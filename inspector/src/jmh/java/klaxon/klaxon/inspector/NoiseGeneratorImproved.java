/**
 * This class is taken from Minecraft, and thus All Rights Reserved, not LGPL!
 */

package klaxon.klaxon.inspector;

import java.util.Random;
import org.openjdk.jmh.annotations.CompilerControl;

public class NoiseGeneratorImproved {
    private static final Random random = new Random(1337);
    private static final int[] permutations = new int[512];
    public static double xCoord = random.nextDouble() * 256.0D;
    public static double yCoord = random.nextDouble() * 256.0D;
    public static double zCoord = random.nextDouble() * 256.0D;
    private static final double[] field_152381_e = new double[] {1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -1.0D, 0.0D, 0.0D, 0.0D, 0.0D, 1.0D, 0.0D, -1.0D, 0.0D};
    private static final double[] field_152382_f = new double[] {1.0D, 1.0D, -1.0D, -1.0D, 0.0D, 0.0D, 0.0D, 0.0D, 1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -1.0D};
    private static final double[] field_152383_g = new double[] {0.0D, 0.0D, 0.0D, 0.0D, 1.0D, 1.0D, -1.0D, -1.0D, 1.0D, 1.0D, -1.0D, -1.0D, 0.0D, 1.0D, 0.0D, -1.0D};
    private static final double[] field_152384_h = new double[] {1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -1.0D, 0.0D, 0.0D, 0.0D, 0.0D, 1.0D, 0.0D, -1.0D, 0.0D};
    private static final double[] field_152385_i = new double[] {0.0D, 0.0D, 0.0D, 0.0D, 1.0D, 1.0D, -1.0D, -1.0D, 1.0D, 1.0D, -1.0D, -1.0D, 0.0D, 1.0D, 0.0D, -1.0D};

    static {
        for (int i = 0; i < 256; ++i) {
            int j = random.nextInt(256 - i) + i;
            int k = permutations[i];
            permutations[i] = permutations[j];
            permutations[j] = k;
            permutations[i + 256] = permutations[i];
        }
    }

    @CompilerControl(CompilerControl.Mode.INLINE)
    public static double lerp(double factor, double a, double b) {
        return a + factor * (b - a);
    }

    @CompilerControl(CompilerControl.Mode.INLINE)
    public static double func_76309_a(int p_76309_1_, double p_76309_2_, double p_76309_4_) {
        int j = p_76309_1_ & 15;
        return field_152384_h[j] * p_76309_2_ + field_152385_i[j] * p_76309_4_;
    }

    @CompilerControl(CompilerControl.Mode.INLINE)
    public static double grad(int p_76310_1_, double p_76310_2_, double p_76310_4_, double p_76310_6_) {
        int j = p_76310_1_ & 15;
        return field_152381_e[j] * p_76310_2_ + field_152382_f[j] * p_76310_4_ + field_152383_g[j] * p_76310_6_;
    }

