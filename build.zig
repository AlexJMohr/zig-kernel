const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    // const target = b.standardTargetOptions(.{});
    const target = std.zig.CrossTarget{
        // cpu_arch: std.Target.
        .cpu_arch = .i386,
        .os_tag = .freestanding,
    };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    // const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("kernel", "src/main.zig");
    exe.setTarget(target);
    // FIXME: std.c.memcpy seems to segfault without building in release mode.
    //        Try it again after implementing the IDT to catch exceptions.
    exe.setBuildMode(.ReleaseSafe);
    exe.setLinkerScriptPath("linker.ld");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
