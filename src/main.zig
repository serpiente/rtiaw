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
const Material = @import("./Material.zig").Material;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;
    const width: usize = 1200;

    //World
    var world: HittableList = HittableList.init(allocator);
    defer world.deinit();

    const ground_material = Material.Lambertian.init(Color3.init(0.5, 0.5, 0.5));
    var ground = Sphere.init(Point3.init(0, -1000, 0), 1000,ground_material);
    try world.add(ground.hittable());

    const rand = std.crypto.random;
    var a: f64 = -5;
    while (a < 5) : (a += 1) {
        var b: f64 = -5;
        while (b < 5) : (b += 1) {
            const choose_mat = rand.float(f64);
            // std.debug.print("{} \n", .{choose_mat});
            const center = Point3.init(a + 0.9 * rand.float(f64), 0.2, b + 0.9 * rand.float(f64));

            if ((center.sub(Point3.init(4, 0.2, 0))).length() > 0.9) {
                if (choose_mat < 0.8) {
                    const albedo = Color3.randomBounded(0, 1).mul(Color3.randomBounded(0, 1));
                    // std.debug.print("{} {} {} \n", .{ albedo.x(), albedo.y(), albedo.z() });
                    var sphere = Sphere{ .center = center, .radius = 0.2, .material = Material.Lambertian.init(albedo)};
                    try world.add(sphere.hittable());
                } else if (choose_mat < 0.95) {
                    const albedo = Color3.randomBounded(0.5, 1);
                    var sphere = Sphere{ .center = center, .radius = 0.2, .material = Material.Metal.init(albedo) };
                    try world.add(sphere.hittable());
                } else {
                    var sphere = Sphere{ .center = center, .radius = 0.2, .material = Material.Dialetric.init(1.5) };
                    try world.add(sphere.hittable());
                }
            }
        }
    }

    const material1 = Material.Dialetric.init(1.5);
    var sphere = Sphere{ .center = Point3.init(0, 1, 0), .radius = 1.0, .material = material1 };
    try world.add(sphere.hittable());

    const material2 = Material.Lambertian.init(Color3.init(0.4, 0.2, 0.1));
    var sphere2 = Sphere{ .center = Point3.init(4, 1, 0), .radius = 1.0, .material = material2 };
    try world.add(sphere2.hittable());

    const material3 = Material.Metal.init(Color3.init(0.7, 0.6, 0.5));
    var sphere3 = Sphere{ .center = Point3.init(4, 1, 0), .radius = 1.0, .material  = material3};

    try world.add(sphere3.hittable());

    
    const camera = Camera.init(width, aspect_ratio);

    try camera.render(allocator, world.hittable());
}
