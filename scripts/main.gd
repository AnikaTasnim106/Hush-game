class_name Main
extends Node2D
## Game root: builds layers + level, runs story flow, colour restoration, hints, boss, ending.

var world: Node2D
var decor_back: Node2D
var geo: Node2D
var decor_front: Node2D
var actors: Node2D
var hero_layer: CanvasLayer
var hero: Node2D
var fx_layer: CanvasLayer
var colour_rect: ColorRect
var colour_mat: ShaderMaterial
var bg: Background
var player: Player
var cam: CameraDirector
var ui: GameUI

var circles := []          # each: {pos, r, target, glow}
var global_colour := 0.0
var hints := []            # each: {rect, text, key, done}
var done_hints := {}
var lamps: Array[Prop] = []
var fountain: Prop
var gate: LevelObjects.SilenceGate
var boss: Node2D
var L = Level1             # current chapter's level script
var lights := []           # each: {node or pos, r, k}
var darkness := 0.0
var last_safe := Vector2.ZERO
var _safe_t := 0.0
var boss_wall_left: StaticBody2D
var boss_wall_right: StaticBody2D
var door_prop: Prop

var state := "boot"        # boot title intro play cutscene boss victory end
var cutscene := false
var boss_started := false
var boss_done := false
var ending := false
var t := 0.0

func _ready() -> void:
	add_to_group("main")
	if GameState.continuing:
		GameState.continuing = false
	else:
		GameState.reset_run()
	L = level_script(GameState.chapter)
	if "--all-pages" in OS.get_cmdline_user_args():
		for id in 12: GameState.add_page(id)
	GameState.page_ids = L.PAGE_IDS
	darkness = L.DARKNESS
	_build_layers()
	L.build(self)
	if "--finaltest" in OS.get_cmdline_user_args(): player.global_position=Vector2(565,Level4.TOP-50)
	last_safe = player.global_position
	for n in decor_back.get_children() + decor_front.get_children():
		if n is Prop and n.kind == "door":
			door_prop = n
	cam.snap()
	_update_colour(0.0)
	if GameState.autoplay:
		var b = load("res://scripts/bot.gd").new()
		add_child(b)
	if "--shot3" in OS.get_cmdline_user_args():
		add_child(load("res://tests/shot3.gd").new())
	if "--endtest" in OS.get_cmdline_user_args():
		GameState.autoplay = true
		add_child(load("res://tests/end_test.gd").new())
	if "--pagetest" in OS.get_cmdline_user_args():
		add_child(load("res://tests/page_test.gd").new())
		return
	if GameState.shot_mode:
		var s = load("res://scripts/shots.gd").new()
		add_child(s)
		return
	if GameState.skip_intro:
		start_play(false)
	elif GameState.jump_in:
		GameState.jump_in = false
		_chapter_intro()
	else:
		_title_flow()

static func level_script(n: int):
	var path := "res://scripts/level%d.gd" % n
	if ResourceLoader.exists(path):
		return load(path)
	return load("res://scripts/level1.gd")

static func chapter_exists(n: int) -> bool:
	return ResourceLoader.exists("res://scripts/level%d.gd" % n)

# ================================================================ construction
func _build_layers() -> void:
	bg = Background.new()
	add_child(bg)
	bg.build(L.WIDTH, L.THEME)
	world = Node2D.new(); world.name = "World"; add_child(world)
	decor_back = Node2D.new(); decor_back.name = "DecorBack"; world.add_child(decor_back)
	geo = Node2D.new(); geo.name = "Geo"; world.add_child(geo)
	actors = Node2D.new(); actors.name = "Actors"; world.add_child(actors)
	decor_front = Node2D.new(); decor_front.name = "DecorFront"; world.add_child(decor_front)

	fx_layer = CanvasLayer.new(); fx_layer.layer = 1; add_child(fx_layer)
	colour_rect = ColorRect.new()
	colour_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	colour_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colour_mat = ShaderMaterial.new()
	colour_mat.shader = load("res://shaders/colour_restore.gdshader")
	colour_rect.material = colour_mat
	fx_layer.add_child(colour_rect)

	hero_layer = CanvasLayer.new(); hero_layer.layer = 2; hero_layer.follow_viewport_enabled = true
	add_child(hero_layer)
	hero = Node2D.new(); hero_layer.add_child(hero)
	Fx.layer = hero

	player = Player.new()
	player.global_position = Vector2(120, -60)
	hero.add_child(player)
	player.died.connect(_on_player_died)
	player.made_noise.connect(noise)
	player.control_locked = true

	player.fall_respawn = func(): return last_safe
	cam = CameraDirector.new()
	cam.target = player
	cam.base_zoom = 1.08
	cam.zoom = Vector2.ONE * 1.08
	cam.min_x = -60.0
	cam.max_x = L.WIDTH - 200.0
	add_child(cam)

	ui = GameUI.new()
	add_child(ui)
	ui.pause_choice.connect(_on_pause_choice)

