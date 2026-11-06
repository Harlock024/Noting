const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const Theme = struct {
    background: Color,
    foreground: Color,

    heading: Color,
    quote: Color,
    code: Color,

    selection: Color,
};


