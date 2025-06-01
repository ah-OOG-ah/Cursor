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
// 4D OpenSimplex2 noise, with XYZ oriented like noise3_ImproveXY
// and W for an extra degree of freedom. W repeats eventually.
// Recommended for time-varied animations which texture a 3D object (W=time)
// in a space where Z is vertical
//
fn noise4_ImproveXYZ_ImproveXY(seed: i64, x: f64, y: f64, z: f64, w: f64) f32 {
    const xy = x + y;
    const s2 = xy * -0.21132486540518699998;
    const zz = z * 0.28867513459481294226;
    const ww = w * 0.2236067977499788;
    const xr = x + (zz + ww + s2);
    const yr = y + (zz + ww + s2);
    const zr = xy * -0.57735026918962599998 + (zz + ww);
    const wr = z * -0.866025403784439 + ww;

    return noise4_UnskewedBase(seed, xr, yr, zr, wr);
}

//
// 4D OpenSimplex2 noise, with XYZ oriented like noise3_ImproveXZ
// and W for an extra degree of freedom. W repeats eventually.
// Recommended for time-varied animations which texture a 3D object (W=time)
// in a space where Y is vertical
//
fn noise4_ImproveXYZ_ImproveXZ(seed: i64, x: f64, y: f64, z: f64, w: f64) f32 {
    const xz = x + z;
    const s2 = xz * -0.21132486540518699998;
    const yy = y * 0.28867513459481294226;
    const ww = w * 0.2236067977499788;
    const xr = x + (yy + ww + s2);
    const zr = z + (yy + ww + s2);
    const yr = xz * -0.57735026918962599998 + (yy + ww);
    const wr = y * -0.866025403784439 + ww;

    return noise4_UnskewedBase(seed, xr, yr, zr, wr);
}

//
// 4D OpenSimplex2 noise, with XYZ oriented like noise3_Fallback
// and W for an extra degree of freedom. W repeats eventually.
// Recommended for time-varied animations which texture a 3D object (W=time)
// where there isn't a clear distinction between horizontal and vertical
//
fn noise4_ImproveXYZ(seed: i64, x: f64, y: f64, z: f64, w: f64) f32 {
    const xyz = x + y + z;
    const ww = w * 0.2236067977499788;
    const s2 = xyz * -0.16666666666666666 + ww;
    const xs = x + s2;
    const ys = y + s2;
    const zs = z + s2;
    const ws = -0.5 * xyz + ww;

    return noise4_UnskewedBase(seed, xs, ys, zs, ws);
}

//
// 4D OpenSimplex2 noise, with XY and ZW forming orthogonal triangular-based planes.
// Recommended for 3D terrain, where X and Y (or Z and W) are horizontal.
// Recommended for noise(x, y, sin(time), cos(time)) trick.
//
fn noise4_ImproveXY_ImproveZW(seed: i64, x: f64, y: f64, z: f64, w: f64) f32 {
    const s2 = (x + y) * -0.178275657951399372 + (z + w) * 0.215623393288842828;
    const t2 = (z + w) * -0.403949762580207112 + (x + y) * -0.375199083010075342;
    const xs = x + s2;
    const ys = y + s2;
    const zs = z + t2;
    const ws = w + t2;

    return noise4_UnskewedBase(seed, xs, ys, zs, ws);
}

//
// 4D OpenSimplex2 noise, fallback lattice orientation.
//
fn noise4_Fallback(seed: i64, x: f64, y: f64, z: f64, w: f64) f32 {
    // Get points for A4 lattice
    const s: f64 = @as(f64, SKEW_4D) * (x + y + z + w);
    const xs: f64 = x + s;
    const ys: f64 = y + s;
    const zs: f64 = z + s;
    const ws: f64 = w + s;

    return noise4_UnskewedBase(seed, xs, ys, zs, ws);
}

