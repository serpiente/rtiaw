const std = @import("std");
const Utils = @import("./Utils.zig");
pub const Vec3 = struct {
    data: @Vector(3, f64),

    pub fn init(x_: f64, y_: f64, z_: f64) Vec3 {
        return Vec3{ .data = @Vector(3, f64){ x_, y_, z_ } };
    }

    pub fn zero() Vec3 {
        return Vec3.init(0.0, 0.0, 0.0);
    }

    pub fn random() Vec3 {
        return Vec3.init(Utils.randomDouble(), Utils.randomDouble(), Utils.randomDouble());
    }

    pub fn randomBounded(min: f64, max: f64) Vec3 {
        return Vec3.init(Utils.randomDoubleBounded(min, max), Utils.randomDoubleBounded(min, max), Utils.randomDoubleBounded(min, max));
    }

    pub fn x(self: *const Vec3) f64 {
        return self.data[0];
    }

    pub fn y(self: *const Vec3) f64 {
        return self.data[1];
    }

    pub fn z(self: *const Vec3) f64 {
        return self.data[2];
    }

    pub fn neg(self: *Vec3) *Vec3 {
        self.data = -self.data;
        return self;
    }

    pub fn addEq(self: *Vec3, other: f64) *Vec3 {
        self.data += @splat(other);
        return self;
    }

    pub fn mulEq(self: *Vec3, other: f64) *Vec3 {
        self.data *= @splat(other);
        return self;
    }

    pub fn divEq(self: *Vec3, other: f64) *Vec3 {
        self.data /= @splat(other);
        return self;
    }

    pub fn dot(self: *const Vec3, other: Vec3) f64 {
        return @reduce(.Add, self.data * other.data);
    }

    pub fn length(self: *const Vec3) f64 {
        return std.math.sqrt(self.dot(self.*));
    }

    pub fn length_squared(self: *const Vec3) f64 {
        return self.dot(self.*);
    }

    pub fn add(u: *const Vec3, v: Vec3) Vec3 {
        return Vec3{ .data = u.data + v.data };
    }

    pub fn sub(u: *const Vec3, v: Vec3) Vec3 {
        return Vec3{ .data = u.data - v.data };
    }

    pub fn mul(u: *Vec3, v: Vec3) Vec3 {
        return Vec3{ .data = u.data * v.data };
    }

    pub fn sum_scalar(u: *const Vec3, scalar: f64) Vec3 {
        return Vec3{ .data = u.data + @as(@Vector(3, f64), @splat(scalar)) };
    }

    pub fn div_scalar(u: *const Vec3, scalar: f64) Vec3 {
        return Vec3{ .data = u.data / @as(@Vector(3, f64), @splat(scalar)) };
    }

    pub fn mul_scalar(u: *const Vec3, scalar: f64) Vec3 {
        return Vec3{ .data = u.data * @as(@Vector(3, f64), @splat(scalar)) };
    }

    pub fn dot_between(u: *const Vec3, v: *const Vec3) f64 {
        return @as(f64, @reduce(.Add, u.data * v.data));
    }

    pub fn cross_product(u: *const Vec3, v: *const Vec3) Vec3 {
        const x_: f64 = u.y() * v.z() - u.z() * v.y();
        const y_: f64 = u.z() * v.x() - u.x() * v.z();
        const z_: f64 = u.x() * v.y() - u.y() * v.x();
        return Vec3.init(x_, y_, z_);
    }

    pub fn unit(u: *const Vec3) Vec3 {
        return u.div_scalar(u.length());
    }

    pub fn random_unit_vector() Vec3 {
        while (true) {
            const rand_vec = Vec3.randomBounded(-1, 1);
            const mag = rand_vec.length_squared();
            if ((1e-160 < mag) and (mag <= 1)) {
                return rand_vec.div_scalar(mag);
            }
        }
    }

    pub fn random_on_hemisphere(normal: *const Vec3) Vec3 {
        const on_unit_sphere = Vec3.random_unit_vector();
        if (on_unit_sphere.dot_between(normal) > 0) {
            return on_unit_sphere;
        } else {
            return on_unit_sphere.mul_scalar(-1);
        }
    }

    pub fn nearZero(v: Vec3) bool {
        const s = 1e-8;
        return @abs(v.x()) < s and @abs(v.y()) < s and @abs(v.z()) < s;
    }

    pub fn reflect(u: *const Vec3, normal: *const Vec3) Vec3 {
        return u.sub(u.dot(normal).mul(normal).mul_scalar(2));
    }
};

pub const Point3 = Vec3;
pub const Color3 = Vec3;
