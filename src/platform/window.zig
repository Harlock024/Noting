const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;

const Self = @This();

window: *c.SDL_Window,
renderer:*c.SDL_Renderer,

pub fn init(title: [:0]const u8,width:i32,heigth:i32,is_resizable:bool) !Self {
    var window_flags: c.SDL_WindowFlags = c.SDL_WINDOW_HIDDEN;
    if (is_resizable) window_flags |= c.SDL_WINDOW_RESIZABLE;
    const window = c.SDL_CreateWindow(title, width, heigth, window_flags);

    try checkSDL(window != null);

    errdefer c.SDL_DestroyWindow(window);
    const renderer = c.SDL_CreateRenderer(window, null);
    try checkSDL(renderer != null);
    errdefer c.SDL_DestroyRenderer(renderer);
    return .{
        .window = window.?,
        .renderer = renderer.?,
    };
    
} 

pub fn show(self: *Self) !void {
    try checkSDL(c.SDL_ShowWindow(self.window));
    _ =c.SDL_StartTextInput(self.window);
}

pub fn deinit(self: *Self) void {
    c.SDL_DestroyRenderer(self.renderer);
    c.SDL_DestroyWindow(self.window);
}

const COLOR = struct {
    r:f32,
    g:f32,
    b:f32,
    a:f32,
};

pub fn  clear(self: *Self, color: COLOR) !void {
    try checkSDL(c.SDL_SetRenderDrawColorFloat(self.renderer,
            color.r / 255.0,
            color.g / 255.0,
            color.b / 255.0,
            color.a / 255.0,
    ));
    try checkSDL(c.SDL_RenderClear(self.renderer));
}

pub fn present(self: *Self) !void {
    try checkSDL(c.SDL_RenderPresent(self.renderer));
}













