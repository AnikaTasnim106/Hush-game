extends Node
func click(pos: Vector2) -> void:
	var mm := InputEventMouseMotion.new(); mm.position = pos; mm.global_position = pos
	get_viewport().push_input(mm)
	await get_tree().process_frame
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos; e.global_position = pos
		get_viewport().push_input(e)
		await get_tree().process_frame
	await get_tree().process_frame
func centre(c: Control) -> Vector2:
	# canvas coords -> window coords (the window may be scaled)
	return get_viewport().get_final_transform() * c.get_global_rect().get_center()
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var m = get_tree().get_first_node_in_group("main")
	var ui = m.ui; var menus = ui.menus
	print("CLK: window size ", DisplayServer.window_get_size(), " transform ", get_viewport().get_final_transform())
	await click(centre(menus.menu))
	print("CLK: ", "PASS" if ui.overlay_open == "pause" else "FAIL", " real click on menu button")
	var btns := {}
	for b in menus.panel.find_children("*", "Button", true, false): btns[b.text.split(" ")[0]] = b
	var was: bool = GameState.muted
	await click(centre(btns["Sound:"]))
	print("CLK: ", "PASS" if GameState.muted != was else "FAIL", " real click on mute row")
	await click(centre(btns["Sound:"]))
	await click(centre(btns["How"]))
	print("CLK: ", "PASS" if ui._pause_howto else "FAIL", " real click How to Play")
	await click(get_viewport().get_final_transform() * Vector2(640, 360))
	print("CLK: ", "PASS" if not ui._pause_howto else "FAIL", " click closes How to Play")
	await click(centre(btns["Resume"]))
	print("CLK: ", "PASS" if ui.overlay_open == "" else "FAIL", " real click Resume")
	was = GameState.muted
	await click(centre(menus.mute))
	print("CLK: ", "PASS" if GameState.muted != was else "FAIL", " real click speaker")
	print("CLK: strike after speaker click? ", m.player.strike_t >= 0.0, " (should be false)")
	await click(centre(menus.mute))
	await get_tree().create_timer(0.5).timeout
	await click(get_viewport().get_final_transform() * Vector2(640, 400))
	await get_tree().process_frame
	print("CLK: ", "PASS" if m.player.strike_t >= 0.0 or m.player.rig.state == "strike" else "FAIL", " click in game rings bell")
	get_tree().quit()
