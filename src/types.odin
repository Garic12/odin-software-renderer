package main

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
}

Mesh :: struct {
	verts: []Vec3,
	tris:  [][3]u32,
	col:   []Color,
}

MeshInstance :: struct {
	mesh:      ^Mesh,
	pos:       Vec3,
	transform: matrix[4, 4]f32,
}

Cam :: struct {
	pos, target: Vec3,
	near, far:   f32,
	fov:         f32,
}
