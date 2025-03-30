const std = @import("std");

pub const Interval = struct {
    t_min: f64,
    t_max: f64,

    pub fn contains(self: *const Interval, point: f64) bool {
        return (self.t_min <= point) and (point <= self.t_max);
    }

    pub fn surrounds(self: *const Interval, point: f64) bool {
        return (self.t_min < point) and (point < self.t_max);
    }

    pub fn is_outside(self: *const Interval, point: f64) bool {
        return (point <= self.t_min) or (self.t_max <= point);
    }
};

pub const EMPTY = Interval{ .t_min = std.math.inf(f64), .t_max = -std.math.inf(f64) };
pub const UNIVERSE = Interval{ .t_min = -std.math.inf(f64), .t_max = std.math.inf(f64) };
