const std = @import("std");
const mocha = @import("mocha");
const allocator = std.heap.c_allocator;


// const mocha_error = enum(c_int) {
//     MissingField, DuplicateField, RootReference, OutOfMemory, InvalidCharacter, Overflow, Core.Error = ?
// };

const mocha_value_type_t = enum(c_int) {
    MOCHA_VALUE_TYPE_NIL,
    MOCHA_VALUE_TYPE_STRING,
    //MOCHA_VALUE_TYPE_REFERENCE,
    MOCHA_VALUE_TYPE_BOOLEAN,
    MOCHA_VALUE_TYPE_OBJECT,
    MOCHA_VALUE_TYPE_ARRAY,
    MOCHA_VALUE_TYPE_FLOAT64,
    MOCHA_VALUE_TYPE_INTEGER64
};

const mocha_value_t = extern union {
    string: [*:0]const u8,
    //ref: Reference,
    boolean: bool,
    object: mocha_object_t,
    array: mocha_array_t,
    float64: f64,
    integer64: i64,
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

export fn mocha_parse(object: *mocha_object_t, src: [*:0]const u8) void {
    const obj = mocha.Parser.parse(allocator, std.mem.span(src)) catch return;
    object.* = .{ .fields = obj.fields.ptr, .fields_len = obj.fields.len};
    return;
}

export fn mocha_deinit(object: *mocha_object_t) void {
    const obj = mocha.Object{ .fields = fieldsCast(object.*.fields, object.*.fields_len) };
    obj.deinit(allocator);
}

export fn mocha_field(object: *mocha_object_t, index: usize) mocha_field_t {
    const fields = fieldsCast(object.*.fields, object.*.fields_len);
    var value: mocha_value_t = undefined;
    var @"type": mocha_value_type_t = undefined;
    switch(fields[index].value) {
        .string => |s| {
            value = .{ .string = s.ptr };
            @"type" = .MOCHA_VALUE_TYPE_STRING;
        },
        .boolean => |b| {
            value = .{ .boolean = b };
            @"type" = .MOCHA_VALUE_TYPE_BOOLEAN;
        },
        .object => |o| {
            value = .{ .object = .{ .fields = o.fields.ptr, .fields_len = o.fields.len} };
            @"type" = .MOCHA_VALUE_TYPE_OBJECT;
        },
        .array => |a| {
            value = .{ .array = .{ .items = a.items.ptr, .items_len = a.items.len} };
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

inline fn fieldsCast(fields: *anyopaque, fields_len: usize) []mocha.Field {
    return @as([*]mocha.Field, @ptrCast(@alignCast(fields)))[0..fields_len];
}
