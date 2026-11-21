package main

import rl "vendor:raylib"

Color :: [4]u8

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

Mat4 :: matrix[4, 4]f32

Framebuffer :: struct {
	w, h:  f32,
	color: []Color,
	depth: []f32,
}

ScreenVert :: struct {
	pos: Vec2,
	z:   f32,
	uv:  [2]f32,
}

Tri :: struct {
	v, vt: [3]u32,
	n:     Vec3,
	col:   Color,
}

Mesh :: struct {
	verts:   []Vec3,
	normals: []Vec3,
	uvs:     []Vec2,
	tris:    []Tri,
	tri_col: []Color,
	img:     rl.Image,
}

MeshInstance :: struct {
	mesh:      ^Mesh,
	pos:       Vec3,
	scale:     f32,
	transform: matrix[4, 4]f32,
}

Cam :: struct {
	pos, target: Vec3,
	near, far:   f32,
	fov:         f32,
}

Input :: struct {
	move_dir:   Vec3,
	yaw, pitch: f32,
}