# ---------------------------------------------------------------- builder helpers (used by Level1)
func add_decor(kind: String, pos: Vector2, p: Dictionary, parent: Node, is_lamp := false) -> Prop:
	var pr := Prop.new()
	pr.kind = kind
	pr.p = p
	pr.position = pos
	parent.add_child(pr)
	if is_lamp:
		lamps.append(pr)
	return pr

func add_solid(r: Rect2, enabled := true) -> StaticBody2D:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.size * 0.5
	cs.disabled = not enabled
	sb.add_child(cs)
	sb.position = r.position
	geo.add_child(sb)
	return sb

func set_solid_enabled(sb: StaticBody2D, on: bool) -> void:
	if sb:
		(sb.get_child(0) as CollisionShape2D).set_deferred("disabled", not on)

func add_ground(x0: float, x1: float) -> void:
	add_solid(Rect2(x0, 0, x1 - x0, 900))
	add_decor("ground", Vector2(x0, 0), {"w": x1 - x0}, geo)

func add_oneway(r: Rect2, kind: String, p := {}) -> StaticBody2D:
	var sb := StaticBody2D.new()
	sb.collision_layer = 2
	sb.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(r.size.x, maxf(r.size.y, 8.0))
	cs.shape = sh
	cs.position = sh.size * 0.5
	cs.one_way_collision = true
	cs.one_way_collision_margin = 6.0
	sb.add_child(cs)
	sb.position = r.position
	geo.add_child(sb)
	match kind:
		"sign":
			var q := p.duplicate(); q["w"] = r.size.x
			add_decor("sign", r.position, q, decor_front)
		"balcony":
			add_decor("balcony", r.position, {"w": r.size.x}, decor_front)
		"line":
			add_decor("line", r.position + Vector2(0, 2), {"w": r.size.x, "sag": 6.0}, decor_front)
		"steps":
			add_decor("steps", Vector2(r.position.x, 0), {"w": r.size.x, "n": 2}, decor_front)
		"awning":
			pass
	if p.has("bounce"):
		sb.set_meta("bounce", p["bounce"])
	return sb

func add_stall(x: float, w: float, goods: String, c1: Color) -> void:
	add_solid(Rect2(x - 4, -70, w + 8, 70))
	add_decor("stall", Vector2(x, 0), {"w": w, "awn": 170.0, "goods": goods, "c1": c1}, decor_back)
	add_oneway(Rect2(x - 8, -200, w + 24, 12), "awning", {"bounce": 1180.0})

func add_house(r: Rect2, idx: int) -> void:
	var top := r.position.y
	add_solid(Rect2(r.position.x, top, r.size.x, -top + 900))
	add_decor("house", Vector2(r.position.x, top), {"w": r.size.x, "h": -top, "col": Level1.HOUSE_COLS[(idx + 2) % Level1.HOUSE_COLS.size()], "trim": Level1.TRIMS[idx % Level1.TRIMS.size()], "door": true, "door_at": 0.25 + 0.15 * (idx % 3), "lit_ratio": 0.4}, geo)

func add_chimney(r: Rect2) -> void:
	add_solid(r)
	add_decor("chimney", r.position, {"w": r.size.x, "h": r.size.y}, geo)

func add_crate(pos: Vector2, s: float) -> void:
	add_solid(Rect2(pos, Vector2(s, s)))
	add_decor("crate", pos, {"s": s}, geo)

func add_solid_prop(r: Rect2, kind: String, p: Dictionary) -> void:
	add_solid(r)
	var pr := add_decor(kind, Vector2(r.position.x, r.end.y), p, geo)
	if kind == "fountain":
		fountain = pr