    /**
     * pars: noiseArray , xOffset , yOffset , zOffset , xSize , ySize , zSize , xScale, yScale , zScale , noiseScale.
     * noiseArray should be xSize*ySize*zSize in size
     */
    @CompilerControl(CompilerControl.Mode.COMPILE_ONLY)
    public static void populateNoiseArray(
        double[] noiseArray,
        double xOffset, double yOffset, double zOffset,
        int xSize, int ySize, int zSize,
        double xScale, double yScale, double zScale,
        double noiseScale) {
        int permBIX;
        int i1;
        double floatX;
        double shufFX;
        int zpos;
        double floatZ;
        int intZ;
        int byteFromIntZ;
        double shufZ;
        int k5;
        int j6;

        if (ySize == 1) {
            double d21;
            double d22;
            k5 = 0;
            double inverseNoiseScale = 1.0D / noiseScale;

            for (int xpos = 0; xpos < xSize; ++xpos) {
                floatX = xOffset + (double)xpos * xScale + xCoord;
                int intX = (int)floatX;

                if (floatX < (double)intX) {
                    --intX;
                }

                int byteOfIntX = intX & 255;
                floatX -= intX;
                shufFX = floatX * floatX * floatX * (floatX * (floatX * 6.0D - 15.0D) + 10.0D);

                for (zpos = 0; zpos < zSize; ++zpos) {
                    floatZ = zOffset + (double)zpos * zScale + zCoord;
                    intZ = (int)floatZ;

                    if (floatZ < (double)intZ) {
                        --intZ;
                    }

                    byteFromIntZ = intZ & 255;
                    floatZ -= intZ;
                    shufZ = floatZ * floatZ * floatZ * (floatZ * (floatZ * 6.0D - 15.0D) + 10.0D);
                    permBIX = permutations[byteOfIntX];
                    int i4 = permutations[permBIX] + byteFromIntZ;
                    int j4 = permutations[byteOfIntX + 1];
                    i1 = permutations[j4] + byteFromIntZ;
                    d21 = lerp(shufFX, func_76309_a(permutations[i4], floatX, floatZ), grad(permutations[i1], floatX - 1.0D, 0.0D, floatZ));
                    d22 = lerp(shufFX, grad(permutations[i4 + 1], floatX, 0.0D, floatZ - 1.0D), grad(permutations[i1 + 1], floatX - 1.0D, 0.0D, floatZ - 1.0D));
                    double d24 = lerp(shufZ, d21, d22);
                    j6 = k5++;
                    noiseArray[j6] += d24 * inverseNoiseScale;
                }
            }
        } else {
            permBIX = 0;
            double d7 = 1.0D / noiseScale;
            i1 = -1;
            double d8 = 0.0D;
            floatX = 0.0D;
            double d10 = 0.0D;
            shufFX = 0.0D;

            for (zpos = 0; zpos < xSize; ++zpos) {
                floatZ = xOffset + (double)zpos * xScale + xCoord;
                intZ = (int)floatZ;

                if (floatZ < (double)intZ) {
                    --intZ;
                }

                byteFromIntZ = intZ & 255;
                floatZ -= intZ;
                shufZ = floatZ * floatZ * floatZ * (floatZ * (floatZ * 6.0D - 15.0D) + 10.0D);

                for (int k2 = 0; k2 < zSize; ++k2) {
                    double d14 = zOffset + (double)k2 * zScale + zCoord;
                    int l2 = (int)d14;

                    if (d14 < (double)l2) {
                        --l2;
                    }

                    int i3 = l2 & 255;
                    d14 -= l2;
                    double d15 = d14 * d14 * d14 * (d14 * (d14 * 6.0D - 15.0D) + 10.0D);

                    for (int j3 = 0; j3 < ySize; ++j3) {
                        double d16 = yOffset + (double)j3 * yScale + yCoord;
                        int k3 = (int)d16;

                        if (d16 < (double)k3) {
                            --k3;
                        }

                        int l3 = k3 & 255;
                        d16 -= k3;
                        double d17 = d16 * d16 * d16 * (d16 * (d16 * 6.0D - 15.0D) + 10.0D);

                        if (j3 == 0 || l3 != i1) {
                            i1 = l3;
                            int k4 = permutations[byteFromIntZ] + l3;
                            int l4 = permutations[k4] + i3;
                            int i5 = permutations[k4 + 1] + i3;
                            int j5 = permutations[byteFromIntZ + 1] + l3;
                            k5 = permutations[j5] + i3;
                            int l5 = permutations[j5 + 1] + i3;
                            d8 = lerp(shufZ, grad(permutations[l4], floatZ, d16, d14), grad(permutations[k5], floatZ - 1.0D, d16, d14));
                            floatX = lerp(shufZ, grad(permutations[i5], floatZ, d16 - 1.0D, d14), grad(permutations[l5], floatZ - 1.0D, d16 - 1.0D, d14));
                            d10 = lerp(shufZ, grad(permutations[l4 + 1], floatZ, d16, d14 - 1.0D), grad(permutations[k5 + 1], floatZ - 1.0D, d16, d14 - 1.0D));
                            shufFX = lerp(shufZ, grad(permutations[i5 + 1], floatZ, d16 - 1.0D, d14 - 1.0D), grad(permutations[l5 + 1], floatZ - 1.0D, d16 - 1.0D, d14 - 1.0D));
                        }

                        double d18 = lerp(d17, d8, floatX);
                        double d19 = lerp(d17, d10, shufFX);
                        double d20 = lerp(d15, d18, d19);
                        j6 = permBIX++;
                        noiseArray[j6] += d20 * d7;
                    }
                }
            }
        }
    }
}
