package main

import lin "core:math/linalg"


draw_tri :: proc(a, b, c: Vec2, pixels: []Color, width, height: f32) -> bool {
	left := max(0, min(a.x, b.x, c.x))
	right := min(width, max(a.x, b.x, c.x))
	top := max(0, min(a.y, b.y, c.y))
	bottom := min(height, max(a.y, b.y, c.y))

	perp_ac := lin.vector2_orthogonal(c - a)
	perp_cb := lin.vector2_orthogonal(b - c)
	perp_ba := lin.vector2_orthogonal(a - b)

	for y := top; y <= bottom; y += 1 {
		for x := left; x <= right; x += 1 {
			p := Vec2{x + 0.5, y + 0.5}
			AC: bool = lin.vector_dot(perp_ac, p - a) >= 0
			CB: bool = lin.vector_dot(perp_cb, p - c) >= 0
			AB: bool = lin.vector_dot(perp_ba, p - b) >= 0

			if AC == CB && AC == AB {
				pixels[cast(int)(y * width + x)] = Color{255, 255, 255, 255}
			}
		}
	}
	return false
}
