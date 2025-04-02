const std = @import("std");
const Ray = @import("./Ray.zig").Ray;
const Interval = @import("./Interval.zig").Interval;

const Point3 = @import("./vec.zig").Point3;
const Vec3 = @import("./vec.zig").Vec3;

const Material = @import("./Material.zig").Material;

pub const HitRecord = struct {
    point: Point3,
    normal: Vec3,
    t: f64,
    front_face: bool,
    material: Material,
};

pub const Hittable = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        hit: *const fn (ctx: *anyopaque, ray: Ray, interval: Interval) ?HitRecord,
    };

    pub fn hit(self: Hittable, ray: Ray, interval: Interval) ?HitRecord {
        return self.vtable.hit(self.ptr, ray, interval);
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(Hittable),

    pub fn init(allocator: std.mem.Allocator) HittableList {
        return .{
            .objects = std.ArrayList(Hittable).init(allocator),
        };
    }

    pub fn deinit(self: *HittableList) void {
        return self.objects.deinit();
    }

    pub fn add(self: *HittableList, obj: Hittable) !void {
        try self.objects.append(obj);
    }

    pub fn hittable(self: *HittableList) Hittable {
        return .{ .ptr = self, .vtable = &.{ .hit = hit } };
    }

    pub fn hit(ctx: *anyopaque, ray: Ray, interval: Interval) ?HitRecord {
        const self: *HittableList = @ptrCast(@alignCast(ctx));

        var closest: f64 = interval.t_max;
        var hit_record: ?HitRecord = null;

        for (self.objects.items) |obj| {
            const candidate = Interval{ .t_min = interval.t_min, .t_max = closest };
            if (obj.hit(ray, candidate)) |new_hit_record| {
                hit_record = new_hit_record;
                closest = new_hit_record.t;
            }
        }
        return hit_record;
    }
};
