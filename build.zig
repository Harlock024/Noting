const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .gnu,
    });
    const optimize = b.standardOptimizeOption(.{});

    const core = b.addLibrary(.{
        .name = "core",
        .root_module = b.addModule("core", .{
            .root_source_file = b.path("src/core/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const platform = b.addLibrary(.{
        .name = "platform",
        .root_module = b.addModule("platform", .{
            .root_source_file = b.path("src/platform/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    platform.root_module.addImport("core", core.root_module);
    platform.root_module.addIncludePath(.{ .cwd_relative = "/usr/include" });
    platform.root_module.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
    platform.root_module.linkSystemLibrary("SDL3", .{});
    platform.root_module.linkSystemLibrary("SDL3_ttf", .{});

    const exe = b.addExecutable(.{ .name = "noting_md", .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    exe.root_module.addImport("core", core.root_module);
    exe.root_module.addImport("platform", platform.root_module);
    exe.root_module.addLibraryPath(.{ .cwd_relative = "/usr/lib" });

    const install_assets = b.addInstallDirectory(.{
        .source_dir = b.path("public"),
          .install_dir = .bin,
          .install_subdir = "public",
    });
    b.getInstallStep().dependOn(&install_assets.step);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run Noting App");
    run_step.dependOn(&run_cmd.step);
}
