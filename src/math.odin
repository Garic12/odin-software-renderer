package main

import lin "core:math/linalg"

get_view_matrix :: proc(cam: ^Cam) -> matrix[4, 4]f32 {
	return lin.matrix4_look_at_f32(cam.pos, cam.target, {0, 0, 1})
}

get_proj_matrix :: proc(cam: ^Cam, ratio: f32) -> matrix[4, 4]f32 {
	return lin.matrix4_perspective_f32(cam.fov, ratio, cam.near, cam.far)
}
