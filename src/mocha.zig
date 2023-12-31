const std = @import("std");
const mocha = @import("mocha");
const allocator = std.heap.c_allocator;

const mocha_error_t = enum(c_int) {
    MOCHA_ERROR_NONE,
    MOCHA_ERROR_MISSING_FIELD,
    MOCHA_ERROR_DUPLICATE_FIELD,
    MOCHA_ERROR_ROOT_REFERENCE,
    MOCHA_ERROR_OUT_OF_MEMORY,
    MOCHA_ERROR_INVALID_CHARACTER,
    MOCHA_ERROR_OVERFLOW,
    MOCHA_ERROR_END_OF_STREAM,
    MOCHA_ERROR_UNEXPECTED_TOKEN,
    MOCHA_ERROR_UNEXPECTED_CHARACTER
};

const mocha_value_type_t = enum(c_int) {
    MOCHA_VALUE_TYPE_NIL,
    MOCHA_VALUE_TYPE_STRING,
    MOCHA_VALUE_TYPE_REFERENCE,
    MOCHA_VALUE_TYPE_BOOLEAN,
    MOCHA_VALUE_TYPE_OBJECT,
    MOCHA_VALUE_TYPE_ARRAY,
    MOCHA_VALUE_TYPE_FLOAT64,
    MOCHA_VALUE_TYPE_INTEGER64
};

const mocha_value_t = extern union {
    string: [*:0]const u8,
    reference: mocha_reference_t,
    boolean: c_int,
    object: mocha_object_t,
    array: mocha_array_t,
    float64: f64,
    integer64: i64,
};

const mocha_reference_t = extern struct {
    name: [*]const u8,
    name_len: usize,
    child: ?*const anyopaque,
    index: usize,
};

const mocha_array_t = extern struct {
    items: *anyopaque,
    items_len: usize,
};

const mocha_field_t = extern struct {
    name: [*:0]const u8,
    value: mocha_value_t,
    @"type": mocha_value_type_t,
};

const mocha_object_t = extern struct {
    fields: *anyopaque,
    fields_len: usize,
};

export fn mocha_parse(object: *mocha_object_t, src: [*:0]const u8) mocha_error_t {
    const obj = mocha.Parser.parse(allocator, std.mem.span(src)) catch |err| return handleMochaError(err);
    object.* = .{ .fields = @ptrCast(obj.fields.ptr), .fields_len = obj.fields.len};
    return .MOCHA_ERROR_NONE;
}

export fn mocha_nparse(object: *mocha_object_t, src: [*]const u8, len: usize) mocha_error_t {
    const obj = mocha.Parser.parse(allocator, src[0..len]) catch |err| return handleMochaError(err);
    object.* = .{ .fields = @ptrCast(obj.fields.ptr), .fields_len = obj.fields.len};
    return .MOCHA_ERROR_NONE;
}

export fn mocha_deinit(object: *mocha_object_t) void {
    const obj = mocha.Object{ .fields = fieldsCast(object.*.fields, object.*.fields_len) };
    obj.deinit(allocator);
}

export fn mocha_field(object: *const mocha_object_t, index: usize) mocha_field_t {
    const fields = fieldsCast(object.*.fields, object.*.fields_len);
    var value: mocha_value_t = undefined;
    var @"type": mocha_value_type_t = undefined;
    switch(fields[index].value) {
        .string => |s| {
            value = .{ .string = s.ptr };
            @"type" = .MOCHA_VALUE_TYPE_STRING;
        },
        .ref => |r| {
            value  = .{ .reference = .{ .name = r.name.ptr, .name_len = r.name.len, .child = @ptrCast(r.child), .index = if (r.index != null) r.index.? else 0 } };
            @"type" = .MOCHA_VALUE_TYPE_REFERENCE;
        },
        .boolean => |b| {
            value = .{ .boolean = if (b) 1 else 0 };
            @"type" = .MOCHA_VALUE_TYPE_BOOLEAN;
        },
        .object => |o| {
            value = .{ .object = .{ .fields = @ptrCast(o.fields.ptr), .fields_len = o.fields.len} };
            @"type" = .MOCHA_VALUE_TYPE_OBJECT;
        },
        .array => |a| {
            value = .{ .array = .{ .items = @ptrCast(a.items.ptr), .items_len = a.items.len} };
            @"type" = .MOCHA_VALUE_TYPE_ARRAY;
        },
        .float => |f| {
            value = .{ .float64 = f };
            @"type" = .MOCHA_VALUE_TYPE_FLOAT64;
        },
        .int => |i| {
            value = .{ .integer64 = i };
            @"type" = .MOCHA_VALUE_TYPE_INTEGER64;
        },
        else => @"type" = .MOCHA_VALUE_TYPE_NIL
    }
    return .{ .name = fields[index].name.ptr, .value = value, .@"type" = @"type" };
}

