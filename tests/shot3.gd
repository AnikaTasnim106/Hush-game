extends Node
func _ready() -> void:
	var main: Main = get_parent()
	main.ui.fade.color.a = 0.0
	main.player.invuln = 99999.0
	for spot in [[Vector2(1100, -60), "c3_a"], [Vector2(2950, -80), "c3_b"], [Vector2(4800, -400), "c3_c"], [Vector2(7900, -60), "c3_d"]]:
		main.player.global_position = spot[0]
		main.cam.snap()
		for i in 40:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/%s.png" % spot[1])
	get_tree().quit()
