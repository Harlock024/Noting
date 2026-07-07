const platform = @import("platform");

const std = @import("std");


const Self = @This();

font: *platform.c.TTF_Font,
buffer: std.ArrayList(u8),
renderer:*platform.c.SDL_Renderer,    
cursor_pos:usize = 0,
line_height: c_int = 0,
line_count: u8 = 0,
scroll_offset:u8 = 0,
preferred_col:usize = 0,
at_line_end:bool = false,

const Config = struct {
font: *platform.c.TTF_Font,
renderer:*platform.c.SDL_Renderer,
};

const Cursor = struct {
    font: *platform.c.TTF_Font,
    line: []const u8,
};

pub fn init(config: Config) !Self {
    var w: c_int = 0;
    var h: c_int = 20;
    _ = platform.c.TTF_GetStringSize(config.font, "A", 1, &w, &h);

    return .{
        .buffer = std.ArrayList(u8).empty,
        .font = config.font,
        .line_height = h,
        .renderer = config.renderer,
        .cursor_pos = 0,
    };
}

pub fn deinit(self:*Self) void {
    self.font = undefined;
    self.renderer = undefined;
}
                                            
pub fn insertText(self:*Self,text:[]const u8) !void{
    try self.buffer.insertSlice(std.heap.page_allocator,self.cursor_pos, text);
    self.cursor_pos +=text.len;
    const current_line_start = std.mem.lastIndexOfScalar(u8, self.buffer.items[0..self.cursor_pos], '\n');
    if(self.cursor_pos == self.buffer.items.len){ 
        self.at_line_end = true;
    }else{
        self.at_line_end = (self.buffer.items[self.cursor_pos] == '\n'); 
    }
    self.preferred_col = self.cursor_pos - if (current_line_start) |p| p + 1 else 0;
}

pub fn insertEnter(self:*Self) !void {
    try self.buffer.insertSlice(std.heap.page_allocator,self.cursor_pos,"\n");
    self.cursor_pos +=1;
    const current_line_start = std.mem.lastIndexOfScalar(u8, self.buffer.items[0..self.cursor_pos], '\n');
    if(self.cursor_pos == self.buffer.items.len){ 
        self.at_line_end = true;
    }else{
        self.at_line_end = (self.buffer.items[self.cursor_pos] == '\n'); 
    }
    self.preferred_col = self.cursor_pos - if (current_line_start) |p| p + 1 else 0;
}

pub fn deleteChar(self:*Self) void{
    std.debug.print("deleteChar llamado, len:{} pos:{}\n", .{self.buffer.items.len, self.cursor_pos});
    if(self.buffer.items.len == 0) return;
    if(self.cursor_pos == 0) return;
    _ = self.buffer.orderedRemove(self.cursor_pos - 1);
    self.cursor_pos -=1;
    const current_line_start = std.mem.lastIndexOfScalar(u8, self.buffer.items[0..self.cursor_pos], '\n');
    if(self.cursor_pos == self.buffer.items.len){ 
        self.at_line_end = true;
    }else{
        self.at_line_end = (self.buffer.items[self.cursor_pos] == '\n'); 
    }  
    self.preferred_col = self.cursor_pos - if (current_line_start) |p| p + 1 else 0;
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
    const current_line_start = std.mem.lastIndexOfScalar(u8, self.buffer.items[0..self.cursor_pos], '\n');
    if(self.cursor_pos == self.buffer.items.len){ 
        self.at_line_end = true;
    }else{
        self.at_line_end = (self.buffer.items[self.cursor_pos] == '\n'); 
    }  

    self.preferred_col = self.cursor_pos - if (current_line_start) |p| p + 1 else 0;
    }
}

pub fn cursorRight(self:*Self)  !void{
    if(self.buffer.items.len == 0 )return;
    if(self.cursor_pos < self.buffer.items.len){
    self.cursor_pos +=1;
    const current_line_start = std.mem.lastIndexOfScalar(u8, self.buffer.items[0..self.cursor_pos], '\n');
    if(self.cursor_pos == self.buffer.items.len){ 
        self.at_line_end = true;
    }else{
        self.at_line_end = (self.buffer.items[self.cursor_pos] == '\n'); 
    }  
    self.preferred_col = self.cursor_pos - if (current_line_start) |p| p + 1 else 0;
    }
}

pub fn cursorUp(self:*Self) !void {
    if(self.buffer.items.len == 0) return;
    if(self.cursor_pos > 0) { 
    const pos = std.mem.lastIndexOfScalar(u8,self.buffer.items[0..self.cursor_pos],'\n');
        if(pos == null) return;
        if(pos == 0) return;
        const prev_start = std.mem.lastIndexOfScalar(u8,self.buffer.items[0..pos.?], '\n');
        const line_start = if(prev_start) |p| p + 1 else 0 ;
        self.cursor_pos = line_start + @min(self.preferred_col,pos.? - line_start);

    }

}

pub fn cursorDown(self:*Self) !void {
    if(self.buffer.items.len == 0 )return;
    if(self.cursor_pos >= self.buffer.items.len) return;

        const pos = std.mem.indexOfScalar(u8, self.buffer.items[self.cursor_pos..], '\n');
        if(pos == null) return;
        const absolute_pos= self.cursor_pos + pos.?;
        const next_line_start = absolute_pos + 1;
        const next_start = std.mem.indexOfScalar(u8,self.buffer.items[next_line_start..],'\n');
        const line_end = if (next_start) |p| next_line_start + p + 1 else self.buffer.items.len;
        std.debug.print("cursorDown: next_line_start:{} line_end:{} preferred_col:{}\n", .{next_line_start, line_end, self.preferred_col});
        if(self.at_line_end){
            self.cursor_pos = line_end - 1;
            return;
        }
        if(next_line_start >= line_end - 1) {
            self.cursor_pos = line_end - 1;
            return;
        }       

        self.cursor_pos = @min(next_line_start + self.preferred_col, line_end - 1);

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