export fn mocha_array(array: *const mocha_array_t, value: *mocha_value_t, index: usize) mocha_value_type_t {
    const items = itemsCast(array.*.items, array.*.items_len);
    switch(items[index]) {
        .string => |s| {
            value.* = .{ .string = s.ptr };
            return .MOCHA_VALUE_TYPE_STRING;
        },
        .ref => |r| {
            value.* = .{ .reference = .{ .name = r.name.ptr, .name_len = r.name.len, .child = @ptrCast(r.child), .index = if (r.index != null) r.index.? else 0 } };
            return .MOCHA_VALUE_TYPE_REFERENCE;
        },
        .boolean => |b| {
            value.* = .{ .boolean = if (b) 1 else 0 };
            return .MOCHA_VALUE_TYPE_BOOLEAN;
        },
        .object => |o| {
            value.* = .{ .object = .{ .fields = @ptrCast(o.fields.ptr), .fields_len = o.fields.len} };
            return .MOCHA_VALUE_TYPE_OBJECT;
        },
        .array => |a| {
            value.* = .{ .array = .{ .items = @ptrCast(a.items.ptr), .items_len = a.items.len} };
            return .MOCHA_VALUE_TYPE_ARRAY;
        },
        .float => |f| {
            value.* = .{ .float64 = f };
            return .MOCHA_VALUE_TYPE_FLOAT64;
        },
        .int => |i| {
            value.* = .{ .integer64 = i };
            return .MOCHA_VALUE_TYPE_INTEGER64;
        },
        else => return .MOCHA_VALUE_TYPE_NIL
    }
}

export fn mocha_reference_next(reference: *mocha_reference_t) c_int {
    if (reference.*.child) |r| {
        const ref = @as(*const mocha.Reference, @ptrCast(@alignCast(r)));
        reference.* = .{
            .name = ref.name.ptr,
            .name_len = ref.name.len,
            .child = @ptrCast(ref.child),
            .index = if (ref.index != null) ref.index.? else 0,
        };
        return 0;
    }
    return 1;
}

inline fn fieldsCast(fields: *anyopaque, fields_len: usize) []mocha.Field {
    return @as([*]mocha.Field, @ptrCast(@alignCast(fields)))[0..fields_len];
}

inline fn itemsCast(items: *anyopaque, items_len: usize) []mocha.Value {
    return @as([*]mocha.Value, @ptrCast(@alignCast(items)))[0..items_len];
}

inline fn handleMochaError(err: mocha.Error) mocha_error_t {
    return switch(err) {
        error.MissingField        => .MOCHA_ERROR_MISSING_FIELD,
        error.DuplicateField      => .MOCHA_ERROR_DUPLICATE_FIELD,
        error.RootReference       => .MOCHA_ERROR_ROOT_REFERENCE,
        error.OutOfMemory         => .MOCHA_ERROR_OUT_OF_MEMORY,
        error.InvalidCharacter    => .MOCHA_ERROR_INVALID_CHARACTER,
        error.Overflow            => .MOCHA_ERROR_OVERFLOW,
        error.EndOfStream         => .MOCHA_ERROR_END_OF_STREAM,
        error.UnexpectedToken     => .MOCHA_ERROR_UNEXPECTED_TOKEN,
        error.UnexpectedCharacter => .MOCHA_ERROR_UNEXPECTED_CHARACTER
    };
}

