const std = @import("std");
const vga = @import("vga.zig");

const Multiboot = packed struct {
    magic: c_long,
    flags: c_long,
    checksum: c_long,
};

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1badb002;
const FLAGS = ALIGN | MEMINFO;

export var multiboot align(4) linksection(".multiboot") = Multiboot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

/// ELF entry point, called by multiboot bootloader.
export fn _start() callconv(.Naked) noreturn {
    // Call kmain with our stack, make sure it never gets inlined.
    @call(.{ .modifier = .never_inline, .stack = stack_bytes_slice }, kmain, .{});

    // TODO: hlt loop
    while (true) {}
}

/// Kernel entry point, called from _start
fn kmain() void {
    var buffer = &vga.buffer;
    buffer.initialize();
    buffer.set_color(.LightGreen, .Black);
    buffer.write("Hello Zig Kernel! :^)\n");
    buffer.set_color(.LightGrey, .Black);

    var writer = buffer.writer();
    _ = writer.write("test with writer\n") catch unreachable;
    _ = writer.print("This is a number: {}. Wow!\n", .{42}) catch unreachable;
}

/// Panic handler
pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    var buffer = &vga.buffer;
    buffer.set_color(.LightRed, .Black);
    buffer.write("KERNEL PANIC: ");
    buffer.write(message);
    if (stack_trace) |trace| {
        buffer.write("\n stack trace: TODO\n");
    }

    // TODO: hlt loop
    while (true) {}
}
