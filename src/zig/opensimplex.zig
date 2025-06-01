// This file is part of Cursor - a mod that _runs_.
// Copyright (C) 2025 ah-OOG-ah
//
// Cursor is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Cursor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");

const PRIME_X: i64 = 0x5205402B9270C86F;
const PRIME_Y: i64 = 0x598CD327003817B5;
const PRIME_Z: i64 = 0x5BCC226E9FA0BACB;
const PRIME_W: i64 = 0x56CC5227E58F554B;
const HASH_MULTIPLIER: i64 = 0x53A3F72DEEC546F5;
const SEED_FLIP_3D: i64 = -0x52D547B2E96ED629;
const SEED_OFFSET_4D: i64 = 0xE83DC3E0DA7164D;

const ROOT2OVER2: f64 = 0.7071067811865476;
const SKEW_2D: f64 = 0.366025403784439;
const UNSKEW_2D: f64 = -0.21132486540518713;

const ROOT3OVER3: f64 = 0.577350269189626;
const FALLBACK_ROTATE_3D: f64 = 2.0 / 3.0;
const ROTATE_3D_ORTHOGONALIZER: f64 = UNSKEW_2D;

const SKEW_4D: f32 = -0.138196601125011;
const UNSKEW_4D: f32 = 0.309016994374947;
const LATTICE_STEP_4D: f32 = 0.2;

const N_GRADS_2D_EXPONENT: i32 = 7;
const N_GRADS_3D_EXPONENT: i32 = 8;
const N_GRADS_4D_EXPONENT: i32 = 9;
const N_GRADS_2D: i32 = 1 << N_GRADS_2D_EXPONENT;
const N_GRADS_3D: i32 = 1 << N_GRADS_3D_EXPONENT;
const N_GRADS_4D: i32 = 1 << N_GRADS_4D_EXPONENT;

const NORMALIZER_2D: f64 = 0.01001634121365712;
const NORMALIZER_3D: f64 = 0.07969837668935331;
const NORMALIZER_4D: f64 = 0.0220065933241897;

const RSQUARED_2D: f32 = 0.5;
const RSQUARED_3D: f32 = 0.6;
const RSQUARED_4D: f32 = 0.6;


// Noise Evaluators

//
// 2D Simplex noise, standard lattice orientation.
//
fn noise2(seed: i64, x: f64, y: f64) f32 {
    // Get points for A2* lattice
    const s = SKEW_2D * (x + y);
    const xs = x + s;
    const ys = y + s;

    return noise2_UnskewedBase(seed, xs, ys);
}

//
// 2D Simplex noise, with Y pointing down the main diagonal.
// Might be better for a 2D sandbox style game, where Y is vertical.
// Probably slightly less optimal for heightmaps or continent maps,
// unless your map is centered around an equator. It's a subtle
// difference, but the option is here to make it an easy choice.
//
fn noise2_ImproveX(seed: i64, x: f64, y: f64) f32 {
    // Skew transform and rotation baked into one.
    const xx = x * ROOT2OVER2;
    const yy = y * (ROOT2OVER2 * (1.0 + 2.0 * SKEW_2D));

    return noise2_UnskewedBase(seed, yy + xx, yy - xx);
}

