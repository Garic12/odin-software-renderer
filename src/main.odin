package main

import "core:fmt"
import "core:os"
import "core:time"
import rl "vendor:raylib"

W_WIDTH :: 400
W_HEIGHT :: 400

main :: proc() {
	rl.InitWindow(W_WIDTH, W_HEIGHT, "ORS")
	defer rl.CloseWindow()

	if !rl.IsWindowReady() {
		fmt.eprint("error: couldn't initialize window")
		os.exit(1)
	}

	// Ressource initialization
	img := rl.GenImageColor(W_WIDTH, W_HEIGHT, rl.BLACK)
	defer rl.UnloadImage(img)

	tex := rl.LoadTextureFromImage(img)
	defer rl.UnloadTexture(tex)

	fb := make_framebuffer(W_WIDTH, W_HEIGHT)
	defer destroy_framebuffer(&fb)

	start := time.tick_now()
	mesh, ok := load_mesh_from_obj("./objects/model.obj")
	if !ok do return
	defer destroy_mesh(&mesh)

	fmt.printfln(
		"loaded obj (%d verts, %d tris) in %.2fms",
		len(mesh.verts),
		len(mesh.tris),
		time.duration_milliseconds(time.tick_since(start)),
	)

	// Instance creation
	inst := make_instance(&mesh, Vec3{-0.3, 0, 0})

	// Cam setup
	cam: Cam
	cam.target = Vec3{-3, 0, 1}
	cam.pos = Vec3{0, 0, -1.5}
	cam.near = 0.1
	cam.far = 100
	cam.fov = 90


	rl.SetTargetFPS(30)
	for {
		if rl.WindowShouldClose() {break}
		dt := rl.GetFrameTime()

		if (rl.IsKeyDown(.SPACE)) {
			inst.pos += dt * Vec3{0, 0, 1}
		}

		view := get_view_matrix(&cam)
		proj := get_proj_matrix(&cam, f32(W_WIDTH) / f32(W_HEIGHT))
		view_proj := proj * view

		clear_framebuffer(&fb)
		draw_instance(&fb, &inst, view_proj)

		rl.UpdateTexture(tex, raw_data(fb.color))

		rl.BeginDrawing()
		rl.DrawTexture(tex, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}
}
