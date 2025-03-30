const std = @import("std");

var rng = std.Random.DefaultPrng.init(0);

pub fn randomDouble() f64 {
    return rng.random().float(f64);
}

pub fn randomDoubleBounded(min: f64, max: f64) f64 {
    return (max - min) * rng.random().float(f64) + min;
}
