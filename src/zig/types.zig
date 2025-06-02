// Theoretically caps out for f64/i64 on AVX-512
pub const VLEN = 8;

pub const VI64_8: type = @Vector(VLEN, i64);
pub const VF64_8: type = @Vector(VLEN, f64);

pub const VI32_8: type = @Vector(VLEN, i32);
pub const VF32_8: type = @Vector(VLEN, f32);

pub fn splati64(val: i64) VI64_8 {
    return @splat(val);
}

pub fn splatf64(val: f64) VF64_8 {
    return @splat(val);
}

pub fn splatf32(val: f32) VF32_8 {
    return @splat(val);
}

pub fn castif(val: VI32_8) VF64_8 {
    var ret: VF64_8 = undefined;
    for (0..VLEN) |i| {
        ret[i] = @as(f64, @floatFromInt(val[i]));
    }
    return ret;
}

pub fn chopf(val: VF64_8) VF32_8 {
    var ret: VF32_8 = undefined;
    for (0..VLEN) |i| {
        ret[i] = @as(f32, @floatCast(val[i]));
    }
    return ret;
}

pub fn castIUP(val: VI32_8) VI64_8 {
    var ret: VI64_8 = undefined;
    for (0..VLEN) |i| {
        ret[i] = @as(i64, val[i]);
    }
    return ret;
}

pub fn fastFloorV(x: VF64_8) VI32_8 {
    const tmp = @floor(x);
    var ret: VI32_8 = undefined;
    for (0..8) |i| { ret[i] = @as(i32, @intFromFloat(tmp[i])); }
    return ret;
}
