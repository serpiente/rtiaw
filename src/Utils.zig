const std = @import("std");

var rng = std.Random.DefaultPrng.init(0);

pub fn randomDouble() f64 {
    return rng.random().float(f64);
}