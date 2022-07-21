const std = @import("std");

const Option = enum {
    Size,
    Character,
    Help,
    None,
};

const PyramidInfo = struct {
    size: usize,
    character: u8,
};

const Allocator = std.mem.Allocator;

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    if (parseOptions(allocator)) |info| {
        pyramid(info.size, info.character, allocator);
    }
}

fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    nosuspend stdout.print(fmt, args) catch return;
}

fn next(iter: *std.process.ArgIterator, allocator: Allocator) ?[:0]u8 {
    if (iter.next(allocator)) |arg_union| {
        if (arg_union) |arg| {
            return arg;
        } else |err| {
            std.log.err("Error while requesting command line argument: {}", .{err});
        }
    }
    return null;
}

fn parseOptions(allocator: Allocator) ?PyramidInfo {
    var info = PyramidInfo{ .size = 10, .character = '*' };

    var arg_iter = std.process.args();
    defer arg_iter.deinit();

    // Ignore file name and path
    if (next(&arg_iter, allocator)) |arg| {
        allocator.free(arg);
    }

    while (next(&arg_iter, allocator)) |arg| {
        defer allocator.free(arg);
        var option = Option.None;
        if (std.mem.eql(u8, arg, "--size")) {
            option = Option.Size;
        } else if (std.mem.eql(u8, arg, "-s")) {
            option = Option.Size;
        } else if (std.mem.eql(u8, arg, "--character")) {
            option = Option.Character;
        } else if (std.mem.eql(u8, arg, "-c")) {
            option = Option.Character;
        } else if (std.mem.eql(u8, arg, "--help")) {
            option = Option.Help;
        } else if (std.mem.eql(u8, arg, "-h")) {
            option = Option.Help;
        }

        switch (option) {
            Option.Size => {
                if (next(&arg_iter, allocator)) |size_str| {
                    defer allocator.free(size_str);
                    const MAX_SIZE = 4096;
                    const PARSE_ERROR_MESSAGE = comptime std.fmt.comptimePrint("Invalid size. Please use a number between 1 and {}.\n", .{MAX_SIZE});
                    if (std.fmt.parseInt(usize, size_str, 10)) |size| {
                        if (size > 0 and size <= MAX_SIZE) {
                            info.size = size;
                        } else {
                            print(PARSE_ERROR_MESSAGE, .{});
                            return null;
                        }
                    } else |err| {
                        switch (err) {
                            error.Overflow, error.InvalidCharacter => {
                                print(PARSE_ERROR_MESSAGE, .{});
                                return null;
                            },
                            _ => {
                                std.log.err("Failed to parse size: {}", .{err});
                                return null;
                            }
                        }
                        print(PARSE_ERROR_MESSAGE, .{});
                        return null;
                    }
                } else {
                    print("No size found. Need a size after '-s'.\n", .{});
                    return null;
                }
            },
            Option.Character => {
                if (next(&arg_iter, allocator)) |character| {
                    defer allocator.free(character);
                    if (character.len == 1) {
                        info.character = character[0];
                    } else {
                        print("Please only use one character.", .{});
                        return null;
                    }
                } else {
                    print("No character found. Need a character after '-c'.\n", .{});
                    return null;
                }
            },
            Option.Help => {
                const HELP_MESSAGE =
                    \\Usage: soap [OPTION..]
                    \\
                    \\  -s, --size HEIGHT       Set the vertical size of the pyramid
                    \\  -c, --character CHAR    Set the character to be used in the pyramid
                    \\  -h, --help              Display this help and exit
                    \\
                ;

                print(HELP_MESSAGE, .{});
                return null;
            },
            Option.None => {
                print("Unknown option: {s}\n", .{arg});
                return null;
            },
        }
    }

    return info;
}

fn pyramid(height: usize, character: u8, allocator: std.mem.Allocator) void {
    const buffer = allocator.alloc(u8, (3 * height * height + height) / 2 + 1) catch {
        std.log.err("Failed to allocate pryamid char buffer.", .{});
        return;
    };
    defer allocator.free(buffer);
    var row: usize = 0;
    var i: usize = 0;
    while (row < height) {
        var column: usize = 0;
        while (column < height - row - 1) {
            buffer[i] = ' ';
            i += 1;
            column += 1;
        }
        column = 0;
        while (column < row * 2 + 1) {
            buffer[i] = character;
            i += 1;
            column += 1;
        }
        buffer[i] = '\n';
        i += 1;
        row += 1;
    }
    buffer[i] = 0;
    print("{s}", .{buffer});
}
