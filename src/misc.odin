package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

destroy_mesh :: proc(mesh: ^Mesh) {
	delete(mesh.verts)
	delete(mesh.tris)
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

		if len(f) == 0 do continue

		switch f[0] {
		case "v":
			x, _ := strconv.parse_f32(f[1])
			y, _ := strconv.parse_f32(f[2])
			z, _ := strconv.parse_f32(f[3])
			append_elem(&verts, Vec3{x, y, z})
		case "f":
			x, _ := strconv.parse_uint(f[1])
			y, _ := strconv.parse_uint(f[2])
			z, _ := strconv.parse_uint(f[3])
			append_elem(&tris, {u32(x), u32(y), u32(z)})
		case:
			continue
		}
	}

	shrink(&verts)
	shrink(&tris)

	return Mesh{verts = verts[:], tris = tris[:]}, true
}
