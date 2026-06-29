const platform = @import("platform");
const std = @import("std");
const fs = @import("fs.zig");

pub const Config = struct {
    title: [:0]const u8,
    width: i32,
    height: i32,
    is_resizable: bool,
};

pub const Content = struct {
    font: [:0]const u8,
    path: []const u8,
    size: f32,
    x: f32,
    y: f32,
};

const Self = @This();
io: std.Io,
path: []const u8,
buffer: std.ArrayList(u8),
window: platform.Window,
font: platform.Font,
is_running: bool = true,

pub fn init(io: std.Io, config: Config, content: Content) !Self {
    try platform.init();
    errdefer platform.deinit();

    var window = try platform.Window.init(
        config.title,
        config.width,
        config.height,
        config.is_resizable,
    );
    errdefer window.deinit();

    var text = try platform.Font.init(
        content.font,
        content.size,
        content.x,
        content.y,
        window.renderer,
    );

    errdefer text.deinit();
    try window.show();
    var buf: [10240]u8 = undefined;
    const file_content = fs.readFile(io, &buf, content.path) catch "";
    var self = Self{
        .buffer = std.ArrayList(u8).empty,
        .path = content.path,
        .window = window,
        .font = text,
        .io = io,
        .is_running = true,
    };
    try self.buffer.appendSlice(std.heap.page_allocator, file_content);
    return self;
}
pub fn deinit(self: *Self) void {
    self.window.deinit();
    self.buffer.deinit(std.heap.page_allocator);
    platform.deinit();
}

pub fn update(self: *Self) void {
    _ = self;
}

pub fn render(self: *Self) !void {
    try self.window.clear(.{
        .r = 30,
        .g = 30,
        .b = 30,
        .a = 255,
    });

    if (self.buffer.items.len > 0) {
        var y_offset: f32 = self.font.y;
        var lines = std.mem.splitScalar(u8, self.buffer.items, '\n');
        while (lines.next()) |line| {
            if (line.len > 0) {
                try self.font.drawText(line, .{
                    .r = 220,
                    .g = 220,
                    .b = 220,
                    .a = 255,
                }, y_offset);
            }
            y_offset += 40;
        }
    }
    try self.window.present();
}
pub fn handle_event(self: *Self, event: platform.Event) !void {
    switch (event) {
        .quit => self.is_running = false,
        .typping => |text| {
            try self.buffer.appendSlice(std.heap.page_allocator, text);
        },
        .editing => |key| switch (key) {
            platform.c.SDLK_BACKSPACE => {
                _ = self.buffer.pop();
            },
            platform.c.SDLK_RETURN => {
                try self.buffer.appendSlice(std.heap.page_allocator, "\n");

                std.debug.print("buffer raw {any}\n", .{self.buffer.items});
            },
            platform.c.SDLK_S => {
                const mods = platform.c.SDL_GetModState();
                if (mods & platform.c.SDL_KMOD_CTRL != 0) {
                    try fs.writeFile(self.path, self.io, self.buffer.items);
                    std.debug.print("guardando en {s}\n", .{self.path});
                }
            },
            // platform.c.SDLK_LEFT     => std.debug.print("flecha izq\n", .{}),
            // platform.c.SDLK_RIGHT    => std.debug.print("flecha der\n", .{}),
            else => {},
        },
        else => {},
    }
}
pub fn run(self: *Self) !void {
    while (self.is_running) {
        while (platform.Event.poll()) |event| {
            try self.handle_event(event);
        }
        self.update();
        try self.render();
    }
}
