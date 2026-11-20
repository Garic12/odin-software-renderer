package main

import "core:math"
import lin "core:math/linalg"

draw_line :: proc(fb: ^Framebuffer, a, b: ScreenVert, color: Color) {
	// Implements Bresenham’s algorithm
	x1 := int(math.round(a.pos.x))
	x2 := int(math.round(b.pos.x))
	y1 := int(math.round(a.pos.y))
	y2 := int(math.round(b.pos.y))

	dx := abs(x2 - x1)
	dy := -abs(y2 - y1)
	sx := x1 < x2 ? 1 : -1
	sy := y1 < y2 ? 1 : -1
	err := dx + dy

	steps := max(dx, -dy)
	i := 0

	for {
		if (x1 >= 0 && x1 < int(fb.w)) && (y1 >= 0 && y1 < int(fb.h)) {
			t := steps == 0 ? 0 : f32(i) / f32(steps)
			p_z := a.z + t * (b.z - a.z)

			idx := y1 * int(fb.w) + x1

			if p_z > fb.depth[idx] {
				fb.depth[idx] = p_z
				fb.color[idx] = color
			}
		}

		if x1 == x2 && y1 == y2 do break
		i += 1

		e2 := 2 * err

		if e2 >= dy {
			err += dy
			x1 += sx
		}
		if e2 <= dx {
			err += dx
			y1 += sy
		}
	}
}

draw_tri :: proc(fb: ^Framebuffer, a, b, c: ScreenVert, color: Color) {
	area := lin.vector_cross2(b.pos - a.pos, c.pos - a.pos)
	if area >= 0 do return

	left := int(math.floor(max(0, min(a.pos.x, b.pos.x, c.pos.x))))
	right := int(math.ceil(min(fb.w - 1, max(a.pos.x, b.pos.x, c.pos.x))))
	top := int(math.floor(max(0, min(a.pos.y, b.pos.y, c.pos.y))))
	bottom := int(math.ceil(min(fb.h - 1, max(a.pos.y, b.pos.y, c.pos.y))))

	for y := top; y <= bottom; y += 1 {
		for x := left; x <= right; x += 1 {
			p := Vec2{f32(x) + 0.5, f32(y) + 0.5}

			w0 := lin.vector_cross2(c.pos - b.pos, p - b.pos) / area
			w1 := lin.vector_cross2(a.pos - c.pos, p - c.pos) / area
			w2 := lin.vector_cross2(b.pos - a.pos, p - a.pos) / area
			if w0 < 0 || w1 < 0 || w2 < 0 do continue

			p_z := w0 * a.z + w1 * b.z + w2 * c.z
			i := y * int(fb.w) + x

			if p_z > fb.depth[i] {
				fb.depth[i] = p_z
				fb.color[i] = color
			}
		}
	}
}

draw_instance :: proc(fb: ^Framebuffer, inst: ^MeshInstance, view_proj: Mat4) {
	inst.transform = lin.matrix4_translate_f32(inst.pos)
	mvp := view_proj * inst.transform

	screen_verts := make([]ScreenVert, len(inst.mesh.verts))
	defer delete(screen_verts)

	for v, i in inst.mesh.verts {
		clip := mvp * (Vec4{v.x, v.y, v.z, 1} * Vec4{inst.scale, inst.scale, inst.scale, 1})

		inv_w := 1 / clip.w
		ndc := clip.xyz * inv_w

		screen_coords := Vec2{(ndc.x + 1) / 2 * fb.w, (1 - ndc.y) / 2 * fb.h}
		screen_verts[i] = ScreenVert{screen_coords, inv_w}
	}

	for tri, i in inst.mesh.tris {
		a := screen_verts[tri.x - 1]
		b := screen_verts[tri.y - 1]
		c := screen_verts[tri.z - 1]

		if (a.z < 0 || b.z < 0 || c.z < 0) do continue

		draw_tri(fb, a, b, c, inst.mesh.col[i])
	}
}

draw_xyz :: proc(fb: ^Framebuffer, view_proj: Mat4) {
	verts := [6]Vec3 {
		Vec3{2, 0, 0},
		Vec3{0, 2, 0},
		Vec3{0, 0, 2},
		Vec3{-2, 0, 0},
		Vec3{0, -2, 0},
		Vec3{0, 0, -2},
	}

	colors := [3]Color{Color{0, 255, 0, 255}, Color{255, 0, 0, 255}, Color{0, 0, 255, 255}}
	screen_verts: [6]ScreenVert

	for v, i in verts {
		clip := view_proj * Vec4{v.x, v.y, v.z, 1}

		inv_w := 1 / clip.w
		ndc := clip.xyz * inv_w

		screen_coords := Vec2{(ndc.x + 1) / 2 * fb.w, (1 - ndc.y) / 2 * fb.h}
		screen_verts[i] = ScreenVert{screen_coords, inv_w}
	}

	for i := 0; i < 3; i += 1 {
		a := screen_verts[i]
		b := screen_verts[i + 3]

		if a.z < 0 || b.z < 0 do continue
		draw_line(fb, screen_verts[i], screen_verts[i + 3], colors[i])
	}
}
