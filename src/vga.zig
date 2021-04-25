const std = @import("std");

const VgaBuffer = struct {
    buffer: [*]volatile VgaChar = @intToPtr([*]volatile VgaChar, 0xb8000),
    color: FullColor = .{ .fg = .White, .bg = .Black },
    row: usize = 0,
    column: usize = 0,

    const Self = @This();

    /// Clear the screen to black. Preserves the current color.
    pub fn initialize(self: *Self) void {
        self.column = 0;
        self.row = 0;
        var y: usize = 0;
        while (y < VGA_HEIGHT) : (y += 1) {
            self.clear_row(y);
        }
    }

    /// Write a string to the VGA buffer using the current color.
    pub fn write(self: *Self, data: []const u8) void {
        for (data) |c| {
            self.putChar(.{ .char = c, .color = self.color });
        }
    }

    /// Set the color used when writing.
    pub fn set_color(self: *Self, fg: HalfColor, bg: HalfColor) void {
        self.color = .{ .fg = fg, .bg = bg };
    }

    /// Write `char` at the specified x and y coordinates in the VGA buffer.
    fn putCharAt(self: *Self, char: VgaChar, x: usize, y: usize) void {
        self.buffer[y * VGA_WIDTH + x] = char;
    }

    /// Write `char` at the current row and column, and move to the next column.
    /// If the end of the current row is reached, wrap to the next row.
    fn putChar(self: *Self, char: VgaChar) void {
        // TODO: handle newline
        switch (char.char) {
            '\n' => self.new_line(),
            else => {
                switch (char.char) {
                    0x20...0x7e => self.putCharAt(
                        char,
                        self.column,
                        self.row,
                    ),
                    // Not printable on VGA (outside of ASCII range, or its a control character).
                    // Print a ■ instead.
                    else => self.putCharAt(
                        .{ .char = 0xfe, .color = char.color },
                        self.column,
                        self.row,
                    ),
                }
                self.column += 1;
                if (self.column == VGA_WIDTH) {
                    self.new_line();
                }
            },
        }
    }

    fn new_line(self: *Self) void {
        self.column = 0;
        switch (self.row) {
            VGA_HEIGHT - 1 => self.shift_upwards(),
            else => self.row += 1,
        }
    }

    /// Move the entire buffer up one row,
    fn shift_upwards(self: *Self) void {
        // TODO: Implement some backbuffering to be able to scroll while pagelock is on?
        //       This is blocked by paging/heap implementation.
        var y: usize = 1;
        while (y < VGA_HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < VGA_WIDTH) : (x += 1) {
                const char = self.buffer[y * VGA_WIDTH + x];
                self.putCharAt(char, x, y - 1);
            }
        }
        // Clear the bottom line
        self.clear_row(y - 1);
    }

    fn clear_row(self: *Self, y: usize) void {
        const clear_color = FullColor{ .fg = .Black, .bg = .Black };
        var x: usize = 0;
        while (x < VGA_WIDTH) : (x += 1) {
            self.putCharAt(.{ .char = ' ', .color = clear_color }, x, y);
        }
    }

    const Writer = std.io.Writer(
        *Self,
        WriterError,
        writer_write,
    );

    const WriterError = error{};

    fn writer_write(self: *Self, data: []const u8) WriterError!usize {
        self.write(data);
        // FIXME: this is naive
        return data.len;
    }

    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }
};

/// Global singleton instance
pub var buffer: VgaBuffer = .{};

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