func add_stage(x: float, w: float, h: float, loose_x: float) -> void:
	add_solid(Rect2(x, -h, loose_x - x, h))
	add_solid(Rect2(loose_x + 60, -h, x + w - loose_x - 60, h))
	add_solid(Rect2(loose_x, -30, 60, 30))
	add_decor("stage", Vector2(x, 0), {"w": w, "h": h, "loose": loose_x - x, "font": ui.f_ui_bold}, geo)
	add_breakable(Vector2(loose_x, -h), 60.0, "page:2")

func add_breakable(pos: Vector2, s: float, contents: String) -> void:
	var b := LevelObjects.Breakable.new()
	b.size = s
	b.contents = contents
	b.position = pos
	geo.add_child(b)

func add_checkpoint(pos: Vector2, active := false) -> void:
	var c := LevelObjects.Checkpoint.new()
	c.position = pos
	decor_front.add_child(c)
	if active:
		c.active = true
		c.on = 1.0
		player.respawn_pos = pos + Vector2(0, -50)

func add_gate(pos: Vector2) -> void:
	gate = LevelObjects.SilenceGate.new()
	gate.position = pos
	geo.add_child(gate)

func add_boss(pos: Vector2, x0: float, x1: float) -> void:
	boss = BossBell.new()
	boss.position = pos
	boss.arena_x0 = x0
	boss.arena_x1 = x1
	actors.add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	boss.damaged.connect(func(f): ui.set_boss_hp(f))
	boss.phase_changed.connect(func(ph):
		if ph < 3:
			spawn_heart(Vector2((x0 + x1) * 0.5, -200.0))
			ui.hint("A heart fell from the bell tower!", 2.5))

func add_organ(pos: Vector2, x0: float, x1: float, stops: Array) -> void:
	var o := OrganFinale.new()
	o.position = pos
	o.arena_x0 = x0
	o.arena_x1 = x1
	for sp in stops:
		o.stops.append(sp)
	decor_back.add_child(o)
	boss = o
	o.defeated.connect(_on_boss_defeated)
	o.damaged.connect(func(f): ui.set_boss_hp(f))
	o.phase_changed.connect(func(ph):
		if ph < 3:
			spawn_heart(Vector2((x0 + x1) * 0.5, -240.0)))

func spawn_hush(kind: String, pos: Vector2, patrol: float) -> Hush:
	var h := Hush.new()
	h.kind = kind
	h.patrol = patrol
	h.position = pos
	actors.add_child(h)
	return h

func add_townsfolk(id: String, nm: String, cfg: Dictionary, pose: Dictionary, pos: Vector2, facing: float, carry: String) -> Townsfolk:
	var tf := Townsfolk.new()
	tf.id = id
	tf.display_name = nm
	tf.rig_cfg = cfg
	tf.pose = pose
	tf.face_dir = facing
	tf.carry = carry
	tf.position = pos
	actors.add_child(tf)
	tf.freed.connect(_on_freed)
	return tf

func spawn_page(id: int, pos: Vector2) -> void:
	if id in GameState.pages:
		return
	var p := Pickup.new()
	p.kind = "page"
	p.page_id = id
	p.position = pos
	hero.add_child(p)

func spawn_heart(pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = "heart"
	p.position = pos
	hero.add_child(p)

func _floor_below(pos: Vector2) -> float:
	var q := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, 1200), 1 | 2)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		return hit.position.y - 14.0
	return pos.y + 300.0

func spawn_notes(pos: Vector2, n: int) -> void:
	var fy := _floor_below(pos)
	for i in n:
		var p := Pickup.new()
		p.kind = "note"
		p.position = pos
		p.vel = Vector2(randf_range(-170, 170), randf_range(-520, -280))
		p.floor_y = fy
		hero.add_child(p)

func note_row(start: Vector2, n: int, spacing: float) -> void:
	for i in n:
		var p := Pickup.new()
		p.kind = "note"
		p.settled = true
		p.position = start + Vector2(i * spacing, 0)
		hero.add_child(p)

func note_arc(start: Vector2, n: int, spacing: float) -> void:
	for i in n:
		var k := float(i) / maxf(1, n - 1)
		var p := Pickup.new()
		p.kind = "note"
		p.settled = true
		p.position = start + Vector2(i * spacing, -sin(k * PI) * 60.0)
		hero.add_child(p)

func add_hint(r: Rect2, text: String, key := "") -> void:
	hints.append({"rect": r, "text": text, "key": key})

func show_page(id: int) -> void:
	if not GameState.autoplay: ui.open_overlay("page", id)
	ui.hint("Lark's song page added to your journal (Tab)", 3.0)

