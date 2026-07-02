const platform = @import("platform");

const std = @import("std");

const Self = @This();

font: *platform.c.TTF_Font,
buffer: std.ArrayList(u8),
renderer:*platform.c.SDL_Renderer,    
cursor_pos:usize = 0,


const Config = struct {
font: *platform.c.TTF_Font,
renderer:*platform.c.SDL_Renderer,
};

const Cursor = struct {
    font: *platform.c.TTF_Font,
    line: []const u8,
};

pub fn init(config:Config)!Self{

    
    return .{
        .buffer = std.ArrayList(u8).empty,
        .font = config.font,
        .renderer = config.renderer,
    };
}

pub fn deinit(self:*Self) void {
    self.font = undefined;
    self.renderer = undefined;
  
}
pub fn insertText(self:*Self,text:[]const u8) !void{
    try self.buffer.appendSlice(std.heap.page_allocator, text);
    self.cursor_pos +=1;
}

pub fn insertEnter(self:*Self) !void {
    try self.buffer.appendSlice(std.heap.page_allocator,"\n");
    self.cursor_pos +=1;
}

pub fn deleteChar(self:*Self) void{
    std.debug.print("deleteChar llamado, len:{} pos:{}\n", .{self.buffer.items.len, self.cursor_pos});
    if(self.buffer.items.len == 0) return;
    if(self.cursor_pos == 0) return;
    _ = self.buffer.pop();
    self.cursor_pos -=1;
}

pub fn drawCursor(self: *Self, x: f32, y: f32) !void {    
    const text_before_cursor = self.getTextBeforeCursor();
    
    var w: c_int = 0;
    var h: c_int = 20;
       
    if(text_before_cursor.len > 0){
    _ = platform.c.TTF_GetStringSize(
        self.font,
        text_before_cursor.ptr,
        text_before_cursor.len,
        &w,
        &h
        );
    }
    
    const cursor_x = x + @as(f32, @floatFromInt(w));
    const cursor_height = @as(f32, @floatFromInt(h));
    
    const cursor_rect = platform.c.SDL_FRect{
        .x = cursor_x,
        .y = y,
        .w = 2,
        .h = cursor_height,
    };
    
    _ = platform.c.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255);
    _ = platform.c.SDL_RenderFillRect(self.renderer, &cursor_rect);
}

pub fn cursorLeft(self:*Self) !void {
    if(self.buffer.items.len == 0) return;
    if(self.cursor_pos > 0) {
    self.cursor_pos-=1;
    }
}

pub fn cursorRight(self:*Self)  !void{
    if(self.buffer.items.len == 0 )return;
    if(self.cursor_pos < self.buffer.items.len){
    self.cursor_pos +=1;
    }
}

fn getTextBeforeCursor(self:*Self) []const u8{
    
    if (self.buffer.items.len == 0 ){
        return &[_]u8{};
    }
    
    if (self.cursor_pos == 0) {
        return &[_]u8{};
    }
        
    const pos = @min(self.cursor_pos, self.buffer.items.len);


    if(self.cursor_pos > self.buffer.items.len){
        self.cursor_pos = self.buffer.items.len;
    }
        
    var line_start:usize = 0 ;
    for(self.buffer.items[0..pos],0..) |char,i|{
        if(char=='\n'){
            line_start = i + 1;
        }
    }

    const start = line_start;
    const end = pos;

    if (start >= self.buffer.items.len or end > self.buffer.items.len or start > end) {
        return &[_]u8{};
    }
    return self.buffer.items[start..end];
}

fn getCurrentLine(self: *Self) []const u8 {
    var line_start: usize = 0;
    var line_end: usize = self.buffer.items.len;
    
    for (self.buffer.items, 0..) |char, i| {
        if (char == '\n') {
            if (i < self.cursor_pos) {
                line_start = i + 1;
            } else if (i >= self.cursor_pos) {
                line_end = i;
                break;
            }
        }
    }
    return self.buffer.items[line_start..line_end];
}

