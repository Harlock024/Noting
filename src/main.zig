const App = @import("app.zig");

pub fn main() !void {
    var app = try App.init(
        .{ 
            .title = "Noting",
            .width = 800,
            .height = 600,
            .is_resizable = true,
        },
        .{
            .font = "/usr/share/fonts/TTF/DejaVuSans.ttf",
            .size = 40,
            .x  = 400,
            .y = 300,
        }
    );
    defer app.deinit();
    try app.run();
}

