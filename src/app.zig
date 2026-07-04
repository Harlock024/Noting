const platform = @import("platform");
const std = @import("std");
const fs = @import("fs.zig");

const Editor = @import("editor.zig");

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
editor: Editor,
io: std.Io,
path: []const u8,
// buffer: std.ArrayList(u8),
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

    var buf: [10240]u8 = undefined;
    const file_content = fs.readFile(io, &buf, content.path) catch "";

    var editor = try Editor.init(.{
     .font  = text.font,
     .renderer=  window.renderer,
    });

    errdefer editor.deinit();

    try editor.buffer.appendSlice(std.heap.page_allocator,file_content);
    editor.cursor_pos = editor.buffer.items.len;
    try window.show();
    const self = Self{
        .path = content.path,
        .window = window,
        .font = text,
        .io = io,
        .editor = editor, 
        .is_running = true,
    };
    return self;
}

pub fn deinit(self: *Self) void {
    self.window.deinit();
    self.editor.buffer.deinit(std.heap.page_allocator);
    platform.deinit();
}

pub fn update(self: *Self) void {
    _ = self;
}

pub fn render(self: *Self) !void {
    try self.window.clear(.{ .r = 30, .g = 30, .b = 30, .a = 255 });
    
    var y_offset: f32 = self.font.y;
    var line_count: usize = 0;
    var last_line: []const u8 = "";
    var lines = std.mem.splitScalar(u8, self.editor.buffer.items, '\n');
    while (lines.next()) |line| {
        last_line = line;
        if (line.len > 0) {
            try self.font.drawText(line, .{
                .r = 220, .g = 220, .b = 220, .a = 255,
            }, y_offset);
        }
        y_offset += 40;
    }

    if (self.editor.buffer.items.len > 0) {
        for(self.editor.buffer.items[0..self.editor.cursor_pos]) |char| {
            if(char == '\n') line_count += 1;
        }
        const cursor_y = self.font.y + @as(f32,@floatFromInt(line_count)) * 40;
        try self.editor.drawCursor(self.font.x,cursor_y);
    }
 
    try self.window.present();
}


pub fn handle_event(self: *Self, event: platform.Event) !void {
    switch (event) {
        .quit => self.is_running = false,
        .typping => |text| {
            try self.editor.insertText(text);
        },
        .editing => |key| switch (key) {
            platform.c.SDLK_BACKSPACE => {
                _ = self.editor.deleteChar();
            },
            platform.c.SDLK_RETURN => {
                try self.editor.insertEnter();          
            },
            platform.c.SDLK_S => {
                const mods = platform.c.SDL_GetModState();
                if (mods & platform.c.SDL_KMOD_CTRL != 0) {
                    try fs.writeFile(self.path, self.io, self.editor.buffer.items);
                    std.debug.print("guardando en {s}\n", .{self.path});
                }
            },
            platform.c.SDLK_LEFT     => try self.editor.cursorLeft(),
            platform.c.SDLK_RIGHT    => try  self.editor.cursorRight(),
            platform.c.SDLK_UP      => {
                std.debug.print("cursor pos {}\n", .{self.editor.cursor_pos});
                try self.editor.cursorUp();
            },
            platform.c.SDLK_DOWN => {
                std.debug.print("cursor pos {}\n", .{self.editor.cursor_pos});
                try self.editor.cursorDown();
            },
            platform.c.SDLK_SPACE    => {
                try self.editor.insertText("");
            },
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
