const platform = @import("platform");
const std = @import("std");


pub const Config = struct {
    title: [:0]const u8,
    width:i32,
    height:i32,
    is_resizable:bool,
};

pub const Content = struct {
    font: [:0]const u8,
    size: f32,
    x:f32,
    y:f32,
};

const Self = @This();
buffer: std.ArrayList(u8),
window: platform.Window,
font: platform.Font,
is_running: bool = true,


    pub fn init(config:Config,content:Content)!Self{
        try platform.init();
        errdefer platform.deinit();

        var window  = try platform.Window.init(
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
        
        return .{
            .buffer = std.ArrayList(u8).empty,
            .window = window,
            .font = text,
            .is_running = true,
        };
}
pub fn deinit(self:*Self) void {
    self.window.deinit();
    self.buffer.deinit(std.heap.page_allocator);
    platform.deinit();

}



pub fn update(self: *Self) void {
    _ = self;
}

pub fn render(self:*Self) !void {
    try self.window.clear(.{
        .r = 255,
        .g= 0,
        .b=0,
        .a= 255,
    });

    std.debug.print("buffer en render: {s} len:{}\n", .{self.buffer.items, self.buffer.items.len});
    if (self.buffer.items.len > 0){
    try self.font.drawText(
        self.buffer.items,
        .{
        .r = 255,
        .g= 255,
        .b=255,
        .a= 255,
         });
    }
    std.debug.print("buffer en render (despues de drawText): {s} len:{}\n", .{self.buffer.items, self.buffer.items.len});
    try self.window.present();
    
}
pub fn handle_event(self: *Self,event: platform.Event)!void {
    std.debug.print("evento recibido\n", .{});
    switch (event) {
        .quit => self.is_running = false,
        .typping => |text|  {
            try self.buffer.appendSlice(std.heap.page_allocator,text);
            std.debug.print("typing: {s} len:{}\n", .{text, text.len});
                },
        .editing => |key| switch (key) {
                    platform.c.SDLK_BACKSPACE => {_  = self.buffer.pop();},
                    platform.c.SDLK_RETURN   => std.debug.print("enter\n", .{}),
                    platform.c.SDLK_LEFT     => std.debug.print("flecha izq\n", .{}),
                    platform.c.SDLK_RIGHT    => std.debug.print("flecha der\n", .{}),
                else =>{ },
                },
            else => { },
    }
}
pub fn run(self: *Self) !void {
    while (self.is_running) {
        while (platform.Event.poll()) |event| {
            std.debug.print("Evento en run\n", .{});
            try self.handle_event(event);
        }
          self.update();
          try  self.render();
    }
}
