const std = @import("std");
const Hittable = @import("./Hittable.zig").Hittable;
const Color3 = @import("./vec.zig").Color3;
const Vec3 = @import("./vec.zig").Vec3;
const Ray = @import("./Ray.zig").Ray;
const Interval = @import("./Interval.zig").Interval;
const RGB = @import("./PPM.zig").RGB;
const PPM = @import("./PPM.zig").PPM;
const Utils = @import("./Utils.zig");
const AspectRatio = struct { x: usize, y: usize };

pub const Camera = struct {
    image_height: usize,
    image_width: usize,
    focal_length: f64,
    viewport_height: f64,
    viewport_width: f64,
    position: Vec3,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    pixel_00_loc: Vec3,
    samples_per_pixel: usize,
    max_depth: usize,

    pub fn init(width: usize, aspect_ratio: f64) Camera {
        const image_width = width;
        const image_height: usize = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        const focal_length: f64 = 1.0;

        const viewport_height: f64 = 2.0;
        const viewport_width: f64 = viewport_height * @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));

        const position = Vec3.zero();

        const viewport_u = Vec3.init(viewport_width, 0, 0);
        const viewport_v = Vec3.init(0, -viewport_height, 0);

        const pixel_delta_u = viewport_u.div_scalar(@floatFromInt(image_width));
        const pixel_delta_v = viewport_v.div_scalar(@floatFromInt(image_height));

        const viewport_upper_left: Vec3 = position.sub(Vec3.init(0, 0, focal_length)).sub(viewport_u.div_scalar(2)).sub(viewport_v.div_scalar(2));

        const pixel_00_loc: Vec3 = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mul_scalar(0.5));

        const samples_per_pixel: usize = 10;
        const max_depth:usize = 50;

        return .{
            .image_height = image_height,
            .image_width = image_width,
            .focal_length = focal_length,
            .viewport_height = viewport_height,
            .viewport_width = viewport_width,
            .position = position,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .pixel_00_loc = pixel_00_loc,
            .samples_per_pixel = samples_per_pixel,
            .max_depth = max_depth,
        };
    }

    pub fn render(self: *const Camera, allocator: std.mem.Allocator, world: Hittable) !void {
        var ppm = try PPM.init(allocator, self.image_width, self.image_height);
        defer ppm.deinit();

        var col: usize = 0;
        while (col < self.image_width) : (col += 1) {
            var row: usize = 0;
            while (row < self.image_height) : (row += 1) {
                
                var color = Vec3.zero();
                for(0..self.samples_per_pixel) |_| {
                    const ray = self.get_ray(row, col);
                    color = color.add(self.ray_color(self.max_depth,ray, &world));
                }
                color = color.div_scalar(@as(f64, @floatFromInt(self.samples_per_pixel)));
                const pixel = color3_to_rgb(color);
                ppm.data[col + row * self.image_width] = pixel;
            }
        }
        try ppm.save("image.ppm");
    }

    pub fn get_ray(self: *const Camera, i: usize, j:usize) Ray {
        const i_off = @as(f64, @floatFromInt(i)) - 0.5 + Utils.randomDouble();
        const j_off = @as(f64, @floatFromInt(j)) - 0.5 + Utils.randomDouble();
        const pixel_center: Vec3 = self.pixel_00_loc.add(self.pixel_delta_u.mul_scalar(j_off)).add(self.pixel_delta_v.mul_scalar(i_off));
        const ray_direction: Vec3 = pixel_center.sub(self.position);
        const ray = Ray.init(self.position, ray_direction);
        return ray;
    }

    pub fn ray_color(self:*const Camera, depth: usize, ray: Ray, world: *const Hittable) Color3 {
        if (depth <= 0){
            return Color3.zero();
        }
        const positive_timeline: Interval = .{ .t_min = 0.001, .t_max = std.math.inf(f64) };
        if (world.hit(ray, positive_timeline)) |hit_record| {
            const dir = Vec3.random_on_hemisphere(&hit_record.normal);
            return self.ray_color(depth - 1, Ray.init(hit_record.point, dir), world).mul_scalar(0.5);
            //return hit_record.normal.add(Color3.init(1, 1, 1)).mul_scalar(0.5);
        }

        const unit_direction = ray.direction.unit();
        const a = 0.5 * (unit_direction.y() + 1.0);
        const white = Color3.init(1.0, 1.0, 1.0);
        const blue = Color3.init(0.5, 0.7, 1.0);
        return white.mul_scalar(1.0 - a).add(blue.mul_scalar(a));
    }
};

pub fn color3_to_rgb(color: Color3) RGB {
    return RGB{ .r = @intFromFloat(255.99 * color.x()), .g = @intFromFloat(255.99 * color.y()), .b = @intFromFloat(255.99 * color.z()) };
}
