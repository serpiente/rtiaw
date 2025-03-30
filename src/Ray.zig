const Vec3 = @import("./vec.zig").Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn init(origin: Vec3, direction: Vec3) Ray {
        return Ray{ .origin = origin, .direction = direction };
    }

    pub fn at(self: *const Ray, t: f64) Vec3 {
        return self.origin.add(self.direction.mul_scalar(t));
    }
};
