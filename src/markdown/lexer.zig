const std = @import("std");
const token = @import("token.zig");
const Token = token.Token;



pub const Lexer = struct {
    source: []const u8,

    current: usize = 0,
    line: usize = 1,
    column: usize = 1,
    
    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .current = 0,
            .line = 1,
            .column = 1,
        };
    }



pub fn peek(self:*Lexer) ?u8 {
    if (self.current >= self.source.len) {
        return null;
    }
    return self.source[self.current];
}

pub fn peekNext(self:*Lexer)?u8 {
    if (self.current + 1 >= self.source.len) {
        return null;
    }
    return self.source[self.current + 1 ];

}

pub fn advance(self:*Lexer) ?u8 {
    if(self.current >= self.source.len) {
        return null;
    }
    const c = self.source[self.current];
    self.current += 1;
    if (c == '\n') {
        self.line += 1;
        self.column = 1;
    } else {
        self.column += 1;
    }
    return c;
}

pub fn match(self:*Lexer, expected:u8) bool {
    if (self.current >= self.source.len) {
        return false;
    }
    if (self.source[self.current] != expected) {
        return false;
    }
    self.current += 1;
    self.column += 1;
    return true;

}

pub fn lexHeading(self:*Lexer) Token {
    var level: u8 = 1;
    const start = self.current;
    while(self.peek()) |c|  {
        if(c != '#')
            break;
        _ = self.advance();
        level += 1;
    }
    return self.makeToken(token.TokenType.heading_marker, start,level);
}

pub fn lextOrderedList(self:*Lexer) Token {
    const start = self.current;
    var number: u8 = 0; 
    while(self.peek()) |c|  {
        if(c < '0' or c > '9')
            break;

        number = number * 10 + (c - '0');
        _ = self.advance();
    }
    if (self.match('.')) {
        return self.makeToken(token.TokenType.number, start, null, number);
    } else {
        return self.makeToken(token.TokenType.text, start);
    }
}

pub fn lexText(self:*Lexer) Token {
    const start = self.current;
    while(self.peek()) |c|  {
        if(c == '\n' or c == '#' or c == '*' or c == '.' or c == '>' or c == '[' or c == ']' or c == '(' or c == ')' or c == '!') {
            break;
        }
        _ = self.advance();
    }
    return self.makeToken(token.TokenType.text, start);
}


pub fn nextToken(self:*Lexer)  Token {
 
    self.skipWhitespace();
    while(!self.isAtEnd()) {
    const start = self.current;
    const c = self.advance().?;
    switch (c) {
        '\n' => {
            return self.makeToken(token.TokenType.newline, start);
        },
        '#' => {
            return self.lexHeading();
        },
        '*' => {
            return self.makeToken(token.TokenType.bold_marker, start);
        },
        '.' => {
            return self.lextOrderedList();
        },
        '>' => return self.makeToken(token.TokenType.quote_marker, start),
        '[' => return self.makeToken(token.TokenType.left_bracket, start),
        ']' => return self.makeToken(token.TokenType.right_bracket, start),
        '(' => return self.makeToken(token.TokenType.left_paren, start),
        ')' => return self.makeToken(token.TokenType.right_paren, start),
        '!' =>  return self.makeToken(token.TokenType.exclamation, start),
        else =>  return self.lexText()
        }
        return self.makeToken(.text,start);
    }
}

pub fn makeToken(self:*Lexer, kind:token.TokenType, start:usize,level:?u8,number:?u8) Token {
    return Token{
        .kind = kind,
        .start = start,
        .end = self.current,
        .line = self.line,
        .column = self.column,
        .level = if (kind == .heading_marker) level else null,
        .number = if (kind == .number) number else null,
    };
}

pub fn skipWhitespace(self:*Lexer) void {
    while (true) {
        const c = peek(self);
        if (c == null) {
            return;
        }
        switch (c.?) {
            ' ', '\t', '\r' => {
                _ = advance(self);
            },
            '\n' => {
                _ = advance(self);
            },
            else => return,
        }
    }
}

pub fn isAtEnd(self:*Lexer) bool {
    return self.current >= self.source.len;
}

};