//
// 2D Simplex noise base.
//
fn noise2_UnskewedBase(seed: i64, xs: f64, ys: f64) f32 {
    // const seed = Wrapping(seed);

    // Get base points and offsets.
    const xsb = fastFloor(xs);
    const ysb = fastFloor(ys);
    const xi = @as(f32, xs - @as(f64, @floatFromInt(xsb)));
    const yi = @as(f32, ys - @as(f64, @floatFromInt(ysb)));

    // Prime pre-multiplication for hash.
    const xsbp = @as(i64, xsb) *% PRIME_X;
    const ysbp = @as(i64, ysb) *% PRIME_Y;

    // Unskew.
    const t: f32 = (xi + yi) * @as(f32, @floatCast(UNSKEW_2D));
    const dx0: f32 = xi + t;
    const dy0: f32 = yi + t;

    // First vertex.
    var value = 0.0;
    const a0: f32 = RSQUARED_2D - dx0 * dx0 - dy0 * dy0;
    if (a0 > 0.0) {
        value = (a0 * a0) * (a0 * a0) * grad2(seed, xsbp, ysbp, dx0, dy0);
    }

    // Second vertex.
    const tmp = (@as(f32, @floatCast(-2.0 * (1.0 + 2.0 * UNSKEW_2D) * (1.0 + 2.0 * UNSKEW_2D))) + a0);
    const a1 = @as(f32, @floatCast(2.0 * (1.0 + 2.0 * UNSKEW_2D) * (1.0 / UNSKEW_2D + 2.0))) * t + tmp;
    if (a1 > 0.0) {
        const dx1: f32 = dx0 - @as(f32, @floatCast(1.0 + 2.0 * UNSKEW_2D));
        const dy1: f32 = dy0 - @as(f32, @floatCast(1.0 + 2.0 * UNSKEW_2D));
        value += (a1 * a1) * (a1 * a1) * grad2(seed, xsbp +% PRIME_X, ysbp +% PRIME_Y, dx1, dy1);
    }

    // Third vertex.
    if (dy0 > dx0) {
        const dx2 = dx0 - @as(f32, @floatCast(UNSKEW_2D));
        const dy2 = dy0 - @as(f32, @floatCast(UNSKEW_2D + 1.0));
        const a2 = RSQUARED_2D - dx2 * dx2 - dy2 * dy2;
        if (a2 > 0.0) {
            value += (a2 * a2) * (a2 * a2) * grad2(seed, xsbp, ysbp +% PRIME_Y, dx2, dy2);
        }
    } else {
        const dx2 = dx0 - @as(f32, @floatCast(UNSKEW_2D + 1.0));
        const dy2 = dy0 - @as(f32, @floatCast(UNSKEW_2D));
        const a2 = RSQUARED_2D - dx2 * dx2 - dy2 * dy2;
        if (a2 > 0.0) {
            value += (a2 * a2) * (a2 * a2) * grad2(seed, xsbp +% PRIME_X, ysbp, dx2, dy2);
        }
    }

    return value;
}

//
// 3D OpenSimplex2 noise, with better visual isotropy in (X, Y).
// Recommended for 3D terrain and time-varied animations.
// The Z coordinate should always be the "different" coordinate in whatever your use case is.
// If Y is vertical in world coordinates, call noise3_ImproveXZ(x, z, Y) or use noise3_XZBeforeY.
// If Z is vertical in world coordinates, call noise3_ImproveXZ(x, y, Z).
// For a time varied animation, call noise3_ImproveXY(x, y, T).
//
fn noise3_ImproveXY(seed: i64, x: f64, y: f64, z: f64) f32 {
    // Re-orient the cubic lattices without skewing, so Z points up the main lattice diagonal,
    // and the planes formed by XY are moved far out of alignment with the cube faces.
    // Orthonormal rotation. Not a skew transform.
    const xy = x + y;
    const s2 = xy * ROTATE_3D_ORTHOGONALIZER;
    const zz = z * ROOT3OVER3;
    const xr = x + s2 + zz;
    const yr = y + s2 + zz;
    const zr = xy * -ROOT3OVER3 + zz;

    // Evaluate both lattices to form a BCC lattice.
    return noise3_UnrotatedBase(seed, xr, yr, zr);
}

//
// 3D OpenSimplex2 noise, with better visual isotropy in (X, Z).
// Recommended for 3D terrain and time-varied animations.
// The Y coordinate should always be the "different" coordinate in whatever your use case is.
// If Y is vertical in world coordinates, call noise3_ImproveXZ(x, Y, z).
// If Z is vertical in world coordinates, call noise3_ImproveXZ(x, Z, y) or use noise3_ImproveXY.
// For a time varied animation, call noise3_ImproveXZ(x, T, y) or use noise3_ImproveXY.
//

pub fn noise3_ImproveXZ(seed: i64, x: f64, y: f64, z: f64) f32 {
    // Re-orient the cubic lattices without skewing, so Y points up the main lattice diagonal,
    // and the planes formed by XZ are moved far out of alignment with the cube faces.
    // Orthonormal rotation. Not a skew transform.
    const xz: f64 = x + z;
    const s2: f64 = xz * ROTATE_3D_ORTHOGONALIZER;
    const yy: f64 = y * ROOT3OVER3;
    const xr: f64 = x + s2 + yy;
    const zr: f64 = z + s2 + yy;
    const yr: f64 = xz * -ROOT3OVER3 + yy;

    // Evaluate both lattices to form a BCC lattice.
    return noise3_UnrotatedBase(seed, xr, yr, zr);
}

