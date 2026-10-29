extends Node
## --shot mode: teleports Wren around the level and saves stills for review.

var main: Main
var out_dir := "res://../runtime/shots"

func _ready() -> void:
	main = get_parent()
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run()

func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("SHOT ", name)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _go(pos: Vector2, facing := 1.0) -> void:
	main.player.global_position = pos
	main.player.velocity = Vector2.ZERO
	main.player.facing = facing
	main.cam.snap()

func _run() -> void:
	GameState.autoplay = true   # auto-advance dialogue
	main.state = "play"
	main.ui.set_hud_visible(true)
	main.ui.fade.color.a = 0.0
	main.player.control_locked = false
	await _frames(10)
	main.player.invuln = 99999.0
	if GameState.chapter == 2:
		await _fields()
		return
	if GameState.chapter==4:
		await _tower_shots()
		return
	var spots := [
		[Vector2(160, -60), "01_start"],
		[Vector2(1000, -60), "02_first_hush"],
		[Vector2(1900, -60), "03_market"],
		[Vector2(2440, -60), "04_baker"],
		[Vector2(3330, -300), "05_rooftop1"],
		[Vector2(4150, -330), "06_laundry"],
		[Vector2(4520, -360), "07_lamplighter"],
		[Vector2(5250, -260), "08_canal"],
		[Vector2(6000, -60), "09_square"],
		[Vector2(6600, -160), "10_stage"],
		[Vector2(7300, -60), "11_gate"],
	]
	for s in spots:
		_go(s[0])
		await _frames(30)
		await _snap(s[1])
	# rescue the baker and capture the colour bloom + dialogue
	_go(Vector2(2470, -60))
	await _frames(10)
	var baker: Townsfolk = null
	for tf in get_tree().get_nodes_in_group("townsfolk"):
		if tf.id == "baker":
			baker = tf
	main.player.facing = 1.0
	for i in 3:
		baker.take_hit(1, main.player.global_position, "strike")
		await _frames(8)
	await _frames(40)
	await _snap("13_rescue_bloom")
	await get_tree().create_timer(1.8).timeout
	await _snap("14_rescue_talk")
	await get_tree().create_timer(4.0).timeout
	await _snap("15_after_rescue")
	# strike pose mid-air
	_go(Vector2(1300, -60))
	main.player.velocity = Vector2(0, -700)
	await _frames(12)
	main.player.bot["strike_p"] = true
	main.player.use_bot = true
	await _frames(8)
	await _snap("16_air_strike")
	main.player.use_bot = false
	main.global_colour = 1.0
	_go(Vector2(5900, -60))
	await _frames(30)
	await _snap("21_square_full_colour")
	_go(Vector2(3400, -300))
	await _frames(30)
	await _snap("22_rooftops_full_colour")
	main.global_colour = 0.0
	# boss fight
	_go(Vector2(7820, -60))
	await get_tree().create_timer(6.0).timeout
	await _snap("17_boss_intro")
	await get_tree().create_timer(2.0).timeout
	await _snap("18_boss_track")
	await get_tree().create_timer(1.0).timeout
	await _snap("19_boss_slam")
	main.ui.open_overlay("journal")
	await _frames(5)
	await _snap("20_journal")
	main.ui.close_overlay()
	get_tree().quit()

func _fields() -> void:
	for entry in [[Vector2(850,-100),"c2_01_frozen_mill"],[Vector2(1650,-80),"c2_02_hollis"],[Vector2(3300,-80),"c2_03_fen"],[Vector2(4650,-180),"c2_04_chase"],[Vector2(7500,-430),"c2_05_pond"]]:
		_go(entry[0])
		main.player.set_physics_process(false)
		await _frames(20)
		await _snap(entry[1])
	main.global_colour = 1.0
	for w in get_tree().get_nodes_in_group("windmill"): w.active = true
	_go(Vector2(850,-300))
	main.player.rig.state = "glide"
	await _frames(30)
	await _snap("c2_06_restored_wind")
	_go(Vector2(10550,-100))
	main.boss_started = true
	main.boss.start_fight()
	main.ui.show_boss("The Scarecrow Choir")
	await _frames(220)
	await _snap("c2_07_choir")
	main.ui.hide_boss()
	for id in [3,4,5]: GameState.add_page(id)
	for tf in get_tree().get_nodes_in_group("townsfolk"):
		GameState.rescued.append(tf.id)
		GameState.add_clue(tf.clue)
	main.ui.open_overlay("journal")
	await _frames(5)
	await _snap("c2_08_journal")
	main.ui.close_overlay()
	main.ui.show_end()
	await _frames(5)
	await _snap("c2_09_end")
	get_tree().quit()

func _tower_shots() -> void:
	main.player.set_physics_process(false)
	for e in [[Vector2(500,-1200),"tower_stairs"],[Vector2(700,-4750),"tower_heart"]]:
		_go(e[0]);await _frames(20);await _snap(e[1])
	main.finish_game("TRUE")
	await _frames(20)
	await _snap("tower_finale")
	get_tree().quit()
