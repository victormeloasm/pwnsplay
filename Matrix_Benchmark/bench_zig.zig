const std = @import("std");

const N: usize = 1000;
const CblasColMajor: i32 = 102;
const CblasNoTrans: i32 = 111;

extern fn cblas_dgemm(
    layout: i32,
    transa: i32,
    transb: i32,
    m: i32,
    n: i32,
    k: i32,
    alpha: f64,
    a: [*]const f64,
    lda: i32,
    b: [*]const f64,
    ldb: i32,
    beta: f64,
    c: [*]f64,
    ldc: i32,
) void;

inline fn aval(i: usize, j: usize) f64 {
    return @as(f64, @floatFromInt((i * 131 + j * 17 + 13) % 1000)) * 0.001 - 0.5;
}

inline fn bval(i: usize, j: usize) f64 {
    return @as(f64, @floatFromInt((i * 19 + j * 137 + 7) % 1000)) * 0.001 - 0.5;
}

fn checksum(c: []const f64) f64 {
    var s: f64 = 0.0;
    var idx: usize = 0;
    while (idx < N*N) : (idx += 97) {
        const row = idx / N;
        const col = idx % N;
        s += c[row + col*N];
    }
    return s;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const a = try alloc.alloc(f64, N*N);
    defer alloc.free(a);
    const b = try alloc.alloc(f64, N*N);
    defer alloc.free(b);
    const c = try alloc.alloc(f64, N*N);
    defer alloc.free(c);

    var i: usize = 0;
    while (i < N) : (i += 1) {
        var j: usize = 0;
        while (j < N) : (j += 1) {
            a[i + j*N] = aval(i,j);
            b[i + j*N] = bval(i,j);
        }
    }

    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
        @intCast(N), @intCast(N), @intCast(N),
        1.0, a.ptr, @intCast(N), b.ptr, @intCast(N),
        0.0, c.ptr, @intCast(N));

    var timer = try std.time.Timer.start();

    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
        @intCast(N), @intCast(N), @intCast(N),
        1.0, a.ptr, @intCast(N), b.ptr, @intCast(N),
        0.0, c.ptr, @intCast(N));

    const ms = @as(f64, @floatFromInt(timer.read())) / 1_000_000.0;

    const out = std.io.getStdOut().writer();
    try out.print("language Zig OpenBLAS FFI\n", .{});
    try out.print("time_ms {d:.6}\n", .{ms});
    try out.print("checksum {d:.17}\n", .{checksum(c)});
}
