const App = @import("app.zig");
const std = @import("std");

pub fn main(init:std.process.Init) !void {
    var args = init.minimal.args.iterate();
    _ = args.next();
    const path = args.next() orelse "notas.md";
    var app = try App.init(
        init.io,
        .{ 
            .title = "Noting",
            .width = 800,
            .height = 600,
            .is_resizable = true,
        },
        .{
            .font = "public/jetbrains-mono-latin-400-normal.ttf",
            .path = path,
            .size = 40,
            .x  = 20,
            .y = 20,
        }
    );
    defer app.deinit();
    try app.run();
}