//
// 3D OpenSimplex2 noise, fallback rotation option
// Use noise3_ImproveXY or noise3_ImproveXZ instead, wherever appropriate.
// They have less diagonal bias. This function's best use is as a fallback.
//
fn noise3_Fallback(seed: i64, x: f64, y: f64, z: f64) f32 {
    // Re-orient the cubic lattices via rotation, to produce a familiar look.
    // Orthonormal rotation. Not a skew transform.
    const r = FALLBACK_ROTATE_3D * (x + y + z);
    const xr = r - x;
    const yr = r - y;
    const zr = r - z;

    // Evaluate both lattices to form a BCC lattice.
    return noise3_UnrotatedBase(seed, xr, yr, zr);
}

//
// Generate overlapping cubic lattices for 3D OpenSimplex2 noise.
//
fn noise3_UnrotatedBase(seed: i64, xr: f64, yr: f64, zr: f64) f32 {
    var seedMut = seed;

    // Get base points and offsets.
    const xrb = fastRound(xr);
    const yrb = fastRound(yr);
    const zrb = fastRound(zr);
    var xri = @as(f32, @floatCast(xr - @as(f64, @floatFromInt(xrb))));
    var yri = @as(f32, @floatCast(yr - @as(f64, @floatFromInt(yrb))));
    var zri = @as(f32, @floatCast(zr - @as(f64, @floatFromInt(zrb))));

    // -1 if positive, 1 if negative.
    var xNSign: i32 = @as(i32, @intFromFloat(-1.0 - xri)) | 1;
    var yNSign: i32 = @as(i32, @intFromFloat(-1.0 - yri)) | 1;
    var zNSign: i32 = @as(i32, @intFromFloat(-1.0 - zri)) | 1;

    // Compute absolute values, using the above as a shortcut. This was faster in my tests for some reason.
    var ax0 = @as(f32, @floatFromInt(xNSign)) * -xri;
    var ay0 = @as(f32, @floatFromInt(yNSign)) * -yri;
    var az0 = @as(f32, @floatFromInt(zNSign)) * -zri;

    // Prime pre-multiplication for hash.
    var xrbp: i64 = @as(i64, xrb) *% PRIME_X;
    var yrbp: i64 = @as(i64, yrb) *% PRIME_Y;
    var zrbp: i64 = @as(i64, zrb) *% PRIME_Z;

    // Loop: Pick an edge on each lattice copy.
    var value: f32 = 0.0;
    var a: f32 = (RSQUARED_3D - xri * xri) - (yri * yri + zri * zri);
    for (0..2) |l| {
        // Closest point on cube.
        if (a > 0.0) {
            value += (a * a) * (a * a) * grad3(seedMut, xrbp, yrbp, zrbp, xri, yri, zri);
        }

        // Second-closest point.
        if (ax0 >= ay0 and ax0 >= az0) {
            var b = a + ax0 + ax0;
            if (b > 1.0) {
                b -= 1.0;
                value += (b * b) * (b * b) * grad3(
                seedMut,
                xrbp -% @as(i64, xNSign) *% PRIME_X, yrbp, zrbp,
                xri + @as(f32, @floatFromInt(xNSign)), yri, zri
                );
            }
        } else if (ay0 > ax0 and ay0 >= az0) {
            var b = a + ay0 + ay0;
            if (b > 1.0) {
                b -= 1.0;
                value += (b * b) * (b * b) * grad3(
                    seedMut,
                    xrbp,
                    yrbp -% @as(i64, yNSign) *% PRIME_Y,
                    zrbp,
                    xri,
                    yri + @as(f32, @floatFromInt(yNSign)),
                    zri,
                );
            }
        } else {
            var b = a + az0 + az0;
            if (b > 1.0) {
                b -= 1.0;
                value += (b * b) * (b * b) * grad3(
                seedMut,
                xrbp,
                yrbp,
                zrbp -% @as(i64, zNSign) *% PRIME_Z,
                xri,
                yri,
                zri + @as(f32, @floatFromInt(zNSign)),
                );
            }
        }

        // Break from loop if we're done, skipping updates below.
        if (l == 1) {
            break;
        }

        // Update absolute value.
        ax0 = 0.5 - ax0;
        ay0 = 0.5 - ay0;
        az0 = 0.5 - az0;

        // Update relative coordinate.
        xri = @as(f32, @floatFromInt(xNSign)) * ax0;
        yri = @as(f32, @floatFromInt(yNSign)) * ay0;
        zri = @as(f32, @floatFromInt(zNSign)) * az0;

        // Update falloff.
        a += (0.75 - ax0) - (ay0 + az0);

        // Update prime for hash.
        xrbp +%= (@as(i64, xNSign) >> 1) & PRIME_X;
        yrbp +%= (@as(i64, yNSign) >> 1) & PRIME_Y;
        zrbp +%= (@as(i64, zNSign) >> 1) & PRIME_Z;

        // Update the reverse sign indicators.
        xNSign = -xNSign;
        yNSign = -yNSign;
        zNSign = -zNSign;

        // And finally update the seed for the other lattice copy.
        seedMut ^= SEED_FLIP_3D;
    }

    return value;
}

