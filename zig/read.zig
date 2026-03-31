
// clear && zig build-exe read.zig -O ReleaseFast -mcpu=native && /usr/bin/time -v ./read

const std = @import("std");

const BUF_SIZE: usize = 65536;

inline fn fastParseInt(p: [*]const u8, next: ?*[*]const u8) i32 {
    var ptr = p;
    var val: i32 = 0;
    var neg: bool = false;

    if (ptr[0] == '-') {
        neg = true;
        ptr += 1;
    }

    while (ptr[0] >= '0' and ptr[0] <= '9') {
        val = val * 10 + (ptr[0] - '0');
        ptr += 1;
    }

    if (ptr[0] == '.') {
        ptr += 1;
        if (ptr[0] >= '0' and ptr[0] <= '9') {
            val = val * 10 + (ptr[0] - '0');
            ptr += 1;
        }
    }

    if (next) |n| {
        n.* = ptr;
    }

    return if (neg) -val else val;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../out.csv", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;

    var buf = try allocator.alloc(u8, BUF_SIZE);
    defer allocator.free(buf);

    var final_min: i32 = std.math.maxInt(i32);
    var final_max: i32 = std.math.minInt(i32);

    var min_city: [128]u8 = undefined;
    var max_city: [128]u8 = undefined;

    var total_count: i32 = 0;
    var leftover: usize = 0;

    while (true) {
        const n = try file.read(buf[leftover..BUF_SIZE]);
        if (n == 0 and leftover == 0) break;

        const total = n + leftover;

        var ptr: usize = 0;

        while (ptr < total) {
            const remaining = buf[ptr..total];

            const newline_opt = std.mem.indexOfScalar(u8, remaining, '\n');
            if (newline_opt == null) break;

            const line_end = ptr + newline_opt.?;

            const line = buf[ptr..line_end];
            const sep_opt = std.mem.indexOfScalar(u8, line, ';');

            if (sep_opt) |sep_idx| {
                const city = line[0..sep_idx];

                const value_ptr = line[sep_idx + 1 ..].ptr;
                const val = fastParseInt(value_ptr, null);

                if (val < final_min) {
                    final_min = val;
                    std.mem.copyForwards(u8, min_city[0..city.len], city);
                    min_city[city.len] = 0;
                }

                if (val > final_max) {
                    final_max = val;
                    std.mem.copyForwards(u8, max_city[0..city.len], city);
                    max_city[city.len] = 0;
                }

                total_count += 1;
            }

            ptr = line_end + 1;
        }

        leftover = total - ptr;
        std.mem.copyForwards(u8, buf[0..leftover], buf[ptr..total]);
    }

    std.debug.print(
        "Min: {d:.1} ({s})\nMax: {d:.1} ({s})\nRows: {}\n",
        .{
            @as(f32, @floatFromInt(final_min)) / 10.0,
            std.mem.sliceTo(&min_city, 0),
            @as(f32, @floatFromInt(final_max)) / 10.0,
            std.mem.sliceTo(&max_city, 0),
            total_count,
        },
    );
}
