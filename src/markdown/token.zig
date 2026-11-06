pub const TokenType = enum {
    text,
    newline,

    heading_marker,

    bold_marker,
    italic_marker,
    code_marker,

    quote_marker,

    ordered_list_marker,
    unordered_list_marker,

    task_list_marker,
    horizontal_rule,
    
    left_bracket,
    right_bracket,

    left_paren,
    right_paren,

    exclamation,
    eof,
};

pub const Token = struct {
    kind: TokenType,
    start: usize,
    end: usize,
    line: usize,
    column: usize,
    number: usize = 0, 
    level: u8 = 0, // level for headings and lists
};

pub fn slice(self:Token,source: []const u8) []const u8 {
    return source[self.start..self.end];
}

