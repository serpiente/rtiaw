const std = @import("std");
const Hittable = @import("./Hittable.zig").Hittable;
const Color3 = @import("./vec.zig").Color3;
const Point3 = @import("./vec.zig").Point3;

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
    vfov: f64,
    lookfrom: Point3,
    lookat: Point3,
    vup: Vec3,
    defocus_angle: f64,
    focus_dist: f64,
    defocus_disk_u: Vec3,
    defocus_disk_v: Vec3,


    pub fn init(width: usize, aspect_ratio: f64) Camera {
        const samples_per_pixel: usize = 500;
        const max_depth: usize = 50;
        const vfov = 20.0;
        const defocus_angle = 0.6;  // Variation angle of rays through each pixel
        const focus_dist = 10;    // Distance from camera lookfrom point to plane of perfect focus

        const lookfrom = Point3.init(13, 2, 3);
        const lookat = Point3.init(0, 0, 0);
        const vup = Vec3.init(0, 1, 0);
        const position = lookfrom;

        const image_width = width;
        const image_height: usize = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        const focal_length: f64 = lookfrom.sub(lookat).length();

        const theta = degrees_to_radians(vfov);
        const h = @tan(theta / 2);
        const viewport_height = 2 * h * focus_dist;
        const viewport_width = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));


        // Calculate the u,v,w unit basis vectors for the camera coordinate frame.
        const w = lookfrom.sub(lookat).unit();
        const u = vup.cross_product(w).unit();
        const v = w.cross_product(u);

        const viewport_u = u.mul_scalar(viewport_width);
        const viewport_v = v.mul_scalar(-1.0 * viewport_height);

        const pixel_delta_u = viewport_u.div_scalar(@floatFromInt(image_width));
        const pixel_delta_v = viewport_v.div_scalar(@floatFromInt(image_height));


        const viewport_upper_left: Vec3 = position.sub(w.mul_scalar(focus_dist)).sub(viewport_u.div_scalar(2.0)).sub(viewport_v.div_scalar(2));
        //const viewport_upper_left: Vec3 = position.sub(Vec3.init(0, 0, focal_length)).sub(viewport_u.div_scalar(2)).sub(viewport_v.div_scalar(2));

        const defocus_radius = focus_dist * @tan(degrees_to_radians(defocus_angle / 2.0));
        const defocus_disk_u = u.mul_scalar(defocus_radius);
        const defocus_disk_v = v.mul_scalar(defocus_radius);

        const pixel_00_loc: Vec3 = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mul_scalar(0.5));

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
            .vfov = vfov,
            .lookfrom = lookfrom,
            .lookat = lookat,
            .vup = vup,
            .defocus_angle = defocus_angle,
            .focus_dist = focus_dist,
            .defocus_disk_u = defocus_disk_u,
            .defocus_disk_v = defocus_disk_v,
        };
    }

    fn degrees_to_radians(degrees: f64) f64 {
        return degrees * std.math.pi / 180.0;
    }

    pub fn render(self: *const Camera, allocator: std.mem.Allocator, world: Hittable) !void {
        var ppm = try PPM.init(allocator, self.image_width, self.image_height);
        defer ppm.deinit();

        var col: usize = 0;
        while (col < self.image_width) : (col += 1) {
            var row: usize = 0;
            while (row < self.image_height) : (row += 1) {
                var color = Vec3.zero();
                for (0..self.samples_per_pixel) |_| {
                    const ray = self.get_ray(row, col);
                    color = color.add(self.ray_color(self.max_depth, ray, &world));
                }
                color = color.div_scalar(@as(f64, @floatFromInt(self.samples_per_pixel)));
                const pixel = color3_to_rgb(color);
                ppm.data[col + row * self.image_width] = pixel;
            }
        }
        try ppm.save("image.ppm");
    }

    pub fn get_ray(self: *const Camera, i: usize, j: usize) Ray {
        const i_off = @as(f64, @floatFromInt(i)) - 0.5 + Utils.randomDouble();
        const j_off = @as(f64, @floatFromInt(j)) - 0.5 + Utils.randomDouble();
        const pixel_center: Vec3 = self.pixel_00_loc.add(self.pixel_delta_u.mul_scalar(j_off)).add(self.pixel_delta_v.mul_scalar(i_off));
        const ray_origin = if (self.defocus_angle <= 0) self.position else self.defocus_disk_sample();
        const ray_direction: Vec3 = pixel_center.sub(ray_origin);
        const ray = Ray.init(self.position, ray_direction);
        return ray;
    }

    pub fn defocus_disk_sample(self: Camera) Vec3 {
        const p = Vec3.random_in_unit_disk();
        return self.position.add(self.defocus_disk_u.mul_scalar(p.x())).add(self.defocus_disk_v.mul_scalar(p.y()));
    }

    pub fn ray_color(self: *const Camera, depth: usize, ray: Ray, world: *const Hittable) Color3 {
        if (depth <= 0) {
            return Color3.zero();
        }
        const positive_timeline: Interval = .{ .t_min = 0.001, .t_max = std.math.inf(f64) };
        if (world.hit(ray, positive_timeline)) |rec| {
            var scattered: Ray = undefined;
            var attenuation: Color3 = undefined;
            var mut_rec = rec;
            switch (rec.material) {
                .lambertian => {
                    if (rec.material.lambertian.scatter(ray, &mut_rec, &attenuation, &scattered)) return attenuation.mul(ray_color(self, depth - 1, scattered, world));
                    return Color3.zero();
                },
                .metal => {
                    if (rec.material.metal.scatter(ray, &mut_rec, &attenuation, &scattered)) return attenuation.mul(ray_color(self, depth - 1, scattered, world));
                    return Color3.zero();
                },
                .dialetric => {
                    if (rec.material.dialetric.scatter(ray, &mut_rec, &attenuation, &scattered)) return attenuation.mul(ray_color(self, depth - 1, scattered, world));
                    return Color3.zero();
                },
            }
        }

        const unit_direction = ray.direction.unit();
        const a = 0.5 * (unit_direction.y() + 1.0);
        const white = Color3.init(1.0, 1.0, 1.0);
        const blue = Color3.init(0.5, 0.7, 1.0);
        return white.mul_scalar(1.0 - a).add(blue.mul_scalar(a));
    }
};

fn linear_to_gamma(component: f64) f64 {
    if (component > 0) {
        return @sqrt(component);
    }
    return 0;
}

pub fn color3_to_rgb(color: Color3) RGB {
    const r: u8 = @intFromFloat(255.99 * linear_to_gamma(color.x()));
    const g: u8 = @intFromFloat(255.99 * linear_to_gamma(color.y()));
    const b: u8 = @intFromFloat(255.99 * linear_to_gamma(color.z()));
    return RGB{ .r = r, .g = g, .b = b };
}