//
// Utility
//

// seed, xsvp, ysvp are wrapping
fn grad2(seed: i64, xsvp: i64, ysvp: i64, dx: f32, dy: f32) f32 {
    var hash = seed ^ xsvp ^ ysvp;
    hash *%= HASH_MULTIPLIER;
    hash ^= hash >> (64 - N_GRADS_2D_EXPONENT + 1);
    const gi = @as(usize, @intCast(@as(i32, @intCast(hash)) & ((N_GRADS_2D - 1) << 1)));
    const grads = GRADIENTS.gradients2D;
    return grads[gi | 0] * dx + grads[gi | 1] * dy;
}

fn grad3(
    seed: i64, // wrapping
    xrvp: i64, // wrapping
    yrvp: i64, // wrapping
    zrvp: i64, // wrapping
    dx: f32, dy: f32, dz: f32) f32 {
    var hash = (seed ^ xrvp) ^ (yrvp ^ zrvp);
    hash *%= HASH_MULTIPLIER;
    hash ^= hash >> (64 - N_GRADS_3D_EXPONENT + 2);
    const gi = @as(usize, @intCast(@as(i32, @truncate(hash)) & ((N_GRADS_3D - 1) << 2)));
    const grads = GRADIENTS.gradients3D;
    return grads[gi | 0] * dx + grads[gi | 1] * dy + grads[gi | 2] * dz;
}

fn fastFloor(x: f64) i32 {
    const xi = @as(i32, @intFromFloat(x));
    if (x < @as(f64, xi)) {
        return xi - 1;
    } else {
        return xi;
    }
}

fn fastRound(x: f64) i32 {
    if (x < 0.0) {
        return @intFromFloat(x - 0.5);
    } else {
        return @intFromFloat(x + 0.5);
    }
}

//
// gradients
//

const Gradients = struct {
    gradients2D: [N_GRADS_2D * 2]f32,
    gradients3D: [N_GRADS_3D * 4]f32
};

const GRADIENTS = computeGradients();

fn computeGradients() Gradients {

    var gradients2D: [N_GRADS_2D * 2]f32 = undefined;
    for (0..gradients2D.len) |i| {
        const v = GRAD2_SRC[i % GRAD2_SRC.len];
        gradients2D[i] = @as(f32, @floatCast(v / NORMALIZER_2D));
    }

    @setEvalBranchQuota(N_GRADS_3D * 4 * 2);
    var gradients3D: [N_GRADS_3D * 4]f32 = undefined;
    for (0..gradients3D.len) |i| {
        const v = GRAD3_SRC[i % GRAD3_SRC.len];
        gradients3D[i] = @as(f32, @floatCast(v / NORMALIZER_3D));
    }

    return Gradients {
        .gradients2D = gradients2D,
        .gradients3D = gradients3D
    };
}

