package main

import "core:fmt"
import lin "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

make_framebuffer :: proc(w, h: f32) -> Framebuffer {
	return Framebuffer{w, h, make([]Color, int(w * h)), make([]f32, int(w * h))}
}

destroy_framebuffer :: proc(fb: ^Framebuffer) {
	delete(fb.color)
	delete(fb.depth)
}

clear_framebuffer :: proc(fb: ^Framebuffer) {
	slice.fill(fb.depth, 0)
	slice.fill(fb.color, Color{0, 0, 0, 255})
}

make_instance :: proc(mesh: ^Mesh, pos: Vec3, scale: f32) -> MeshInstance {
	return MeshInstance{mesh, pos, scale, lin.matrix4_translate_f32(pos)}
}

destroy_mesh :: proc(mesh: ^Mesh) {
	delete(mesh.verts)
	delete(mesh.tris)
	delete(mesh.col)
}

load_mesh_from_obj :: proc(filepath: string) -> (mesh: Mesh, ok: bool) {
	data, err := os.read_entire_file(filepath, context.allocator)
	if err != nil {
		fmt.eprintfln("%s: %s", filepath, os.error_string(err))
		return {}, false
	}
	defer delete(data)

	verts: [dynamic]Vec3
	tris: [dynamic][3]u32
	colors: [dynamic]Color

	face: [dynamic]u32
	defer delete(face)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		l := line
		f: [4]string
		n := 0

		for field in strings.fields_iterator(&l) {
			if n == len(f) do break
			f[n] = field
			n += 1
		}

		if n == 0 do continue

		switch f[0] {
		case "v":
			x, _ := strconv.parse_f32(f[1])
			y, _ := strconv.parse_f32(f[2])
			z, _ := strconv.parse_f32(f[3])
			append_elem(&verts, Vec3{x, y, z})
		case "f":
			clear(&face)
			rest := line
			_, _ = strings.fields_iterator(&rest) // skip "f"
			for field in strings.fields_iterator(&rest) {
				// "a", "a/b", "a//c", "a/b/c" -> take only "a"
				idx_str := field
				if i := strings.index_byte(field, '/'); i >= 0 do idx_str = field[:i]
				idx, _ := strconv.parse_uint(idx_str)
				append_elem(&face, u32(idx))
			}
			for i in 1 ..< len(face) - 1 {
				r := u8(rand.int_range(0, 255))
				g := u8(rand.int_range(0, 255))
				b := u8(rand.int_range(0, 255))

				append_elem(&colors, Color{r, g, b, 255})
				append_elem(&tris, [3]u32{face[0], face[i], face[i + 1]})
			}
		}
	}

	shrink(&verts)
	shrink(&tris)
	shrink(&colors)

	return Mesh{verts = verts[:], tris = tris[:], col = colors[:]}, true
}
