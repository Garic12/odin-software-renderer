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

	img := rl.GenImageColor(W_WIDTH, W_HEIGHT, rl.BLACK)
	defer rl.UnloadImage(img)

	tex := rl.LoadTextureFromImage(img)
	defer rl.UnloadTexture(tex)

	pixels := make([]Color, W_WIDTH * W_HEIGHT)
	defer delete(pixels)

	a := Vec2{50, 50}
	b := Vec2{200, 50}
	c := Vec2{125, 125}
	draw_tri(a, b, c, pixels, W_WIDTH, W_HEIGHT)

	start := time.tick_now()
	mesh, ok := load_mesh_from_obj("./objects/teapot.obj")
	if !ok do return
	defer destroy_mesh(&mesh)

	fmt.printfln("loaded obj in %.2fms", time.duration_milliseconds(time.tick_since(start)))


	rl.SetTargetFPS(30)
	for {
		if rl.WindowShouldClose() {break}

		rl.UpdateTexture(tex, raw_data(pixels))

		rl.BeginDrawing()
		rl.DrawTexture(tex, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}
}
