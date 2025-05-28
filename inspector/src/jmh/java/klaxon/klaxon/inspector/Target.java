package klaxon.klaxon.inspector;

import java.lang.foreign.Arena;
import java.lang.foreign.Linker;
import java.lang.foreign.SymbolLookup;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

@Warmup(iterations = 0, batchSize = 0)
@Measurement(iterations = 1, batchSize = 1)
public class Target {

    public static void main(String[] args) {
        final int SIZE = 512;
        final var noise = new double[SIZE * SIZE * SIZE];
        NoiseGeneratorImproved.populateNoiseArray(noise, 0, 0, 0, SIZE, SIZE, SIZE, 0.1, 0.1, 0.1, 1.0);
        final int RL = SIZE * SIZE; // / 2;

        double max = Double.MIN_VALUE;
        double min = Double.MAX_VALUE;
        double avg = 0;
        for (int i = 0; i < noise.length / RL; ++i) {
            //System.out.print(fmtHex(i * RL, '0', 4));
            for (int ii = 0; ii < RL; ++ii) {
                final var d = noise[i * RL + ii];
                max = Math.max(d, max);
                min = Math.min(d, min);
                avg += d;

                //System.out.printf(" %5.2f", d);
            }
            //System.out.print("\n");
        }

        avg /= noise.length;

        System.out.printf("Max: %.2f\nAvg: %.2f\nMin: %.2f\n", max, avg, min);
    }

    @SuppressWarnings("SameParameterValue")
    private static String fmtHex(int val, char padding, int width) {
        return ("0x%" + width + "x").formatted(val).replace(' ', padding);
    }

    @Setup
    public static void setup() {
        final var linker = Linker.nativeLinker();
        final var globalArena = Arena.global();
        final var zig = SymbolLookup.libraryLookup("natives", globalArena);
    }

    @Benchmark
    public static void noise(Blackhole bh) {
        //
        final var noise = new double[8 * 8 * 8];
        NoiseGeneratorImproved.populateNoiseArray(noise, 0, 0, 0, 8, 8, 8, 0.1, 0.1, 0.1, 1.1);
        bh.consume(noise);
    }
}

