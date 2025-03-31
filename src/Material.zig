const Ray = @import("./Ray.zig").Ray;
const HitRecord = @import("./Hittable.zig").HitRecord;
const Color3 = @import("./vec.zig").Color3;
const Utils = @import("./Utils.zig");
const Vec3 = @import("./vec.zig").Vec3;

pub const Material = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        scatter: *const fn (ctx: *anyopaque, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Color3, scattered: *Ray) bool,
    };

    pub fn scatter(self: *const Material, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Color3, scattered: *Ray) bool {
        return self.vtable.scatter(@constCast(self.ptr), ray_in, hit_record, attenuation, scattered);
    }
};

pub const Lambertian = struct {
    albedo: Color3,

    pub fn init(albedo: Color3) Lambertian {
        return .{
            .albedo = albedo,
        };
    }

    pub fn materialize(self: *const Lambertian) Material {
        return .{ .ptr = @constCast(self), .vtable = &.{
            .scatter = scatter,
        } };
    }

    pub fn scatter(ctx: *anyopaque, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Color3, scattered: *Ray) bool {
        const self: *Lambertian = @ptrCast(@alignCast(ctx));
        _ = ray_in;
        var scatter_direction = hit_record.normal.add(Vec3.random_unit_vector());
        if (Vec3.nearZero(scatter_direction)) {
            scatter_direction = hit_record.normal;
        }
        scattered.* = Ray.init(hit_record.point, scatter_direction);
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: Color3,

    pub fn init(albedo: Color3) Lambertian {
        return .{
            .albedo = albedo,
        };
    }

    pub fn materialize(self: *const Lambertian) Material {
        return .{ .ptr = @constCast(self), .vtable = &.{
            .scatter = scatter,
        } };
    }

    pub fn scatter(ctx: *anyopaque, ray_in: *const Ray, hit_record: *const HitRecord, attenuation: *Color3, scattered: *Ray) bool {
        const self: *Metal = @ptrCast(@alignCast(ctx));
        const reflected = ray_in.direction.reflect(hit_record.normal);
        scattered.* = Ray.init(hit_record.point, reflected);
        attenuation.* = self.albedo;
        return true;
    }
};
