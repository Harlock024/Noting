const c = @import("c.zig").c;
const checkSDL = @import("internal.zig").checkSDL;
const std = @import("std");
const Self = @This();


font: *c.TTF_Font,
renderer:*c.SDL_Renderer,
x:f32,
y:f32,    

pub fn init(path: [:0]const u8,size:f32,x:f32,y:f32,renderer:*c.SDL_Renderer,) !Self {
    const font = c.TTF_OpenFont(path,size);
    try  checkSDL(font != null);
    errdefer c.TTF_CloseFont(font);
    return .{
         .font = font.?,
         .x = x,
         .y = y,
         .renderer = renderer,
    };
}

pub fn deinit(self: *Self) void {
    c.TTF_CloseFont(self.font);
}


pub fn drawText(self:*Self,text:[]const u8,fontColor:c.SDL_Color)!void{
    const surface=c.TTF_RenderText_Solid(self.font,
        text.ptr,
        0,
        fontColor);
    try checkSDL(surface != null);
    defer c.SDL_DestroySurface(surface);
    const texture = c.SDL_CreateTextureFromSurface(self.renderer,surface);
    try checkSDL(texture != null);
    defer c.SDL_DestroyTexture(texture);
    var w:f32 = 0;
    var h:f32 = 0;
    try checkSDL(c.SDL_GetTextureSize(texture,&w,&h));
    const dst = c.SDL_FRect{
        .w = w,
        .h = h,
        .x = self.x,
        .y = self.y,
    };
    try checkSDL(c.SDL_RenderTexture(self.renderer,texture,null,&dst));  
}





