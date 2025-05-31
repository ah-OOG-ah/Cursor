/**
 * This file is part of Cursor - a mod that _runs_.
 * Copyright (C) 2025 ah-OOG-ah
 *
 * Cursor is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Cursor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

package klaxon.klaxon.inspector;

import static java.lang.Math.max;
import static java.lang.Math.round;
import static java.lang.Math.sqrt;
import static java.lang.foreign.FunctionDescriptor.ofVoid;
import static java.lang.foreign.ValueLayout.ADDRESS;
import static java.lang.foreign.ValueLayout.JAVA_DOUBLE;
import static java.lang.foreign.ValueLayout.JAVA_INT;
import static java.lang.foreign.ValueLayout.JAVA_LONG;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.lang.foreign.Arena;
import java.lang.foreign.Linker;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.SymbolLookup;
import java.lang.invoke.MethodHandle;
import java.util.Random;
import javax.imageio.ImageIO;
import net.minecraft.world.gen.NoiseGeneratorImproved;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

@Warmup(iterations = 0, batchSize = 0)
@Measurement(iterations = 1, batchSize = 1)
public class Target {

    private static MethodHandle zmh_populateNoiseArray;
    private static NoiseGeneratorImproved noiseGen = null;

    public static void main(String[] args) {
        final int SIZE = 512;
        final boolean THIN = true;
        final int thith = 1;
        final var noise = new double[THIN ? SIZE * thith * SIZE : SIZE * SIZE * SIZE];
        final var SCALE = 0.1;

        noiseGen = new NoiseGeneratorImproved(new Random(1337));
        noiseGen.populateNoiseArray(noise, 0, 0, 0, SIZE, THIN ? thith : SIZE, SIZE, SCALE, SCALE, SCALE, 1.0);
        final int RL = noise.length / SIZE;
        printNoiseResults(noise, RL, false);
        writeNoiseAsPNG(noise, new File("mc.png"), SIZE, THIN ? thith : SIZE, SIZE);

        setup();
        populateNoiseArray(noise, 0, 0, 0, SIZE, THIN ? thith : SIZE, SIZE, SCALE, SCALE, SCALE, 1.0, 1337);
        printNoiseResults(noise, RL, false);
        writeNoiseAsPNG(noise, new File("mine.png"), SIZE, THIN ? thith : SIZE, SIZE);
    }

    private static void printNoiseResults(double[] noise, int runLength, boolean printDetails) {
        double max = Double.MIN_VALUE;
        double min = Double.MAX_VALUE;
        double avg = 0;

        for (int i = 0; i < noise.length / runLength; ++i) {
            if (printDetails) System.out.print(fmtHex(i * runLength, '0', 4));
            for (int ii = 0; ii < runLength; ++ii) {
                final var d = noise[i * runLength + ii];
                max = max(d, max);
                min = Math.min(d, min);
                avg += d;

                if (printDetails) System.out.printf(" %5.2f", d);
            }
            if (printDetails) System.out.print("\n");
        }

        avg /= noise.length;

        double deviationsSquared = 0;
        for (int i = 0; i < noise.length; ++i) {
            final var deviation = noise[i] - avg;
            deviationsSquared += deviation * deviation;
        }
        double variance = deviationsSquared / (noise.length - 1);
        double sStdev = sqrt(variance);

        System.out.printf("Max: %f\nAvg: %f\nMin: %f\n", max, avg, min);
        System.out.printf("Standard deviation: %f\n", sStdev);
    }

    private static void writeNoiseAsPNG(double[] noise, File output, int x, int y, int z) {
        if (!output.getName().endsWith(".png")) throw new RuntimeException();

        final var img = new BufferedImage(x, y * z, BufferedImage.TYPE_BYTE_GRAY);
        for (int i = 0; i < x * y * z; ++i) {
            // clamp is now 0 - 1
            final int val = (int) round((noise[i] * 0.5 + 0.5) * 256);
            final int color = 0xFF_00_00_00 | val << 16 | val << 8 | val;

            final int ny = i % y;
            final int xz = i / y;
            final int nx = xz % x;
            final int nz = xz / x;
            img.setRGB(nx, nz + ny * z, color);
        }

        try {
            ImageIO.write(img, "png", output);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    @SuppressWarnings("SameParameterValue")
    private static String fmtHex(int val, char padding, int width) {
        return ("0x%" + width + "x").formatted(val).replace(' ', padding);
    }

    @Setup
    public static void setup() {
        noiseGen = new NoiseGeneratorImproved(new Random(1337));

        final var linker = Linker.nativeLinker();
        final var globalArena = Arena.global();
        final var zig = SymbolLookup.libraryLookup("inspector/build/libCursor.so", globalArena);
        zmh_populateNoiseArray = linker.downcallHandle(
            zig.findOrThrow("populateNoiseArray"),
            ofVoid(ADDRESS,
                JAVA_DOUBLE, JAVA_DOUBLE, JAVA_DOUBLE,
                JAVA_INT, JAVA_INT, JAVA_INT,
                JAVA_DOUBLE, JAVA_DOUBLE, JAVA_DOUBLE,
                JAVA_DOUBLE, JAVA_LONG, JAVA_DOUBLE),
            Linker.Option.critical(true)
        );
    }

    public static void populateNoiseArray(
        double[] noiseArray,
        double xOffset, double yOffset, double zOffset,
        int xSize, int ySize, int zSize,
        double xScale, double yScale, double zScale,
        double noiseScale, long seed) {

        final MemorySegment wrappedNoise = MemorySegment.ofArray(noiseArray);
        // Required to make range match MC's. It's not *that* close, but it's close enough... probably
        noiseScale *= 1.291408 / 2.0;
        double offset = -0.445328;

        try {
            zmh_populateNoiseArray.invokeExact(wrappedNoise,
                xOffset, yOffset, zOffset,
                xSize, ySize, zSize,
                xScale, yScale, zScale,
                noiseScale, seed, offset);
        } catch (Throwable e) {
            throw new RuntimeException(e);
        }
    }

    @Benchmark
    public static void noise(Blackhole bh) {
        //
        final var noise = new double[8 * 8 * 8];
        noiseGen.populateNoiseArray(noise, 0, 0, 0, 8, 8, 8, 0.1, 0.1, 0.1, 1.1);
        bh.consume(noise);
    }
}

