const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mocha = b.dependency("mocha", .{});

    const staticLib = b.addStaticLibrary(.{
        .name = "mocha",
        .root_source_file = .{ .path = "src/mocha.zig" },
        .optimize = optimize,
        .target = target,
    });
    staticLib.addModule("mocha", mocha.module("mocha"));
    staticLib.linkLibC();
    b.installArtifact(staticLib);

    const sharedLib = b.addSharedLibrary(.{
        .name = "mocha",
        .root_source_file = .{ .path = "src/mocha.zig" },
        .optimize = optimize,
        .target = target,
    });
    sharedLib.addModule("mocha", mocha.module("mocha"));
    sharedLib.linkLibC();
    b.installArtifact(sharedLib);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mocha.zig" },
        .optimize = optimize,
    });
    main_tests.linkLibC();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
