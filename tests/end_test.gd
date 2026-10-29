extends Node
## --endtest: Chapter 3 finale + ending path check (skips the platforming).
func _ready() -> void:
	var main: Main = get_parent()
	await get_tree().create_timer(0.5).timeout
	var p: Player = main.player
	p.invuln = 99999.0
	for tf in get_tree().get_nodes_in_group("townsfolk"):
		tf.take_hit(9, p.global_position, "strike")
		while main.cutscene or p.control_locked:
			await get_tree().process_frame
	print("END: rescued ", GameState.rescued.size())
	await get_tree().create_timer(2.0).timeout
	p.global_position = Vector2(main.L.ARENA_X0 + 250, -60)
	await get_tree().create_timer(6.0).timeout
	print("END: boss state ", main.boss.state)
	for i in 3:
		while main.boss.state != "fight":
			await get_tree().process_frame
		for k in 3:
			main.boss.take_hit(1, p.global_position, "strike")
		await get_tree().create_timer(0.5).timeout
	print("END: boss ", main.boss.state, " done=", main.boss_done)
	while p.control_locked:
		await get_tree().process_frame
	p.global_position = Vector2(main.L.END_X + 10, -60)
	await get_tree().create_timer(20.0).timeout
	print("END: TIMEOUT")
	get_tree().quit(1)
