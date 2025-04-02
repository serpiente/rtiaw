const Point3 = @import("./vec.zig").Point3;
const Interval = @import("./Interval.zig").Interval;
const Vec3 = @import("./vec.zig").Vec3;
const Color3 = @import("./vec.zig").Color3;
const HitRecord = @import("./Hittable.zig").HitRecord;
const Ray = @import("./Ray.zig").Ray;
const Utils = @import("./Utils.zig");
const std = @import("std");

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dialetric: Dialetric,

    pub const Lambertian = struct {
        albedo: Color3,

        pub fn init(albedo: Color3) Material {
            return .{ .lambertian = .{ .albedo = albedo } };
        }

        pub fn scatter(self: Lambertian, r_in: Ray, hit_record: *HitRecord, attenuation: *Color3, scattered: *Ray) bool {
            _ = r_in;
            var scatter_direction = hit_record.normal.add(Vec3.random_unit_vector());
            if (scatter_direction.near_zero()) scatter_direction = hit_record.normal;
            scattered.* = Ray.init(hit_record.point, scatter_direction);
            attenuation.* = self.albedo;
            return true;
        }
    };

    pub const Metal = struct {
        albedo: Color3,

        pub fn init(albedo: Color3) Material {
            return .{ .metal = .{ .albedo = albedo } };
        }

        pub fn scatter(self: Metal, r_in: Ray, hit_record: *HitRecord, attenuation: *Color3, scattered: *Ray) bool {
            var reflected = r_in.direction.reflect(hit_record.normal);
            reflected = reflected.unit().add(Vec3.random_unit_vector());
            scattered.* = Ray.init(hit_record.point, reflected);
            attenuation.* = self.albedo;
            return (scattered.direction.dot(hit_record.normal) > 0);
        }
    };

    pub const Dialetric = struct {
        refraction_index: f64,

        pub fn init(refraction_index: f64) Material {
            return .{ .dialetric = .{ .refraction_index = refraction_index } };
        }

        fn reflectance(self: Dialetric, cosine: f64, refraction_index: f64) f64 {
            // Use Schlick's approximation for reflectance.
            _ = self;
            var r0 = (1 - refraction_index) / (1 + refraction_index);
            r0 = r0 * r0;
            return r0 + (1 - r0) * std.math.pow(f64, (1 - cosine), 5);
        }

        pub fn scatter(self: Dialetric, r_in: Ray, hit_record: *HitRecord, attenuation: *Color3, scattered: *Ray) bool {
            attenuation.* = Color3.init(1.0, 1.0, 1.0);
            const ri = if (hit_record.front_face) (1 / self.refraction_index) else self.refraction_index;
            const unit_direction = r_in.direction.unit();

            const cos_theta: f64 = @min(unit_direction.mul_scalar(-1).dot(hit_record.normal), 1.0);
            const sin_theta: f64 = @sqrt(1.0 - cos_theta * cos_theta);

            const cannot_refract = ri * sin_theta > 1.0;

            var direction: Vec3 = undefined;
            if (cannot_refract or self.reflectance(cos_theta, ri) > Utils.randomDouble()) {
                direction = unit_direction.reflect(hit_record.normal);
            } else {
                direction = unit_direction.refract(hit_record.normal, ri);
            }

            scattered.* = Ray.init(hit_record.point, direction);
            return true;
        }
    };
};
