const std = @import("std");

fn AVL(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: T,
            parent: ?*Node,
            left: ?*Node,
            right: ?*Node,

            fn init(self: *Node, data: T) void {
                self.data = data;
                self.parent = null;
                self.left = null;
                self.right = null;
            }
        };
        root: ?*Node,
        count: usize,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) Self {
            return AVL(T){
                .root = null,
                .count = 0,
                .allocator = allocator,
            };
        }

        fn search(self: Self, s: T) ?*const Node {
            var curr_node = self.root orelse {
                std.debug.print("\nThe tree is empty.......", .{});
                return null;
            };

            while (curr_node.data != s) {
                if (s < curr_node.data) {
                    if (curr_node.left) |left| {
                        curr_node = left;
                    } else {
                        std.debug.print("\nNo such Element....", .{});
                        break;
                    }
                } else if (s > curr_node.data) {
                    if (curr_node.right) |right| {
                        curr_node = right;
                    } else {
                        std.debug.print("\nNo such Element....", .{});
                        break;
                    }
                }
            } else {
                std.debug.print("\nElement Found!!\n", .{});
                return curr_node;
            }

            return null;
        }

        fn insert(self: *Self, data: usize) !void {
            if (self.root == null) {
                self.root = try self.newNode(data);
            } else {
                var curr_node = self.root;
                while (curr_node) |*node| {
                    if (data < node.*.data) {
                        if (node.*.left != null) {
                            curr_node = node.*.left.?;
                            continue;
                        } else {
                            std.debug.print("\nInserting {} at left of {}", .{ data, node.*.data });
                            node.*.left = try self.newNode(data);
                            node.*.left.?.parent = node.*;
                            break;
                        }
                    } else if (data > node.*.data) {
                        if (node.*.right != null) {
                            curr_node = node.*.right.?;
                            continue;
                        } else {
                            std.debug.print("\nInserting {} at right of {}", .{ data, node.*.data });
                            node.*.right = try self.newNode(data);
                            node.*.right.?.parent = node.*;
                            break;
                        }
                    } else {
                        std.debug.print("\nCannot insert same element twice: {}", .{data});
                        break;
                    }
                }
            }

            std.debug.print("\nInserted: {}\n", .{data});
        }

        fn newNode(self: *Self, data: T) !*Node {
            const new_node = try self.*.allocator.create(Node);
            new_node.*.init(data);
            self.*.count += 1;

            return new_node;
        }

        fn deinit(self: Self) void {
            var curr_node = self.root;
            while (curr_node) |*node| {
                if (node.*.left != null) {
                    curr_node = node.*.left.?;
                    continue;
                } else if (node.*.right != null) {
                    curr_node = node.*.right.?;
                    continue;
                } else {
                    const is_root = curr_node == self.root;
                    if (is_root) {
                        self.allocator.destroy(curr_node.?);
                        break;
                    } else {
                        const temp = node.*;
                        const is_left_child = if (node.*.data < node.*.parent.?.data) true else false;
                        curr_node = node.*.parent.?;
                        if (is_left_child) {
                            node.*.left = null;
                        } else {
                            node.*.right = null;
                        }
                        self.allocator.destroy(temp);
                    }
                }
            }
        }
    };
}

pub fn main() !void {}

test "empty tree with deinit" {
    var allocator = std.testing.allocator;

    var tree = AVL(usize).init(allocator);

    defer tree.deinit();
}

test "one element tree" {
    var allocator = std.testing.allocator;

    var tree = AVL(usize).init(allocator);
    try tree.insert(10);

    defer tree.deinit();
}

test "multiple element tree" {
    var allocator = std.testing.allocator;

    var tree = AVL(usize).init(allocator);
    try tree.insert(10);
    try tree.insert(20);
    try tree.insert(40);
    try tree.insert(15);
    try tree.insert(16);
    try tree.insert(12);
    try tree.insert(5);
    try tree.insert(2);

    std.debug.print("\nno. of nodes: {}\n", .{tree.count});

    defer tree.deinit();
}

test "search" {
    var allocator = std.testing.allocator;

    var tree = AVL(usize).init(allocator);
    try tree.insert(10);
    try tree.insert(20);
    try tree.insert(40);
    try tree.insert(15);
    try tree.insert(16);
    try tree.insert(12);
    try tree.insert(5);
    try tree.insert(2);

    _ = tree.search(2);

    std.debug.print("\nno. of nodes: {}\n", .{tree.count});

    defer tree.deinit();
}
