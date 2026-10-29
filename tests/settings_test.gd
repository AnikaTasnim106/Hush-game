extends Node
func ok(name: String, cond: bool) -> void:
	print("SET: ", "PASS " if cond else "FAIL ", name)
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var m = get_tree().get_first_node_in_group("main")
	var ui = m.ui
	var menus = ui.menus
	# 1. menu button opens / closes
	menus.menu.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	ok("menu button opens menu", ui.overlay_open == "pause" and menus.panel.visible and get_tree().paused)
	# 2. sliders
	var sliders: Array = menus.panel.find_children("*", "HSlider", true, false)
	ok("3 sliders exist", sliders.size() == 3)
	if sliders.size() == 3:
		sliders[0].value = 0.5
		sliders[1].value = 0.3
		sliders[2].value = 0.6
		await get_tree().process_frame
		var mi := AudioServer.get_bus_index("Music")
		var si := AudioServer.get_bus_index("SFX")
		ok("master slider changes volume", absf(GameState.volume - 0.5) < 0.01 and absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.5)) < 0.1)
		ok("music slider changes Music bus", mi >= 0 and absf(AudioServer.get_bus_volume_db(mi) - linear_to_db(0.3)) < 0.1)
		ok("sfx slider changes SFX bus", si >= 0 and absf(AudioServer.get_bus_volume_db(si) - linear_to_db(0.6)) < 0.1)
	# 3. buttons by text
	var btns := {}
	for b in menus.panel.find_children("*", "Button", true, false):
		btns[b.text.split(" ")[0]] = b
	# mute button in panel
	var was: bool = GameState.muted
	btns["Sound:"].pressed.emit()
	await get_tree().process_frame
	ok("menu mute toggles", GameState.muted != was and AudioServer.is_bus_mute(0) == GameState.muted)
	btns["Sound:"].pressed.emit()
	await get_tree().process_frame
	# speaker button
	was = GameState.muted
	menus.mute.pressed.emit()
	await get_tree().process_frame
	ok("speaker button toggles", GameState.muted != was)
	menus.mute.pressed.emit()
	# M key
	was = GameState.muted
	var k := InputEventKey.new(); k.physical_keycode = KEY_M; k.pressed = true
	Input.parse_input_event(k)
	await get_tree().process_frame
	await get_tree().process_frame
	ok("M key toggles mute", GameState.muted != was)
	if GameState.muted != was: GameState.toggle_mute()
	# How to Play
	btns["How"].pressed.emit()
	await get_tree().process_frame
	ok("How to Play opens", ui._pause_howto and not menus.panel.visible and ui.overlay.visible)
	var esc := InputEventAction.new(); esc.action = "pause"; esc.pressed = true
	Input.parse_input_event(esc)
	await get_tree().process_frame
	await get_tree().process_frame
	ok("Esc closes How to Play back to menu", not ui._pause_howto and menus.panel.visible)
	# Resume
	btns["Resume"].pressed.emit()
	await get_tree().process_frame
	ok("Resume closes menu + unpauses", ui.overlay_open == "" and not get_tree().paused)
	# Esc opens and closes
	Input.parse_input_event(esc)
	await get_tree().process_frame
	await get_tree().process_frame
	ok("Esc opens menu", ui.overlay_open == "pause")
	Input.parse_input_event(esc)
	await get_tree().process_frame
	await get_tree().process_frame
	ok("Esc closes menu", ui.overlay_open == "" and not get_tree().paused)
	# Restart from Lantern
	m.player.global_position += Vector2(400, 0)
	menus.menu.pressed.emit()
	await get_tree().process_frame
	btns["Restart"].pressed.emit()
	await get_tree().create_timer(0.3).timeout
	ok("Restart from Lantern respawns", m.player.global_position.distance_to(m.player.respawn_pos) < 80 and not get_tree().paused)
	# settings saved
	var cf := ConfigFile.new()
	ok("settings saved to file", cf.load("user://settings.cfg") == OK and absf(float(cf.get_value("sound", "music", -1)) - 0.3) < 0.01)
	get_tree().quit()