# ================================================================ colour
func add_colour(pos: Vector2, radius: float, dur := 2.0) -> void:
	var c := {"pos": pos, "r": 0.0, "target": radius, "glow": 1.0}
	circles.append(c)
	var tw := create_tween()
	tw.tween_method(func(v): c["r"] = v, 0.0, radius, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_method(func(v): c["glow"] = v, 1.0, 0.0, dur + 0.6)

func _update_colour(_delta: float) -> void:
	var ct := get_viewport().get_canvas_transform()
	var vs := get_viewport().get_visible_rect().size
	var arr: Array[Vector4] = []
	for c in circles:
		var sp: Vector2 = ct * (c["pos"] as Vector2)
		arr.append(Vector4(sp.x, sp.y, c["r"] * ct.get_scale().x, c["glow"]))
	while arr.size() < 16:
		arr.append(Vector4(0, 0, 0, 0))
	colour_mat.set_shader_parameter("circles", arr)
	colour_mat.set_shader_parameter("count", mini(circles.size(), 16))
	colour_mat.set_shader_parameter("vsize", vs)
	colour_mat.set_shader_parameter("global_colour", global_colour)
	colour_mat.set_shader_parameter("time", t)
	var la: Array[Vector4] = []
	var pp: Vector2 = ct * (player.global_position + Vector2(0, -10))
	la.append(Vector4(pp.x, pp.y, 300.0 * ct.get_scale().x, 1.0))
	for l in lights:
		var src = l["src"]
		var wp: Vector2 = src.global_position if src is Node2D else src
		if src is Prop and not (src as Prop).lit:
			continue
		var sp2: Vector2 = ct * (wp + l.get("off", Vector2.ZERO))
		if sp2.x < -400 or sp2.x > vs.x + 400:
			continue
		la.append(Vector4(sp2.x, sp2.y, float(l["r"]) * ct.get_scale().x, float(l["k"])))
		if la.size() >= 16:
			break
	var nl := la.size()
	while la.size() < 16:
		la.append(Vector4(0, 0, 0, 0))
	colour_mat.set_shader_parameter("lights", la)
	colour_mat.set_shader_parameter("light_count", nl)
	colour_mat.set_shader_parameter("darkness", darkness)

# ================================================================ flow
func _title_flow() -> void:
	state = "title"
	ui.set_hud_visible(false)
	ui.fade.color.a = 1.0
	ui.show_title()
	Sfx.ambience(-16.0, -20.0, -80.0)
	await ui.fade_to(0.35, 1.2)
	var chosen := 1
	while true:
		await get_tree().process_frame
		if ui.overlay_open == "pause": continue
		if ui.menus.chapter_request > 0:
			chosen=ui.menus.chapter_request
			break
		if Input.is_action_just_pressed("advance") or GameState.autoplay:
			break
		for n in [1, 2, 3, 4]:
			if Input.is_key_pressed(KEY_0 + n) and chapter_exists(n):
				chosen = n
		if chosen != 1:
			break
	Sfx.play("strike2", -4.0)
	ui.hide_title()
	await ui.fade_to(1.0, 0.8)
	if chosen != GameState.chapter:
		GameState.chapter = chosen
		GameState.continuing = true
		GameState.jump_in = true
		get_tree().reload_current_scene()
		return
	await ui.story_cards(L.story_cards())
	start_play(true)

func _chapter_intro() -> void:
	ui.set_hud_visible(false)
	ui.fade.color.a = 1.0
	await ui.story_cards(L.story_cards())
	start_play(true)

func _wait_advance() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("advance") or GameState.autoplay:
			return

func start_play(with_intro: bool) -> void:
	state = "play"
	ui.set_hud_visible(true)
	var amb: Array = L.AMBIENCE
	Sfx.ambience(amb[0], amb[1], amb[2])
	cam.snap()
	if with_intro:
		player.control_locked = true
		ui.fade.color.a = 1.0
		ui.letterbox(true, 0.01)
		cam.focus = player.global_position + Vector2(60, -90)
		cam.focus_zoom = 1.35
		cam.global_position = cam.focus
		await ui.fade_to(0.0, 1.5)
		await ui.show_card(L.CHAPTER_CARD[0], L.CHAPTER_CARD[1], 1.6)
		await _say(L.intro_lines())
		cam.focus = null
		ui.letterbox(false)
	else:
		ui.fade.color.a = 0.0
	player.control_locked = false

func _say(lines: Array, speakers := {}) -> void:
	# lines: [speaker, text, expression]
	cutscene = true
	var conn := func(idx: int, sp: String) -> void:
		var ln: Array = lines[idx]
		var expr: String = ln[2] if ln.size() > 2 else "neutral"
		for k in speakers:
			var r: Rig = speakers[k]
			r.talking = false
		if sp == "Wren":
			player.rig.expression = expr
			player.rig.talking = true
			player.rig.state = "talk" if player.is_on_floor() else player.rig.state
		elif speakers.has(sp):
			var r: Rig = speakers[sp]
			r.expression = expr
			r.talking = true
		if sp != "Wren":
			player.rig.talking = false
	ui.dialogue_line.connect(conn)
	await ui.dialogue(lines.map(func(l): return [l[0], l[1]]))
	ui.dialogue_line.disconnect(conn)
	player.rig.talking = false
	for k in speakers:
		(speakers[k] as Rig).talking = false
	cutscene = false

# ---------------------------------------------------------------- rescues
func _on_freed(tf: Townsfolk) -> void:
	_rescue_scene(tf)

func _rescue_scene(tf: Townsfolk) -> void:
	player.control_locked = true
	done_hints["rescue_baker"] = true
	var center := tf.global_position + Vector2(0, -80)
	add_colour(tf.global_position + Vector2(0, -60), 820.0, 2.4)
	Fx.ring(center, 3.0, Color(1.0, 0.85, 0.5), 1.0)
	ui.letterbox(true)
	var side := signf(player.global_position.x - tf.global_position.x)
	if side == 0.0:
		side = -1.0
	var stand_x := tf.global_position.x + side * (130.0 if tf.id != "twins" else 150.0) + (42.0 if tf.id == "twins" and side > 0 else 0.0)
	player.auto_walk = stand_x
	cam.focus = Vector2((tf.global_position.x + stand_x) * 0.5, tf.global_position.y - 70.0)
	cam.focus_zoom = 1.4
	await get_tree().create_timer(1.6).timeout
	player.auto_walk = 0.0
	player.facing = signf(tf.global_position.x - player.global_position.x)
	tf.rig.facing = signf(player.global_position.x - tf.global_position.x)
	for r in tf.extra_rigs:
		r.facing = tf.rig.facing
	var speakers := {tf.display_name: tf.rig}
	if tf.id == "twins":
		speakers = {"Pim": tf.rig, "Posy": tf.extra_rigs[0]}
	# mid-dialogue effects
	var conn := func(idx: int, _sp: String) -> void:
		L.on_rescue_line(self, tf, idx)
	ui.dialogue_line.connect(conn)
	await _say(tf.lines, speakers)
	ui.dialogue_line.disconnect(conn)
	GameState.rescued.append(tf.id)
	GameState.add_clue(tf.clue)
	ui.hud.queue_redraw()
	ui.hint("New clue in your journal (Tab)", 3.5)
	# world reacts
	L.on_rescued(self, tf)
	var n := GameState.rescued.size()
	Sfx.ambience(-16.0, -18.0 - n * 3.0, [-80.0, -30.0, -24.0, -18.0][mini(n,3)])
	if is_instance_valid(gate):
		gate.set_count(n)
	cam.focus = null
	ui.letterbox(false)
	if n >= 3 and is_instance_valid(gate):
		await get_tree().create_timer(0.6).timeout
		ui.hint("The gate has opened.", 4.0)
		await _say(L.gate_lines())
	player.control_locked = false

func _light_lamps() -> void:
	Sfx.play("checkpoint", -2.0, 0.8)
	for i in lamps.size():
		var l := lamps[i]
		get_tree().create_timer(0.15 * i).timeout.connect(l.set_lit.bind(true))

# ---------------------------------------------------------------- boss
func _start_boss() -> void:
	boss_started = true
	player.control_locked = true
	set_solid_enabled(boss_wall_left, true)
	cam.lock_rect = Rect2(Vector2((L.ARENA_X0 + L.ARENA_X1) * 0.5 - 10, L.ARENA_CAM_Y), Vector2(20, 20))
	cam.base_zoom = 0.92
	ui.letterbox(true)
	await get_tree().create_timer(0.8).timeout
	await _say(L.boss_lines())
	ui.letterbox(false)
	boss.start_fight()
	Sfx.ambience(-24.0, -12.0, -80.0)
	await ui.show_card(L.BOSS_NAME, L.BOSS_SUB, 1.2)
	ui.show_boss(L.BOSS_NAME)
	ui.hint(L.BOSS_HINT, 6.0)
	ui.set_boss_hp(1.0 - boss.phase / 3.0)
	player.control_locked = false

func _on_boss_defeated() -> void:
	boss_done = true
	for mill in get_tree().get_nodes_in_group("windmill"): mill.free_mill()
	player.control_locked = true
	ui.hide_boss()
	for h in get_tree().get_nodes_in_group("hush"):
		h.dissolve_now()
	for w in get_tree().get_nodes_in_group("boss_wave"):
		w.queue_free()
	add_colour(Vector2(boss.global_position.x, -300), 1400.0, 3.0)
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(self, "global_colour", 1.0, 3.5).set_trans(Tween.TRANS_SINE)
	var tw3 := create_tween()
	tw3.tween_property(self, "darkness", L.DARK_AFTER, 4.0)
	Sfx.ambience(-20.0, -80.0, -12.0)
	cam.shake(10.0)
	await get_tree().create_timer(3.2).timeout
	ui.letterbox(true)
	await _say(L.victory_lines())
	ui.letterbox(false)
	set_solid_enabled(boss_wall_right, false)
	set_solid_enabled(boss_wall_left, false)
	cam.lock_rect = null
	cam.base_zoom = 1.08
	if door_prop:
		var tw2 := create_tween()
		tw2.tween_method(func(v): door_prop.p["open"] = v; door_prop.queue_redraw(), 0.0, 1.0, 1.5)
	ui.hint(L.AFTER_BOSS_HINT, 4.0)
	player.control_locked = false

func reset_boss() -> void:
	boss_started = false
	set_solid_enabled(boss_wall_left, false)
	cam.lock_rect = null
	cam.base_zoom = 1.08
	ui.hide_boss()
	for w in get_tree().get_nodes_in_group("boss_wave"):
		w.queue_free()
	for h in get_tree().get_nodes_in_group("hush"):
		if h.global_position.x > L.ARENA_X0 - 50:
			h.queue_free()
	boss.reset()
	Sfx.ambience(-14.0, -18.0, -18.0)

# ---------------------------------------------------------------- ending
func _ending() -> void:
	ending = true
	player.control_locked = true
	player.auto_walk = L.END_X + 20.0
	ui.letterbox(true)
	cam.focus = Vector2(L.END_X + 60, L.END_CAM_Y)
	cam.focus_zoom = 1.45
	await get_tree().create_timer(1.2).timeout
	await _say(L.ending_lines())
	await ui.fade_to(1.0, 1.4)
	ui.letterbox(false, 0.01)
	var nxt := -1
	for n in range(GameState.chapter + 1, 5):
		if chapter_exists(n):
			nxt = n
			break
	var info: Dictionary = L.END_INFO.duplicate()
	if nxt > 0:
		info["press"] = "Press Space to continue to Chapter %d" % nxt
	ui.show_end(info)
	await get_tree().create_timer(1.0).timeout
	if GameState.autoplay:
		print("BOT: reached end card. chapter=%d notes=%d pages=%d rescued=%d" % [GameState.chapter, GameState.notes, GameState.pages.size(), GameState.rescued.size()])
		get_tree().quit()
		return
	await _wait_advance()
	if nxt > 0:
		GameState.chapter = nxt
		GameState.rescued.clear()
		GameState.heal_full()
		GameState.continuing = true
		GameState.jump_in = true
	else:
		GameState.reset_run()
		GameState.chapter = 1
	get_tree().reload_current_scene()

# ---------------------------------------------------------------- death
var _fainting := false

func _on_player_died() -> void:
	if _fainting:
		return
	_fainting = true
	while cutscene:
		await get_tree().process_frame
	player.control_locked = true
	await ui.fade_to(1.0, 0.6)
	if boss_started and not boss_done:
		reset_boss()
	player.respawn()
	GameState.heal_full()
	var lost := mini(GameState.notes, 10)
	GameState.add_notes(-lost)
	cam.snap()
	await ui.fade_to(0.0, 0.6)
	if lost > 0:
		ui.hint("Wren picks herself up. (%d notes dropped)" % lost, 3.0)
	player.invuln = 1.5
	player.control_locked = false
	_fainting = false

func _on_pause_choice(choice: String) -> void:
	match choice:
		"Restart from Lantern":
			if boss_started and not boss_done:
				reset_boss()
			player.respawn()
			cam.snap()
		"Quit to Title":
			GameState.reset_run()
			GameState.chapter = 1
			GameState.continuing = false
			GameState.jump_in = false
			Engine.time_scale = 1.0
			get_tree().paused = false
			get_tree().call_deferred("reload_current_scene")

# ================================================================ per-frame
func _process(delta: float) -> void:
	t += delta
	_update_colour(delta)
	if state != "play":
		return
	# hints
	var p := player.global_position
	for h in hints:
		if h["key"] != "" and done_hints.has(h["key"]):
			continue
		if (h["rect"] as Rect2).has_point(p) and not player.control_locked:
			ui.hint(h["text"], 0.4)
	# interaction prompt
	var near: Townsfolk = null
	if not player.control_locked:
		for tf in get_tree().get_nodes_in_group("townsfolk"):
			if tf.can_interact() and tf.global_position.distance_to(p + Vector2(0, 48)) < 110.0:
				near = tf
				break
	if near:
		var sp: Vector2 = get_viewport().get_canvas_transform() * (near.global_position + Vector2(0, -170))
		ui.show_prompt(sp, "E   " + near.interact_label())
		if Input.is_action_just_pressed("interact"):
			ui.hide_prompt()
			_talk_again(near)
	else:
		ui.hide_prompt()
	# boss trigger
	if not boss_started and not boss_done and ((GameState.chapter != 4 and p.x > L.ARENA_X0 + 180.0) or (GameState.chapter == 4 and p.y < Level4.TOP-30 and p.x > 390)) and not player.control_locked:
		_start_boss()
	# ending trigger
	if GameState.chapter != 4 and boss_done and not ending and p.x > L.END_X - 40.0 and not player.control_locked:
		_ending()
	if GameState.hearts <= 0 and not _fainting and not player.fainted:
		player._faint()
	# remember last safe ground (for falls into water/pits)
	if GameState.chapter == 4: player.kill_y = minf(500,last_safe.y+550)
	_safe_t -= delta
	if _safe_t <= 0.0 and player.is_on_floor() and not player.on_moving and player.hurt_t <= 0.0:
		_safe_t = 0.4
		last_safe = player.global_position

func _talk_again(tf: Townsfolk) -> void:
	player.control_locked = true
	player.facing = signf(tf.global_position.x - player.global_position.x)
	tf.rig.facing = -player.facing
	for r in tf.extra_rigs:
		r.facing = -player.facing
	var sp := {tf.display_name: tf.rig}
	if tf.id == "twins":
		sp = {"Pim": tf.rig, "Posy": tf.extra_rigs[0]}
	await _say(tf.repeat_line, sp)
	player.control_locked = false

func _unhandled_input(e: InputEvent) -> void:
	if state != "play" or cutscene or ui.overlay_open != "":
		return
	if e.is_action_pressed("pause"):
		ui.open_overlay("pause")
	elif e.is_action_pressed("journal"):
		ui.open_overlay("journal")


# ================================================================ noise + lights (chapter 3 listeners)
func noise(pos: Vector2, radius: float) -> void:
	for h in get_tree().get_nodes_in_group("hush"):
		if h.has_method("hear"):
			h.hear(pos, radius)

func add_light(src, radius: float, k := 1.0, off := Vector2.ZERO) -> void:
	lights.append({"src": src, "r": radius, "k": k, "off": off})

func add_moving(kind: String, pos: Vector2, w: float, axis: Vector2, amp: float, speed: float, phase := 0.0) -> LevelObjects.Mover:
	var m := LevelObjects.Mover.new()
	m.kind = kind
	m.w = w
	m.axis = axis
	m.amp = amp
	m.speed = speed
	m.phase = phase
	m.position = pos
	geo.add_child(m)
	return m

func finish_game(which: String) -> void:
	if ending: return
	ending=true
	boss_done=true
	state="finale"
	player.wind_push=0
	for h in get_tree().get_nodes_in_group("hush"): h.dissolve_now()
	for w in get_tree().get_nodes_in_group("boss_wave"): w.queue_free()
	var f:=HushFinale.new()
	f.main=self
	f.ending=which
	add_child(f)
