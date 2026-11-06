const std = @import("std");


pub const Node = union(enum){
    Document: DocumentNode,
    Heading: HeadingNode,
    Paragraph: ParagraphNode,
    Text: TextNode,
    Bold: BoldNode,
    Italic: ItalicNode,
    Code: CodeNode,
    Quote: QuoteNode,
    List: ListNode,
    ListItem: ListItemNode,
    Link: LinkNode,
    Image: ImageNode,
};

const DocumentNode = struct {
    children: std.ArrayList(Node),
};
const HeadingNode = struct {
    level: u8,
    children: std.ArrayList(Node),
};
const ParagraphNode = struct {
    children: std.ArrayList(Node),
};

const TextNode = struct {
    text: []const u8,
};
const BoldNode = struct {
    children: std.ArrayList(Node),
};
const ItalicNode = struct {
    children: std.ArrayList(Node),
};
const CodeNode = struct {
    text: []const u8,
};
const QuoteNode = struct {
    children: std.ArrayList(Node),
};
const ListNode = struct {
    ordered: bool,
    children: std.ArrayList(Node),
};
const ListItemNode = struct {
    children: std.ArrayList(Node),
};
const LinkNode = struct {
    href: []const u8,
    children: std.ArrayList(Node),
};
const ImageNode = struct {
    src: []const u8,
    alt: []const u8,
};

