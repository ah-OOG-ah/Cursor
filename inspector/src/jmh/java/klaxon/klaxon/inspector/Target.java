package klaxon.klaxon.inspector;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

@Warmup(iterations = 0, batchSize = 0)
@Measurement(iterations = 1, batchSize = 1)
public class Target {
    @Benchmark
    public static void noise(Blackhole bh) {
        //
        final var noise = new double[8 * 8 * 8];
        NoiseGeneratorImproved.populateNoiseArray(noise, 0, 0, 0, 8, 8, 8, 0.1, 0.1, 0.1, 1.1);
        bh.consume(noise);
    }
}