const GRAD2_SRC = [_]f64 {
    0.38268343236509,   0.923879532511287,
    0.923879532511287,  0.38268343236509,
    0.923879532511287, -0.38268343236509,
    0.38268343236509,  -0.923879532511287,
   -0.38268343236509,  -0.923879532511287,
   -0.923879532511287, -0.38268343236509,
   -0.923879532511287,  0.38268343236509,
   -0.38268343236509,   0.923879532511287,
    //-------------------------------------//
    0.130526192220052,  0.99144486137381,
    0.608761429008721,  0.793353340291235,
    0.793353340291235,  0.608761429008721,
    0.99144486137381,   0.130526192220051,
    0.99144486137381,  -0.130526192220051,
    0.793353340291235, -0.60876142900872,
    0.608761429008721, -0.793353340291235,
    0.130526192220052, -0.99144486137381,
   -0.130526192220052, -0.99144486137381,
   -0.608761429008721, -0.793353340291235,
   -0.793353340291235, -0.608761429008721,
   -0.99144486137381,  -0.130526192220052,
   -0.99144486137381,   0.130526192220051,
   -0.793353340291235,  0.608761429008721,
   -0.608761429008721,  0.793353340291235,
   -0.130526192220052,  0.99144486137381,
};

const GRAD3_SRC = [_]f64 {
2.22474487139,       2.22474487139,      -1.0,                 0.0,
2.22474487139,       2.22474487139,       1.0,                 0.0,
3.0862664687972017,  1.1721513422464978,  0.0,                 0.0,
1.1721513422464978,  3.0862664687972017,  0.0,                 0.0,
-2.22474487139,       2.22474487139,      -1.0,                 0.0,
-2.22474487139,       2.22474487139,       1.0,                 0.0,
-1.1721513422464978,  3.0862664687972017,  0.0,                 0.0,
-3.0862664687972017,  1.1721513422464978,  0.0,                 0.0,
-1.0,                -2.22474487139,      -2.22474487139,       0.0,
1.0,                -2.22474487139,      -2.22474487139,       0.0,
0.0,                -3.0862664687972017, -1.1721513422464978,  0.0,
0.0,                -1.1721513422464978, -3.0862664687972017,  0.0,
-1.0,                -2.22474487139,       2.22474487139,       0.0,
1.0,                -2.22474487139,       2.22474487139,       0.0,
0.0,                -1.1721513422464978,  3.0862664687972017,  0.0,
0.0,                -3.0862664687972017,  1.1721513422464978,  0.0,
//--------------------------------------------------------------------//
    -2.22474487139,      -2.22474487139,      -1.0,                 0.0,
-2.22474487139,      -2.22474487139,       1.0,                 0.0,
-3.0862664687972017, -1.1721513422464978,  0.0,                 0.0,
-1.1721513422464978, -3.0862664687972017,  0.0,                 0.0,
-2.22474487139,      -1.0,                -2.22474487139,       0.0,
-2.22474487139,       1.0,                -2.22474487139,       0.0,
-1.1721513422464978,  0.0,                -3.0862664687972017,  0.0,
-3.0862664687972017,  0.0,                -1.1721513422464978,  0.0,
-2.22474487139,      -1.0,                 2.22474487139,       0.0,
-2.22474487139,       1.0,                 2.22474487139,       0.0,
-3.0862664687972017,  0.0,                 1.1721513422464978,  0.0,
-1.1721513422464978,  0.0,                 3.0862664687972017,  0.0,
-1.0,                 2.22474487139,      -2.22474487139,       0.0,
1.0,                 2.22474487139,      -2.22474487139,       0.0,
0.0,                 1.1721513422464978, -3.0862664687972017,  0.0,
0.0,                 3.0862664687972017, -1.1721513422464978,  0.0,
-1.0,                 2.22474487139,       2.22474487139,       0.0,
1.0,                 2.22474487139,       2.22474487139,       0.0,
0.0,                 3.0862664687972017,  1.1721513422464978,  0.0,
0.0,                 1.1721513422464978,  3.0862664687972017,  0.0,
2.22474487139,      -2.22474487139,      -1.0,                 0.0,
2.22474487139,      -2.22474487139,       1.0,                 0.0,
1.1721513422464978, -3.0862664687972017,  0.0,                 0.0,
3.0862664687972017, -1.1721513422464978,  0.0,                 0.0,
2.22474487139,      -1.0,                -2.22474487139,       0.0,
2.22474487139,       1.0,                -2.22474487139,       0.0,
3.0862664687972017,  0.0,                -1.1721513422464978,  0.0,
1.1721513422464978,  0.0,                -3.0862664687972017,  0.0,
2.22474487139,      -1.0,                 2.22474487139,       0.0,
2.22474487139,       1.0,                 2.22474487139,       0.0,
1.1721513422464978,  0.0,                 3.0862664687972017,  0.0,
3.0862664687972017,  0.0,                 1.1721513422464978,  0.0,
};
