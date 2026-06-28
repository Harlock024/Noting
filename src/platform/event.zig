const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;
const std = @import("std");


pub const Event = union(enum) {
    quit,
    typping:[]const u8,
    editing:c.SDL_Keycode,
    other,

 pub fn poll() ?Event {
        var event: c.SDL_Event = undefined; 
        if(c.SDL_PollEvent(&event)){
            return switch (event.type) {
                c.SDL_EVENT_QUIT => .quit,

                c.SDL_EVENT_TEXT_INPUT => .{
                  .typping = std.mem.sliceTo(event.text.text,0),
                },
                c.SDL_EVENT_KEY_DOWN  => .{ 
                  .editing =event.key.key,
                },
                else => .other,
            };
        }
        
        return null;
    }
};
