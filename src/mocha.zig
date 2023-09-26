const std = @import("std");
const mocha = @import("mocha");
const allocator = std.heap.c_allocator;


// const mocha_error = enum(c_int) {
//     MissingField, DuplicateField, RootReference, OutOfMemory, InvalidCharacter, Overflow, Core.Error = ?
// };

const mocha_value_t = extern union {
    string: [*:0]const u8,
    //ref: Reference,
    boolean: bool,
    object: mocha_object_t,
    array: mocha_array_t,
    float: f64,
    integer: i64,
};

const mocha_array_t = extern struct {
    items: *anyopaque,
    items_len: usize,
};

const mocha_field_t = extern struct {
    name: [*:0]const u8,
    value: mocha_value_t,
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
    return .{ .name = fields[index].name, .value = .{ .boolean = true} };
}

inline fn fieldsCast(fields: *anyopaque, fields_len: usize) []mocha.Field {
    return @as([*]mocha.Field, @ptrCast(@alignCast(fields)))[0..fields_len];
}
