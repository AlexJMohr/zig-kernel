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

/// ELF entry point, called by multiboot bootloader. Just sets up the stack and calls kmain.
export fn _start() callconv(.Naked) noreturn {
    // Initialize the stack
    const stack_top = @ptrToInt(&stack_bytes) + stack_bytes.len;
    asm volatile (""
        :
        : [stack_top] "{esp}" (stack_top)
    );

    // Call kmain, make sure it never gets inlined.
    @call(.{ .modifier = .never_inline }, kmain, .{});

    // TODO: hlt loop
    while (true) {}
}

/// Kernel entry point, called from _start
fn kmain() void {
    vga.clear();
    vga.set_color(.LightGreen, .Black);
    vga.write("Hello Zig Kernel! :^)\n");
    vga.set_color(.LightGrey, .Black);
}

/// Panic handler
pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    vga.set_color(.LightRed, .Black);
    vga.write("KERNEL PANIC: ");

    // TODO: hlt loop
    while (true) {}
}
