const std = @import("std");
const Point3 = @import("./vec.zig").Point3;
const Vec3 = @import("./vec.zig").Vec3;
const Color3 = @import("./vec.zig").Color3;
const Ray = @import("./Ray.zig").Ray;
const HitRecord = @import("./Hittable.zig").HitRecord;
const Sphere = @import("./Sphere.zig").Sphere;
const Hittable = @import("./Hittable.zig").Hittable;
const HittableList = @import("./Hittable.zig").HittableList;
const Interval = @import("./Interval.zig").Interval;
const Camera = @import("./Camera.zig").Camera;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;
    const width: usize = 512;

    //World
    var world: HittableList = HittableList.init(allocator);
    defer world.deinit();

    var sphere1 = Sphere.init(Point3.init(0, 0, -1), 0.5);
    var sphere2 = Sphere.init(Point3.init(0, -100.5, -1), 100);

    try world.add(sphere1.hittable());
    try world.add(sphere2.hittable());

    const camera = Camera.init(width, aspect_ratio);

    try camera.render(allocator, world.hittable());
}
