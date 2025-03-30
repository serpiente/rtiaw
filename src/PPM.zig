const std = @import("std");
pub const RGB = struct { r: u8, g: u8, b: u8 };

pub const PPM = struct {
    width: usize,
    height: usize,
    data: []RGB,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !PPM {
        const self = PPM{ .width = width, .height = height, .data = try allocator.alloc(RGB, width * height), .allocator = allocator };
        return self;
    }

    pub fn deinit(self: *PPM) void {
        self.allocator.free(self.data);
    }

    pub fn save(self: *PPM, filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        const file_writer = file.writer();

        var bufferedWriter = std.io.bufferedWriter(file_writer);
        var bwriter = bufferedWriter.writer();
        try bwriter.print("P3\n{} {}\n255\n", .{ self.width, self.height });

        for (self.data) |pixel| {
            try bwriter.print("{} {} {}\n", .{ pixel.r, pixel.g, pixel.b });
        }
        try bufferedWriter.flush();
    }
};