//
// 4D OpenSimplex2 noise base.
//
fn noise4_UnskewedBase(seed: i64, xs: f64, ys: f64, zs: f64, ws: f64) f32 {
    // Wrapping
    // var seed = seed; // wrapping

    // Get base points and offsets
    const xsb = fastFloor(xs);
    const ysb = fastFloor(ys);
    const zsb = fastFloor(zs);
    const wsb = fastFloor(ws);
    var xsi = @as(f32, @floatCast(xs - @as(f64, @floatFromInt(xsb))));
    var ysi = @as(f32, @floatCast(ys - @as(f64, @floatFromInt(ysb))));
    var zsi = @as(f32, @floatCast(zs - @as(f64, @floatFromInt(zsb))));
    var wsi = @as(f32, @floatCast(ws - @as(f64, @floatFromInt(wsb))));

    // Determine which lattice we can be confident has a contributing point its corresponding cell's base simplex.
    // We only look at the spaces between the diagonal planes. This proved effective in all of my tests.
    const siSum: f32 = (xsi + ysi) + (zsi + wsi);
    const startingLattice = @as(i32, @intFromFloat(siSum * 1.25));

    // Offset for seed based on first lattice copy.
    seed +%= @as(i64, startingLattice) *% SEED_OFFSET_4D;

    // Offset for lattice point relative positions (skewed)
    const startingLatticeOffset: f32 = @as(f32, @floatFromInt(startingLattice)) * -LATTICE_STEP_4D;
    xsi += startingLatticeOffset;
    ysi += startingLatticeOffset;
    zsi += startingLatticeOffset;
    wsi += startingLatticeOffset;

    // Prep for vertex contributions.
    var ssi: f32 = (siSum + startingLatticeOffset * 4.0) * UNSKEW_4D;

    // Prime pre-multiplication for hash.
    var xsvp: i64 = @as(i64, xsb) *% PRIME_X;
    var ysvp: i64 = @as(i64, ysb) *% PRIME_Y;
    var zsvp: i64 = @as(i64, zsb) *% PRIME_Z;
    var wsvp: i64 = @as(i64, wsb) *% PRIME_W;

    // Five points to add, total, from five copies of the A4 lattice.
    var value = 0.0;
    for (0..5) |i| {
        // Next point is the closest vertex on the 4-simplex whose base vertex is the aforementioned vertex.
        const score0 = 1.0 + ssi * (-1.0 / UNSKEW_4D); // Seems slightly faster than 1.0-xsi-ysi-zsi-wsi
        if (xsi >= ysi and xsi >= zsi and xsi >= wsi and xsi >= score0) {
            xsvp += PRIME_X;
            xsi -= 1.0;
            ssi -= UNSKEW_4D;
        } else if (ysi > xsi and ysi >= zsi and ysi >= wsi and ysi >= score0) {
            ysvp += PRIME_Y;
            ysi -= 1.0;
            ssi -= UNSKEW_4D;
        } else if (zsi > xsi and zsi > ysi and zsi >= wsi and zsi >= score0) {
            zsvp += PRIME_Z;
            zsi -= 1.0;
            ssi -= UNSKEW_4D;
        } else if (wsi > xsi and wsi > ysi and wsi > zsi and wsi >= score0) {
            wsvp += PRIME_W;
            wsi -= 1.0;
            ssi -= UNSKEW_4D;
        }

        // gradient contribution with falloff.
        const dx = xsi + ssi;
        const dy = ysi + ssi;
        const dz = zsi + ssi;
        const dw = wsi + ssi;
        var a = (dx * dx + dy * dy) + (dz * dz + dw * dw);
        if (a < RSQUARED_4D) {
            a -= RSQUARED_4D;
            a *= a;
            value += a * a * grad4(seed, xsvp, ysvp, zsvp, wsvp, dx, dy, dz, dw);
        }

        // Break from loop if we're done, skipping updates below.
        if (i == 4) {
            break;
        }

        // Update for next lattice copy shifted down by <-0.2, -0.2, -0.2, -0.2>.
        xsi += LATTICE_STEP_4D;
        ysi += LATTICE_STEP_4D;
        zsi += LATTICE_STEP_4D;
        wsi += LATTICE_STEP_4D;
        ssi += LATTICE_STEP_4D * 4.0 * UNSKEW_4D;
        seed -%= SEED_OFFSET_4D;

        // Because we don't always start on the same lattice copy, there's a special reset case.
        if (i == startingLattice) {
            xsvp -= PRIME_X;
            ysvp -= PRIME_Y;
            zsvp -= PRIME_Z;
            wsvp -= PRIME_W;
            seed +%= SEED_OFFSET_4D * 5;
        }
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

fn grad4(
    seed: i64, // wrapping
    xsvp: i64, // wrapping
    ysvp: i64, // wrapping
    zsvp: i64, // wrapping
    wsvp: i64, // wrapping
    dx: f32,
    dy: f32,
    dz: f32,
    dw: f32,) f32 {
    var hash = seed ^ (xsvp ^ ysvp) ^ (zsvp ^ wsvp);
    hash *%= HASH_MULTIPLIER;
    hash ^= hash >> (64 - N_GRADS_4D_EXPONENT + 2);
    const gi = @as(usize, @intCast(@as(i32, @intCast(hash)) & ((N_GRADS_4D - 1) << 2)));
    const grads = GRADIENTS.gradients4D;
    return (grads[gi | 0] * dx + grads[gi | 1] * dy) + (grads[gi | 2] * dz + grads[gi | 3] * dw);
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
    gradients3D: [N_GRADS_3D * 4]f32,
    gradients4D: [N_GRADS_4D * 4]f32,
};

const GRADIENTS = computeGradients();

fn computeGradients() Gradients {
    // const gradients2D = GRAD2_SRC
    // .into_iter()
    // .map(|v| (v / NORMALIZER_2D) as f32)
    // .collect::<Vec<_>>() // cache divisions
    // .into_iter()
    // .cycle()
    // .take((N_GRADS_2D * 2) as usize)
    // .collect();
    var gradients2D: [N_GRADS_2D * 2]f32 = undefined;
    for (0..gradients2D.len) |i| {
        const v = GRAD2_SRC[i % GRAD2_SRC.len];
        gradients2D[i] = @as(f32, @floatCast(v / NORMALIZER_2D));
    }

    // const gradients3D: Vec<_> = GRAD3_SRC
    // .into_iter()
    // .map(|v| (v / NORMALIZER_3D) as f32)
    // .collect::<Vec<_>>() // cache divisions
    //         .into_iter()
    // .cycle()
    // .take((N_GRADS_3D * 4) as usize)
    // .collect();

    @setEvalBranchQuota(N_GRADS_3D * 4 * 2);
    var gradients3D: [N_GRADS_3D * 4]f32 = undefined;
    for (0..gradients3D.len) |i| {
        const v = GRAD3_SRC[i % GRAD3_SRC.len];
        gradients3D[i] = @as(f32, @floatCast(v / NORMALIZER_3D));
    }

    // const gradients4D: Vec<_> = GRAD4_SRC
    // .into_iter()
    // .map(|v| (v / NORMALIZER_4D) as f32)
    // .collect::<Vec<_>>() // cache divisions
    //         .into_iter()
    // .cycle()
    // .take((N_GRADS_4D * 4) as usize)
    // .collect();
    //
    @setEvalBranchQuota(N_GRADS_4D * 4 * 2);
    var gradients4D: [N_GRADS_4D * 4]f32 = undefined;
    for (0..gradients4D.len) |i| {
        const v = GRAD4_SRC[i % GRAD4_SRC.len];
        gradients4D[i] = @as(f32, @floatCast(v / NORMALIZER_4D));
    }

    return Gradients {
        .gradients2D = gradients2D,
        .gradients3D = gradients3D,
        .gradients4D = gradients4D
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

const GRAD4_SRC = [_]f64 {
-0.6740059517812944,   -0.3239847771997537,   -0.3239847771997537,    0.5794684678643381,
-0.7504883828755602,   -0.4004672082940195,    0.15296486218853164,   0.5029860367700724,
-0.7504883828755602,    0.15296486218853164,  -0.4004672082940195,    0.5029860367700724,
-0.8828161875373585,    0.08164729285680945,   0.08164729285680945,   0.4553054119602712,
-0.4553054119602712,   -0.08164729285680945,  -0.08164729285680945,   0.8828161875373585,
-0.5029860367700724,   -0.15296486218853164,   0.4004672082940195,    0.7504883828755602,
-0.5029860367700724,    0.4004672082940195,   -0.15296486218853164,   0.7504883828755602,
-0.5794684678643381,    0.3239847771997537,    0.3239847771997537,    0.6740059517812944,
-0.6740059517812944,   -0.3239847771997537,    0.5794684678643381,   -0.3239847771997537,
-0.7504883828755602,   -0.4004672082940195,    0.5029860367700724,    0.15296486218853164,
-0.7504883828755602,    0.15296486218853164,   0.5029860367700724,   -0.4004672082940195,
-0.8828161875373585,    0.08164729285680945,   0.4553054119602712,    0.08164729285680945,
-0.4553054119602712,   -0.08164729285680945,   0.8828161875373585,   -0.08164729285680945,
-0.5029860367700724,   -0.15296486218853164,   0.7504883828755602,    0.4004672082940195,
-0.5029860367700724,    0.4004672082940195,    0.7504883828755602,   -0.15296486218853164,
-0.5794684678643381,    0.3239847771997537,    0.6740059517812944,    0.3239847771997537,
-0.6740059517812944,    0.5794684678643381,   -0.3239847771997537,   -0.3239847771997537,
-0.7504883828755602,    0.5029860367700724,   -0.4004672082940195,    0.15296486218853164,
-0.7504883828755602,    0.5029860367700724,    0.15296486218853164,  -0.4004672082940195,
-0.8828161875373585,    0.4553054119602712,    0.08164729285680945,   0.08164729285680945,
-0.4553054119602712,    0.8828161875373585,   -0.08164729285680945,  -0.08164729285680945,
-0.5029860367700724,    0.7504883828755602,   -0.15296486218853164,   0.4004672082940195,
-0.5029860367700724,    0.7504883828755602,    0.4004672082940195,   -0.15296486218853164,
-0.5794684678643381,    0.6740059517812944,    0.3239847771997537,    0.3239847771997537,
0.5794684678643381,   -0.6740059517812944,   -0.3239847771997537,   -0.3239847771997537,
0.5029860367700724,   -0.7504883828755602,   -0.4004672082940195,    0.15296486218853164,
0.5029860367700724,   -0.7504883828755602,    0.15296486218853164,  -0.4004672082940195,
0.4553054119602712,   -0.8828161875373585,    0.08164729285680945,   0.08164729285680945,
0.8828161875373585,   -0.4553054119602712,   -0.08164729285680945,  -0.08164729285680945,
0.7504883828755602,   -0.5029860367700724,   -0.15296486218853164,   0.4004672082940195,
0.7504883828755602,   -0.5029860367700724,    0.4004672082940195,   -0.15296486218853164,
0.6740059517812944,   -0.5794684678643381,    0.3239847771997537,    0.3239847771997537,
//------------------------------------------------------------------------------------------//
    -0.753341017856078,    -0.37968289875261624,  -0.37968289875261624,  -0.37968289875261624,
-0.7821684431180708,   -0.4321472685365301,   -0.4321472685365301,    0.12128480194602098,
-0.7821684431180708,   -0.4321472685365301,    0.12128480194602098,  -0.4321472685365301,
-0.7821684431180708,    0.12128480194602098,  -0.4321472685365301,   -0.4321472685365301,
-0.8586508742123365,   -0.508629699630796,     0.044802370851755174,  0.044802370851755174,
-0.8586508742123365,    0.044802370851755174, -0.508629699630796,     0.044802370851755174,
-0.8586508742123365,    0.044802370851755174,  0.044802370851755174, -0.508629699630796,
-0.9982828964265062,   -0.03381941603233842,  -0.03381941603233842,  -0.03381941603233842,
-0.37968289875261624,  -0.753341017856078,    -0.37968289875261624,  -0.37968289875261624,
-0.4321472685365301,   -0.7821684431180708,   -0.4321472685365301,    0.12128480194602098,
-0.4321472685365301,   -0.7821684431180708,    0.12128480194602098,  -0.4321472685365301,
0.12128480194602098,  -0.7821684431180708,   -0.4321472685365301,   -0.4321472685365301,
-0.508629699630796,    -0.8586508742123365,    0.044802370851755174,  0.044802370851755174,
0.044802370851755174, -0.8586508742123365,   -0.508629699630796,     0.044802370851755174,
0.044802370851755174, -0.8586508742123365,    0.044802370851755174, -0.508629699630796,
-0.03381941603233842,  -0.9982828964265062,   -0.03381941603233842,  -0.03381941603233842,
-0.37968289875261624,  -0.37968289875261624,  -0.753341017856078,    -0.37968289875261624,
-0.4321472685365301,   -0.4321472685365301,   -0.7821684431180708,    0.12128480194602098,
-0.4321472685365301,    0.12128480194602098,  -0.7821684431180708,   -0.4321472685365301,
0.12128480194602098,  -0.4321472685365301,   -0.7821684431180708,   -0.4321472685365301,
-0.508629699630796,     0.044802370851755174, -0.8586508742123365,    0.044802370851755174,
0.044802370851755174, -0.508629699630796,    -0.8586508742123365,    0.044802370851755174,
0.044802370851755174,  0.044802370851755174, -0.8586508742123365,   -0.508629699630796,
-0.03381941603233842,  -0.03381941603233842,  -0.9982828964265062,   -0.03381941603233842,
-0.37968289875261624,  -0.37968289875261624,  -0.37968289875261624,  -0.753341017856078,
-0.4321472685365301,   -0.4321472685365301,    0.12128480194602098,  -0.7821684431180708,
-0.4321472685365301,    0.12128480194602098,  -0.4321472685365301,   -0.7821684431180708,
0.12128480194602098,  -0.4321472685365301,   -0.4321472685365301,   -0.7821684431180708,
-0.508629699630796,     0.044802370851755174,  0.044802370851755174, -0.8586508742123365,
0.044802370851755174, -0.508629699630796,     0.044802370851755174, -0.8586508742123365,
0.044802370851755174,  0.044802370851755174, -0.508629699630796,    -0.8586508742123365,
-0.03381941603233842,  -0.03381941603233842,  -0.03381941603233842,  -0.9982828964265062,
-0.3239847771997537,   -0.6740059517812944,   -0.3239847771997537,    0.5794684678643381,
-0.4004672082940195,   -0.7504883828755602,    0.15296486218853164,   0.5029860367700724,
0.15296486218853164,  -0.7504883828755602,   -0.4004672082940195,    0.5029860367700724,
0.08164729285680945,  -0.8828161875373585,    0.08164729285680945,   0.4553054119602712,
-0.08164729285680945,  -0.4553054119602712,   -0.08164729285680945,   0.8828161875373585,
-0.15296486218853164,  -0.5029860367700724,    0.4004672082940195,    0.7504883828755602,
0.4004672082940195,   -0.5029860367700724,   -0.15296486218853164,   0.7504883828755602,
0.3239847771997537,   -0.5794684678643381,    0.3239847771997537,    0.6740059517812944,
-0.3239847771997537,   -0.3239847771997537,   -0.6740059517812944,    0.5794684678643381,
-0.4004672082940195,    0.15296486218853164,  -0.7504883828755602,    0.5029860367700724,
0.15296486218853164,  -0.4004672082940195,   -0.7504883828755602,    0.5029860367700724,
0.08164729285680945,   0.08164729285680945,  -0.8828161875373585,    0.4553054119602712,
-0.08164729285680945,  -0.08164729285680945,  -0.4553054119602712,    0.8828161875373585,
-0.15296486218853164,   0.4004672082940195,   -0.5029860367700724,    0.7504883828755602,
0.4004672082940195,   -0.15296486218853164,  -0.5029860367700724,    0.7504883828755602,
0.3239847771997537,    0.3239847771997537,   -0.5794684678643381,    0.6740059517812944,
-0.3239847771997537,   -0.6740059517812944,    0.5794684678643381,   -0.3239847771997537,
-0.4004672082940195,   -0.7504883828755602,    0.5029860367700724,    0.15296486218853164,
0.15296486218853164,  -0.7504883828755602,    0.5029860367700724,   -0.4004672082940195,
0.08164729285680945,  -0.8828161875373585,    0.4553054119602712,    0.08164729285680945,
-0.08164729285680945,  -0.4553054119602712,    0.8828161875373585,   -0.08164729285680945,
-0.15296486218853164,  -0.5029860367700724,    0.7504883828755602,    0.4004672082940195,
0.4004672082940195,   -0.5029860367700724,    0.7504883828755602,   -0.15296486218853164,
0.3239847771997537,   -0.5794684678643381,    0.6740059517812944,    0.3239847771997537,
-0.3239847771997537,   -0.3239847771997537,    0.5794684678643381,   -0.6740059517812944,
-0.4004672082940195,    0.15296486218853164,   0.5029860367700724,   -0.7504883828755602,
0.15296486218853164,  -0.4004672082940195,    0.5029860367700724,   -0.7504883828755602,
0.08164729285680945,   0.08164729285680945,   0.4553054119602712,   -0.8828161875373585,
-0.08164729285680945,  -0.08164729285680945,   0.8828161875373585,   -0.4553054119602712,
-0.15296486218853164,   0.4004672082940195,    0.7504883828755602,   -0.5029860367700724,
0.4004672082940195,   -0.15296486218853164,   0.7504883828755602,   -0.5029860367700724,
0.3239847771997537,    0.3239847771997537,    0.6740059517812944,   -0.5794684678643381,
-0.3239847771997537,    0.5794684678643381,   -0.6740059517812944,   -0.3239847771997537,
-0.4004672082940195,    0.5029860367700724,   -0.7504883828755602,    0.15296486218853164,
0.15296486218853164,   0.5029860367700724,   -0.7504883828755602,   -0.4004672082940195,
0.08164729285680945,   0.4553054119602712,   -0.8828161875373585,    0.08164729285680945,
-0.08164729285680945,   0.8828161875373585,   -0.4553054119602712,   -0.08164729285680945,
-0.15296486218853164,   0.7504883828755602,   -0.5029860367700724,    0.4004672082940195,
0.4004672082940195,    0.7504883828755602,   -0.5029860367700724,   -0.15296486218853164,
0.3239847771997537,    0.6740059517812944,   -0.5794684678643381,    0.3239847771997537,
-0.3239847771997537,    0.5794684678643381,   -0.3239847771997537,   -0.6740059517812944,
-0.4004672082940195,    0.5029860367700724,    0.15296486218853164,  -0.7504883828755602,
0.15296486218853164,   0.5029860367700724,   -0.4004672082940195,   -0.7504883828755602,
0.08164729285680945,   0.4553054119602712,    0.08164729285680945,  -0.8828161875373585,
-0.08164729285680945,   0.8828161875373585,   -0.08164729285680945,  -0.4553054119602712,
-0.15296486218853164,   0.7504883828755602,    0.4004672082940195,   -0.5029860367700724,
0.4004672082940195,    0.7504883828755602,   -0.15296486218853164,  -0.5029860367700724,
0.3239847771997537,    0.6740059517812944,    0.3239847771997537,   -0.5794684678643381,
0.5794684678643381,   -0.3239847771997537,   -0.6740059517812944,   -0.3239847771997537,
0.5029860367700724,   -0.4004672082940195,   -0.7504883828755602,    0.15296486218853164,
0.5029860367700724,    0.15296486218853164,  -0.7504883828755602,   -0.4004672082940195,
0.4553054119602712,    0.08164729285680945,  -0.8828161875373585,    0.08164729285680945,
0.8828161875373585,   -0.08164729285680945,  -0.4553054119602712,   -0.08164729285680945,
0.7504883828755602,   -0.15296486218853164,  -0.5029860367700724,    0.4004672082940195,
0.7504883828755602,    0.4004672082940195,   -0.5029860367700724,   -0.15296486218853164,
0.6740059517812944,    0.3239847771997537,   -0.5794684678643381,    0.3239847771997537,
0.5794684678643381,   -0.3239847771997537,   -0.3239847771997537,   -0.6740059517812944,
0.5029860367700724,   -0.4004672082940195,    0.15296486218853164,  -0.7504883828755602,
0.5029860367700724,    0.15296486218853164,  -0.4004672082940195,   -0.7504883828755602,
0.4553054119602712,    0.08164729285680945,   0.08164729285680945,  -0.8828161875373585,
0.8828161875373585,   -0.08164729285680945,  -0.08164729285680945,  -0.4553054119602712,
0.7504883828755602,   -0.15296486218853164,   0.4004672082940195,   -0.5029860367700724,
0.7504883828755602,    0.4004672082940195,   -0.15296486218853164,  -0.5029860367700724,
0.6740059517812944,    0.3239847771997537,    0.3239847771997537,   -0.5794684678643381,
0.03381941603233842,   0.03381941603233842,   0.03381941603233842,   0.9982828964265062,
-0.044802370851755174, -0.044802370851755174,  0.508629699630796,     0.8586508742123365,
-0.044802370851755174,  0.508629699630796,    -0.044802370851755174,  0.8586508742123365,
-0.12128480194602098,   0.4321472685365301,    0.4321472685365301,    0.7821684431180708,
0.508629699630796,    -0.044802370851755174, -0.044802370851755174,  0.8586508742123365,
0.4321472685365301,   -0.12128480194602098,   0.4321472685365301,    0.7821684431180708,
0.4321472685365301,    0.4321472685365301,   -0.12128480194602098,   0.7821684431180708,
0.37968289875261624,   0.37968289875261624,   0.37968289875261624,   0.753341017856078,
0.03381941603233842,   0.03381941603233842,   0.9982828964265062,    0.03381941603233842,
-0.044802370851755174,  0.044802370851755174,  0.8586508742123365,    0.508629699630796,
-0.044802370851755174,  0.508629699630796,     0.8586508742123365,   -0.044802370851755174,
-0.12128480194602098,   0.4321472685365301,    0.7821684431180708,    0.4321472685365301,
0.508629699630796,    -0.044802370851755174,  0.8586508742123365,   -0.044802370851755174,
0.4321472685365301,   -0.12128480194602098,   0.7821684431180708,    0.4321472685365301,
0.4321472685365301,    0.4321472685365301,    0.7821684431180708,   -0.12128480194602098,
0.37968289875261624,   0.37968289875261624,   0.753341017856078,     0.37968289875261624,
0.03381941603233842,   0.9982828964265062,    0.03381941603233842,   0.03381941603233842,
-0.044802370851755174,  0.8586508742123365,   -0.044802370851755174,  0.508629699630796,
-0.044802370851755174,  0.8586508742123365,    0.508629699630796,    -0.044802370851755174,
-0.12128480194602098,   0.7821684431180708,    0.4321472685365301,    0.4321472685365301,
0.508629699630796,     0.8586508742123365,   -0.044802370851755174, -0.044802370851755174,
0.4321472685365301,    0.7821684431180708,   -0.12128480194602098,   0.4321472685365301,
0.4321472685365301,    0.7821684431180708,    0.4321472685365301,   -0.12128480194602098,
0.37968289875261624,   0.753341017856078,     0.37968289875261624,   0.37968289875261624,
0.9982828964265062,    0.03381941603233842,   0.03381941603233842,   0.03381941603233842,
0.8586508742123365,   -0.044802370851755174, -0.044802370851755174,  0.508629699630796,
0.8586508742123365,   -0.044802370851755174,  0.508629699630796,    -0.044802370851755174,
0.7821684431180708,   -0.12128480194602098,   0.4321472685365301,    0.4321472685365301,
0.8586508742123365,    0.508629699630796,    -0.044802370851755174, -0.044802370851755174,
0.7821684431180708,    0.4321472685365301,   -0.12128480194602098,   0.4321472685365301,
0.7821684431180708,    0.4321472685365301,    0.4321472685365301,   -0.12128480194602098,
0.753341017856078,     0.37968289875261624,   0.37968289875261624,   0.37968289875261624,
};
