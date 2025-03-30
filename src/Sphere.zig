const Point3 = @import("./vec.zig").Point3;
const Interval = @import("./Interval.zig").Interval;
const Vec3 = @import("./vec.zig").Vec3;

const Ray = @import("./Ray.zig").Ray;
const HitRecord = @import("./Hittable.zig").HitRecord;
const Hittable = @import("./Hittable.zig").Hittable;

pub const Sphere = struct {
    center: Point3,
    radius: f64,

    pub fn init(center: Point3, radius: f64) Sphere {
        return Sphere{ .center = center, .radius = radius };
    }

    pub fn hittable(self: *Sphere) Hittable {
        return .{ .ptr = self, .vtable = &.{
            .hit = hit,
        } };
    }

    pub fn hit(ctx: *anyopaque, ray: Ray, interval: Interval) ?HitRecord {
        const self: *Sphere = @ptrCast(@alignCast(ctx));

        const oc: Vec3 = self.center.sub(ray.origin);
        const a = ray.direction.length_squared();
        const h = ray.direction.dot(oc);
        const c = oc.length_squared() - self.radius * self.radius;
        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return null;
        }
        const sqrtd = @sqrt(discriminant);
        var root = (h - sqrtd) / a;
        if (interval.is_outside(root)) {
            root = (h + sqrtd) / a;
            if (interval.is_outside(root)) {
                return null;
            }
        }

        const hit_point = ray.at(root);
        const normal = hit_point.sub(self.center).div_scalar(self.radius);
        const front_face = ray.direction.dot(normal) < 0;

        return .{
            .t = root,
            .point = hit_point,
            .front_face = front_face,
            .normal = if (front_face) normal else normal.mul_scalar(-1),
        };
    }
};
