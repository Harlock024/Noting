const std = @import("std");



pub fn readFile(io: std.Io ,buf: []u8,path: []const u8)![]u8{
    return try std.Io.Dir.readFile(std.Io.Dir.cwd(), io,path,buf);
}

pub fn writeFile(path:[]const u8,io:std.Io,content:[]const u8)!void {
    try std.Io.Dir.writeFile(std.Io.Dir.cwd(),io,.{
        .sub_path = path,
        .data = content,
    });
}
