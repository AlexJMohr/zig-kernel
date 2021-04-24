var buffer = @intToPtr([*]volatile VgaChar, 0xb8000);
var color = FullColor{ .fg = .White, .bg = .Black };
var row: usize = 0;
var column: usize = 0;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

/// Half of a VGA color (either foreground or background).
const HalfColor = packed enum(u4) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGrey = 7,
    DarkGrey = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

/// Full VGA color
const FullColor = packed struct {
    fg: HalfColor,
    bg: HalfColor,
};

const VgaChar = packed struct {
    char: u8,
    color: FullColor,
};

/// Clear the screen to black. Preserves the current color.
pub fn clear() void {
    column = 0;
    row = 0;
    var y: usize = 0;
    while (y < VGA_HEIGHT) : (y += 1) {
        clear_row(y);
    }
}

/// Write a string to the VGA buffer using the current color.
pub fn write(data: []const u8) void {
    for (data) |c| {
        putChar(.{ .char = c, .color = color });
    }
}

/// Set the color used when writing.
pub fn set_color(fg: HalfColor, bg: HalfColor) void {
    color = .{ .fg = fg, .bg = bg };
}

/// Write `char` at the specified x and y coordinates in the VGA buffer.
fn putCharAt(char: VgaChar, x: usize, y: usize) void {
    buffer[y * VGA_WIDTH + x] = char;
}

/// Write `char` at the current row and column, and move to the next column.
/// If the end of the current row is reached, wrap to the next row.
fn putChar(char: VgaChar) void {
    // TODO: handle newline
    switch (char.char) {
        '\n' => new_line(),
        else => {
            switch (char.char) {
                0x20...0x7e => putCharAt(char, column, row),
                // Not printable on VGA (outside of ASCII range, or its a control character).
                // Print a ■ instead.
                else => putCharAt(.{ .char = 0xfe, .color = char.color }, column, row),
            }
            column += 1;
            if (column == VGA_WIDTH) {
                new_line();
            }
        },
    }
}

fn new_line() void {
    column = 0;
    switch (row) {
        VGA_HEIGHT - 1 => shift_upwards(),
        else => row += 1,
    }
}

/// Move the entire buffer up one row,
fn shift_upwards() void {
    // TODO: Implement some backbuffering to be able to scroll while pagelock is on?
    //       This is blocked by paging/heap implementation.
    var y: usize = 1;
    while (y < VGA_HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < VGA_WIDTH) : (x += 1) {
            const char = buffer[y * VGA_WIDTH + x];
            putCharAt(char, x, y - 1);
        }
    }
    // Clear the bottom line
    clear_row(y - 1);
}

fn clear_row(y: usize) void {
    const clear_color = FullColor{ .fg = .Black, .bg = .Black };
    var x: usize = 0;
    while (x < VGA_WIDTH) : (x += 1) {
        putCharAt(.{ .char = ' ', .color = clear_color }, x, y);
    }
}