test "library tests" {
    const text =
        \\defaults: {
        \\user_id: 0
        \\start_id: user_id
        \\}

        \\hanna: {
        \\name: 'hanna rose'
        \\id: @:defaults:user_id
        \\inventory: ['banana' 12.32]
        \\}
    ;
    var object: mocha_object_t = undefined;
    const mocha_err1 = mocha_nparse(&object, text, text.len);
    try @import("std").testing.expectEqual(mocha_err1, .MOCHA_ERROR_NONE);
    mocha_deinit(&object);
    const mocha_err = mocha_parse(&object, text);
    try @import("std").testing.expectEqual(mocha_err, .MOCHA_ERROR_NONE);
    defer mocha_deinit(&object);
    {
        const field = mocha_field(&object, 0);
        try @import("std").testing.expect(std.mem.eql(u8, field.name[0..8], "defaults"));
        try @import("std").testing.expectEqual(field.@"type", .MOCHA_VALUE_TYPE_OBJECT);

        const field1 = mocha_field(&field.value.object, 0);
        try @import("std").testing.expect(std.mem.eql(u8, field1.name[0..7], "user_id"));
        try @import("std").testing.expectEqual(field1.@"type", .MOCHA_VALUE_TYPE_INTEGER64);
        try @import("std").testing.expectEqual(field1.value.integer64, 0);

        const field2 = mocha_field(&field.value.object, 1);
        try @import("std").testing.expect(std.mem.eql(u8, field2.name[0..8], "start_id"));
        try @import("std").testing.expectEqual(field2.@"type", .MOCHA_VALUE_TYPE_REFERENCE);
        try @import("std").testing.expect(std.mem.eql(u8, field2.value.reference.name[0..7], "user_id"));
    }

    {
        const field = mocha_field(&object, 1);
        try @import("std").testing.expect(std.mem.eql(u8, field.name[0..5], "hanna"));
        try @import("std").testing.expectEqual(field.@"type", .MOCHA_VALUE_TYPE_OBJECT);

        const field1 = mocha_field(&field.value.object, 0);
        try @import("std").testing.expect(std.mem.eql(u8, field1.name[0..4], "name"));
        try @import("std").testing.expectEqual(field1.@"type", .MOCHA_VALUE_TYPE_STRING);
        try @import("std").testing.expect(std.mem.eql(u8, field1.value.string[0..10], "hanna rose"));

        const field2 = mocha_field(&field.value.object, 1);
        try @import("std").testing.expect(std.mem.eql(u8, field2.name[0..2], "id"));
        try @import("std").testing.expectEqual(field2.@"type", .MOCHA_VALUE_TYPE_REFERENCE);
        try @import("std").testing.expect(std.mem.eql(u8, field2.value.reference.name[0..1], "@"));

        var ref: mocha_reference_t = field2.value.reference;
        _ = mocha_reference_next(&ref);
        try @import("std").testing.expect(std.mem.eql(u8, ref.name[0..8], "defaults"));
        
        _ = mocha_reference_next(&ref);
        try @import("std").testing.expect(std.mem.eql(u8, ref.name[0..7], "user_id"));
        
        try @import("std").testing.expect(ref.child == null);

        const field3 = mocha_field(&field.value.object, 2);
        try @import("std").testing.expect(std.mem.eql(u8, field3.name[0..9], "inventory"));
        try @import("std").testing.expectEqual(field3.@"type", .MOCHA_VALUE_TYPE_ARRAY);

        var value: mocha_value_t = undefined;
        const value_type = mocha_array(&field3.value.array, &value, 0);
        try @import("std").testing.expectEqual(value_type, .MOCHA_VALUE_TYPE_STRING);
        try @import("std").testing.expect(std.mem.eql(u8, value.string[0..6], "banana"));
        
        const value_type1 = mocha_array(&field3.value.array, &value, 1);
        try @import("std").testing.expectEqual(value_type1, .MOCHA_VALUE_TYPE_FLOAT64);
        try @import("std").testing.expectEqual(value.float64, 12.32);
    }
}
