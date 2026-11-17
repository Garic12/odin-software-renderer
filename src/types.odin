package main

Color :: [4]u8

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mesh :: struct {
	verts: []Vec3,
	tris:  [][3]u32,
}
