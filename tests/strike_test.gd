extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var m = get_tree().get_first_node_in_group("main")
	var p = m.player
	for code in [KEY_J, KEY_X]:
		var e := InputEventKey.new(); e.physical_keycode = code; e.keycode = code; e.pressed = true
		Input.parse_input_event(e)
		var hit := false
		for i in 20:
			await get_tree().physics_frame
			if p.strike_t >= 0.0: hit = true
		var r := InputEventKey.new(); r.physical_keycode = code; r.keycode = code; r.pressed = false
		Input.parse_input_event(r)
		await get_tree().create_timer(0.6).timeout
		print("STRIKE: key=", OS.get_keycode_string(code), " works=", hit, " locked=", p.control_locked, " state=", m.state, " overlay=", m.ui.overlay_open)
	get_tree().quit()
