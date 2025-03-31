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
const Material = @import("./Material.zig");

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

    const material_ground =  Material.Lambertian.init(Vec3.init(0.8, 0.8, 0.0));
    const material_center =  Material.Lambertian.init(Vec3.init(0.1, 0.2, 0.5));
    const material_left =  Material.Metal.init(Vec3.init(0.8, 0.8, 0.8));
    const material_right =  Material.Metal.init(Vec3.init(0.8, 0.6, 0.2));

    var sphere1 = Sphere.init(Point3.init(0, -100.5, -1), 100, material_ground.materialize());
    var sphere2 = Sphere.init(Point3.init( 0.0,    0.0, -1.2), 0.5, material_center.materialize());
    var sphere3 = Sphere.init(Point3.init(-1.0,    0.0, -1.0), 0.5, material_left.materialize());
    var sphere4 = Sphere.init(Point3.init( 1.0,    0.0, -1.0), 0.5, material_right.materialize());

    try world.add(sphere1.hittable());
    try world.add(sphere2.hittable());
    try world.add(sphere3.hittable());
    try world.add(sphere4.hittable());

    const camera = Camera.init(width, aspect_ratio);

    try camera.render(allocator, world.hittable());
}
