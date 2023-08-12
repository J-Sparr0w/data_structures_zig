const std = @import("std");

const Direction = enum {
    Left,
    Right,
};

fn AVL(comptime T: type) type {
    return struct {
        const Self = @This();
        const Balance = enum {
            LeftHeavy,
            RightHeavy,
            Balanced,
        };
        const Node = struct {
            data: T,
            parent: ?*Node,
            left: ?*Node,
            right: ?*Node,
            balance: Balance,

            fn init(self: *Node, data: T, parent: ?*Node) void {
                self.data = data;
                self.parent = parent orelse null;
                self.left = null;
                self.right = null;
                self.balance = Balance.Balanced;
            }

            fn print(self: Node) void {
                const data = self.data;
                const left = if (self.left != null) self.left.?.data else null;
                const right = if (self.right != null) self.right.?.data else null;
                const parent = if (self.parent != null) self.parent.?.data else null;
                std.debug.print("\nnode: {}\nleft-child: {any}\nright-child: {any}\nparent: {any}", .{ data, left, right, parent });
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
            var path = std.ArrayList(Direction).init(self.allocator);
            defer path.deinit();

            if (self.root == null) {
                self.root = try self.newNode(data, null);
            } else {
                var curr_node = self.root;
                while (curr_node) |*node| {
                    if (data < node.*.data) {
                        try path.append(Direction.Left);
                        if (node.*.left != null) {
                            curr_node = node.*.left.?;
                            continue;
                        } else {
                            std.debug.print("\nInserting {} at left of {}", .{ data, node.*.data });
                            node.*.left = try self.newNode(data, node.*);
                            break;
                        }
                    } else if (data > node.*.data) {
                        try path.append(Direction.Right);
                        if (node.*.right != null) {
                            curr_node = node.*.right.?;
                            continue;
                        } else {
                            std.debug.print("\nInserting {} at right of {}", .{ data, node.*.data });
                            node.*.right = try self.newNode(data, node.*);
                            break;
                        }
                    } else {
                        std.debug.print("\nCannot insert same element twice: {}", .{data});
                        break;
                    }
                } //while

                //  after inserting current node is still the parent of the inserted node
                //  it hasn't been updated to the leaf node

                // marking balance indicators
                while (curr_node != null) {
                    const height_diff = height(curr_node.?.right) - height(curr_node.?.left);
                    const abs_ht_diff = try std.math.absInt(height_diff);
                    const parent = curr_node.?.parent;
                    // std.debug.print("\nheight diff for {} : {}", .{ curr_node.?.data, height_diff });
                    if (height_diff < 0) {
                        if (abs_ht_diff == 1) {
                            //left-heavy

                            curr_node.?.balance = .LeftHeavy;
                        } else {
                            std.debug.print("\n{} is left-critical ", .{curr_node.?.data});
                            //left-critical
                            //does it require double rotation or single?
                            const left_child = curr_node.?.left.?;
                            if (data < left_child.data) {
                                //single rotation => child inserted at left-subtree of left-child
                                // std.debug.print("\n Performing rightRotate on {} ", .{curr_node.?.data});

                                self.rightRotate(curr_node.?);
                            } else {
                                //double rotation => child inserted at left-subtree of left-child
                                // std.debug.print("\n Performing double rotation on {} ", .{curr_node.?.data});

                                self.leftRotate(left_child);
                                self.rightRotate(curr_node.?);
                            }

                            // curr_node.?.balance = .Balanced;
                        }
                    } else if (height_diff > 0) {
                        if (abs_ht_diff == 1) {
                            //right-heavy
                            curr_node.?.balance = .RightHeavy;
                        } else {
                            std.debug.print("\n{} is right-critical ", .{curr_node.?.data});

                            const right_child = curr_node.?.right.?;
                            if (data > right_child.data) {
                                // std.debug.print("\n Performing leftRotate on {} ", .{curr_node.?.data});
                                //single rotation => child inserted at left-subtree of left-child
                                self.leftRotate(curr_node.?);
                            } else {
                                // std.debug.print("\n Performing double rotation on {} ", .{curr_node.?.data});
                                //double rotation => child inserted at left-subtree of left-child
                                self.rightRotate(right_child);
                                self.leftRotate(curr_node.?);
                            }
                            //right-critical
                            // curr_node.?.balance = .Balanced;
                        }
                    } else {
                        //balanced
                        curr_node.?.balance = .Balanced;
                    }
                    curr_node = parent;
                }
            } //else
            std.debug.print("\nInsertion completed\n", .{});
        }

        fn rightRotate(self: *Self, node: *Node) void {
            //node, parent, and left-child of node - theres going to be 4-5 pointers being manipulated
            var parent_node = node.*.parent orelse null;
            var left_node = node.*.left.?;
            node.*.parent = left_node;
            left_node.*.parent = parent_node;

            if (left_node.*.right) |right_node| {
                node.*.left = right_node;
                right_node.*.parent = node;
            } else {
                node.*.left = null;
            }
            left_node.*.right = node;
            if (parent_node) |*parent| {

                //determining which child of parent to update
                if (left_node.*.data < parent.*.data) {
                    parent.*.left = left_node;
                } else {
                    parent.*.right = left_node;
                }
            } else {
                self.*.root = left_node;
            }

            left_node.*.balance = .Balanced;
            node.*.balance = .Balanced;
        }

        fn leftRotate(self: *Self, node: *Node) void {
            //node, parent, and left-child of node - theres going to be 4-5 pointers being manipulated
            var parent_node = node.*.parent orelse null;
            var right_node = node.*.right.?;
            node.*.parent = right_node;
            right_node.*.parent = parent_node;

            if (right_node.*.left) |left_node| {
                node.*.right = left_node;
                left_node.*.parent = node;
            } else {
                node.*.right = null;
            }
            right_node.*.left = node;
            if (parent_node) |*parent| {

                //determining which child of parent to update
                if (right_node.*.data < parent.*.data) {
                    parent.*.left = right_node;
                } else {
                    parent.*.right = right_node;
                }
            } else {
                self.*.root = right_node;
            }

            right_node.*.balance = .Balanced;
            node.*.balance = .Balanced;
        }

        fn height(node: ?*const Node) isize {
            var curr_node = node orelse return -1;
            var ht: isize = 0;

            while (curr_node.*.left != null or curr_node.*.right != null) {
                switch (curr_node.*.balance) {
                    .LeftHeavy => {
                        // std.debug.print("\n{} is left-heavy", .{curr_node.data});

                        //go to left child
                        curr_node = curr_node.*.left.?;
                        ht += 1;
                    },
                    .RightHeavy => {
                        // std.debug.print("\n{} is right-heavy", .{curr_node.data});

                        curr_node = curr_node.*.right.?;
                        ht += 1;
                    },
                    .Balanced => {
                        // std.debug.print("\n{} is balanced", .{curr_node.data});
                        if (curr_node.*.right == null)
                            break;
                        curr_node = curr_node.*.right.?;
                        ht += 1;
                    },
                }
            }
            // std.debug.print("\nheight: {}", .{ht});
            return ht;
        }

        fn newNode(self: *Self, data: T, parent: ?*Node) !*Node {
            const new_node = try self.*.allocator.create(Node);
            new_node.*.init(data, parent);
            self.*.count += 1;

            return new_node;
        }

        fn deinit(self: Self) void {
            std.debug.print("\n\nDeinit", .{});
            var curr_node = self.root;
            while (curr_node) |*node| {
                curr_node.?.print();
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

                        std.debug.print("\nDeleted {} ", .{temp.data});
                        // const next = if (curr_node != null) curr_node.?.*.data else null;
                        // std.debug.print("\nDeleting {}, next to be deleted: {any}", .{ temp.data, next });
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

test "same element tree" {
    var allocator = std.testing.allocator;

    var tree = AVL(usize).init(allocator);
    try tree.insert(10);
    try tree.insert(20);
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

    std.debug.print("\nno. of nodes: {}\n\n\n", .{tree.count});

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
