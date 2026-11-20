package main

import "core:fmt"
import "core:math"
import lin "core:math/linalg"
import "core:os"
import "core:time"
import rl "vendor:raylib"

W_WIDTH :: 800
W_HEIGHT :: 800

gather_input :: proc(input: ^Input, forward: Vec2) {
	if (rl.IsKeyDown(.SPACE)) {
		input.move_dir.z = 1
	} else if (rl.IsKeyDown(.LEFT_SHIFT)) {
		input.move_dir.z = -1
	}

	fwd := lin.vector_normalize(Vec2{forward.x, forward.y})
	right := Vec2{fwd.y, -fwd.x}

	dir: Vec2
	if rl.IsKeyDown(.W) do dir += fwd
	if rl.IsKeyDown(.S) do dir -= fwd
	if rl.IsKeyDown(.D) do dir += right
	if rl.IsKeyDown(.A) do dir -= right

	input.move_dir.xy = lin.normalize0(dir)

	mouse_dir := rl.GetMouseDelta()
	input.yaw -= mouse_dir.x * 0.003
	input.pitch -= mouse_dir.y * 0.003
	input.pitch = clamp(input.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)
}

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

	cube, ok_cube := load_mesh_from_obj("./objects/cube.obj")
	if !ok_cube do return
	defer destroy_mesh(&cube)

	plane, ok_plane := load_mesh_from_obj("./objects/plane.obj")
	if !ok_plane do return
	defer destroy_mesh(&plane)

	// Instance creation
	inst := make_instance(&cube, Vec3{-2, 0, 0}, 0.5)
	inst2 := make_instance(&cube, Vec3{2, 0, 0}, 0.5)

	inst3 := make_instance(&plane, Vec3{0, 0, -1}, 1)

	// Cam setup
	cam: Cam
	cam.target = Vec3{-2, 0, 0}
	cam.pos = Vec3{0, 0, 3}
	cam.near = 0.1
	cam.far = 20
	cam.fov = math.to_radians(f32(90))

	input := Input{}


	rl.SetTargetFPS(30)
	for {
		if rl.WindowShouldClose() {break}
		dt := rl.GetFrameTime()

		focused := rl.IsWindowFocused()
		if focused && !rl.IsCursorHidden() {
			rl.DisableCursor()
		} else if !focused && rl.IsCursorHidden() {
			rl.EnableCursor()
		}

		forward := Vec3 {
			-math.sin(input.yaw) * math.cos(input.pitch),
			math.cos(input.yaw) * math.cos(input.pitch),
			math.sin(input.pitch),
		}
		cam.target = cam.pos + forward

		input.move_dir = Vec3{0, 0, 0}
		gather_input(&input, forward.xy)
		cam.pos += dt * 3 * input.move_dir
		cam.target += dt * 3 * input.move_dir

		view := get_view_matrix(&cam)
		proj := get_proj_matrix(&cam, f32(W_WIDTH) / f32(W_HEIGHT))
		view_proj := proj * view

		clear_framebuffer(&fb)
		draw_xyz(&fb, view_proj)
		draw_instance(&fb, &inst, view_proj)
		draw_instance(&fb, &inst2, view_proj)
		draw_instance(&fb, &inst3, view_proj)

		rl.UpdateTexture(tex, raw_data(fb.color))

		rl.BeginDrawing()
		rl.DrawTexture(tex, 0, 0, rl.WHITE)
		rl.DrawText(
			rl.TextFormat("Pos: %.1f, %.1f, %.1f", cam.pos.x, cam.pos.y, cam.pos.z),
			10,
			10,
			20,
			rl.WHITE,
		)
		rl.DrawText(
			rl.TextFormat("Target: %.1f, %.1f, %.1f", cam.target.x, cam.target.y, cam.target.z),
			10,
			30,
			20,
			rl.WHITE,
		)
		rl.EndDrawing()
	}
}
