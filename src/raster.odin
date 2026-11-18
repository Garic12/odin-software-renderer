package main

import "core:math"
import lin "core:math/linalg"

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

			if p_z < fb.depth[i] {
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
		clip := mvp * Vec4{v.x, v.y, v.z, 1}

		inv_w := 1 / clip.w
		ndc := clip.xyz * inv_w

		screen_coords := Vec2{(ndc.x + 1) / 2 * fb.w, (ndc.y + 1) / 2 * fb.h}
		screen_verts[i] = ScreenVert{screen_coords, ndc.z}
	}

	for tri, i in inst.mesh.tris {
		a := screen_verts[tri.x - 1]
		b := screen_verts[tri.y - 1]
		c := screen_verts[tri.z - 1]

		draw_tri(fb, a, b, c, inst.mesh.col[i])
	}
}
