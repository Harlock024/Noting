pub const Window = @import("window.zig");
pub const Font = @import("font.zig");
pub const Event = @import("event.zig").Event;

pub const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;

pub fn init() !void {
    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "wayland");
    try checkSDL(c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS));
    try checkSDL(c.TTF_Init());
}

pub fn deinit() void {
    c.SDL_Quit();
}


