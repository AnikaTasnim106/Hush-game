extends Node
## --pagetest: checks each hidden song page can be reached with real inputs.
var main: Main
var p: Player
func _ready() -> void:
	main = get_parent()
	await get_tree().process_frame
	p = main.player
	p.use_bot = true
	p.control_locked = false
	p.invuln = 99999.0
	main.state = "play"
	GameState.autoplay = true
	for h in get_tree().get_nodes_in_group("hush"):
		h.queue_free()
	if GameState.chapter == 2:
		await _test_fields()
		return
	if GameState.chapter == 3:
		await _test_hall()
		return
	if GameState.chapter == 4:
		await _test_tower()
		return
	await _test0()
	await _test1()
	await _test2()
	print("PAGES: found ", GameState.pages)
	get_tree().quit(0 if GameState.pages.size() == 3 else 1)

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _close_overlay() -> void:
	if main.ui.overlay_open != "":
		main.ui.close_overlay()

func _test0() -> void:
	# drop onto the bread stall awning, bounce while holding jump, drift right to the sign
	p.global_position = Vector2(1930, -320)
	p.velocity = Vector2.ZERO
	p.bot["jump"] = true
	p.bot["x"] = 0.0
	await _wait(0.5)
	p.bot["x"] = 0.6
	await _wait(0.9)
	p.bot["x"] = 0.0
	p.bot["jump"] = false
	await _wait(0.6)
	print("PAGE0: pos=", p.global_position, " pages=", GameState.pages)
	_close_overlay()

func _test1() -> void:
	# stand on the H3 chimney and jump right onto the attic balcony
	p.global_position = Vector2(4420, -385 - 50)
	p.velocity = Vector2.ZERO
	await _wait(0.4)
	p.bot["jump_p"] = true
	p.bot["jump"] = true
	p.bot["x"] = 1.0
	await _wait(0.25)
	await _wait(0.3)
	p.bot["x"] = 0.3
	await _wait(0.5)
	p.bot["jump"] = false
	p.bot["x"] = 0.0
	await _wait(0.5)
	print("PAGE1: pos=", p.global_position, " pages=", GameState.pages)
	_close_overlay()

func _test2() -> void:
	# jump onto the stage above the loose board and stomp it
	p.global_position = Vector2(6800, -90 - 50)
	p.velocity = Vector2.ZERO
	await _wait(0.4)
	p.bot["jump_p"] = true
	p.bot["jump"] = true
	await _wait(0.3)
	p.bot["stomp_p"] = true
	await _wait(0.8)
	p.bot["jump"] = false
	await _wait(0.6)
	print("PAGE2: pos=", p.global_position, " pages=", GameState.pages)
	_close_overlay()

func _until(check: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not check.call() and elapsed < timeout:
		await _wait(0.05)
		elapsed += 0.05
	return check.call()

func _rise(x: float, target_y: float) -> bool:
	p.global_position = Vector2(x-70,-50)
	p.velocity = Vector2.ZERO
	p.bot["x"] = 0.0
	p.bot["jump"] = false
	p.facing = 1
	await _wait(0.3)
	for i in 3:
		p.bot["strike_p"] = true
		await _wait(0.55)
	p.bot["x"] = 0.4
	await _wait(0.45)
	p.bot["x"] = 0.0
	p.bot["jump"] = true
	p.bot["jump_p"] = true
	return await _until(func(): return p.global_position.y < target_y, 5.0)

func _test_fields() -> void:
	var ok := await _rise(850,-500)
	p.bot["x"] = 1.0
	ok = await _until(func(): return p.global_position.x > 1110,3.0) and ok
	p.bot["x"] = 0.0
	p.bot["jump"] = false
	ok = await _until(func(): return 3 in GameState.pages,5.0) and ok
	_close_overlay()
	print("PAGE3: ",3 in GameState.pages," via mill wind; pos=",p.global_position)
	ok = await _rise(7010,-635) and ok
	p.bot["x"] = 1.0
	ok = await _until(func(): return p.global_position.x > 7540,4.0) and ok
	p.bot["x"] = 0.0
	p.bot["jump"] = false
	ok = await _until(func(): return 4 in GameState.pages,5.0) and ok
	_close_overlay()
	print("PAGE4: ",4 in GameState.pages," via pond glide; pos=",p.global_position)
	ok = await _rise(8250,-480) and ok
	p.bot["x"] = 1.0
	ok = await _until(func(): return p.global_position.x > 8430,3.0) and ok
	p.bot["x"] = 0.0
	p.bot["jump"] = false
	p.bot["stomp_p"] = true
	ok = await _until(func(): return 5 in GameState.pages,5.0) and ok
	_close_overlay()
	print("PAGE5: ",5 in GameState.pages," via wind + stomp; pos=",p.global_position)
	print("PAGES: found ",GameState.pages)
	get_tree().quit(0 if ok and GameState.pages.size()==3 else 1)

func _test_hall() -> void:
	for pair in [[Vector2(2990,-80),6],[Vector2(5100,-322-50),7],[Vector2(6745,-90-50),8]]:
		p.global_position=pair[0];p.velocity=Vector2.ZERO
		p.bot["x"]=0;p.bot["jump"]=false
		await _wait(0.3)
		p.bot["jump_p"]=true;p.bot["jump"]=true
		if pair[1]==6: p.bot["x"]=-0.45
		await _until(func(): return pair[1] in GameState.pages,3)
		_close_overlay()
	print("PAGES HALL: ",GameState.pages)
	get_tree().quit(0 if GameState.pages.size()==3 else 1)
func _test_tower() -> void:
	var route:=Level4.route()
	for i in [6,20,34]:
		var q: Vector2=route[i]
		p.global_position=q+Vector2(0,-50);p.velocity=Vector2.ZERO
		p.bot["x"]=0;p.bot["jump"]=false
		await _wait(0.3)
		p.bot["jump_p"]=true;p.bot["jump"]=true;p.bot["x"]=1
		await _wait(0.58)
		p.bot["x"]=0
		await _until(func(): return 9+[6,20,34].find(i) in GameState.pages,3)
		_close_overlay()
	print("PAGES TOWER: ",GameState.pages)
	get_tree().quit(0 if GameState.pages.size()==3 else 1)
