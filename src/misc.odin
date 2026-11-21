package main

import "core:fmt"
import lin "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

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
	delete(mesh.normals)
	delete(mesh.uvs)
	delete(mesh.tris)
	delete(mesh.tri_col)
	rl.UnloadImage(mesh.img)
}

load_mesh_from_obj :: proc(obj_name: string) -> (mesh: Mesh, ok: bool) {
	filepath := strings.concatenate({"./objects/", obj_name, ".obj"})
	mtl_path := strings.concatenate({"./objects/", obj_name, ".png"})

	image := rl.LoadImage(strings.clone_to_cstring(mtl_path))
	if image.data == nil do return {}, false

	data, err := os.read_entire_file(filepath, context.allocator)
	if err != nil {
		fmt.eprintfln("%s: %s", filepath, os.error_string(err))
		return {}, false
	}
	defer delete(data)

	verts: [dynamic]Vec3
	normals: [dynamic]Vec3
	uvs: [dynamic]Vec2
	tris: [dynamic]Tri
	tri_col: [dynamic]Color

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
		case "vt":
			x, _ := strconv.parse_f32(f[1])
			y, _ := strconv.parse_f32(f[1])
			append_elem(&uvs, {x, y})
		case "f":
			rest := line
			_, _ = strings.fields_iterator(&rest) // skip "f"
			fields := strings.split(rest, " ")
			fields_content := make([][2]u32, len(fields)) // will hold pairs of v|vt
			defer delete(fields_content)

			for i in 0 ..< len(fields) {
				elements := strings.split(rest, "/")
				v, _ := strconv.parse_uint(elements[0])
				vt, _ := strconv.parse_uint(elements[1])

				fields_content[i][0] = u32(v)
				fields_content[i][1] = u32(vt)
			}


			r := u8(rand.int_range(0, 255))
			g := u8(rand.int_range(0, 255))
			b := u8(rand.int_range(0, 255))

			for i in 1 ..< len(fields) - 1 {
				tri: Tri
				tri.col = Color{r, g, b, 255}
				tri.v[0] = fields_content[0][0]
				tri.vt[0] = fields_content[0][1]

				tri.v[i] = fields_content[i][0]
				tri.vt[i] = fields_content[i][1]

				tri.v[i + 1] = fields_content[i + 1][0]
				tri.vt[i + 1] = fields_content[i + 1][1]

				append_elem(&tris, tri)
			}
		}
	}

	shrink(&verts)
	shrink(&normals)
	shrink(&uvs)
	shrink(&tris)
	shrink(&tri_col)

	return Mesh {
			verts = verts[:],
			normals = normals[:],
			uvs = uvs[:],
			tris = tris[:],
			tri_col = tri_col[:],
			img = image,
		},
		true
}
