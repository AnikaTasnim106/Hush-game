class_name BossBell
extends Node2D
## Mini-boss: THE MUTE BELL. The town's great bell, smothered by the Hush.
## Pattern: track Wren -> wind up -> SLAM (silence waves along the floor) -> dazed (clapper exposed).
## Ring the clapper 3 times per phase. 3 phases.

signal defeated
signal phase_changed(p)
signal damaged(frac)

const HITS_PER_PHASE := 3
const HITS_PER_DAZE := 3
var daze_hits := 0
var chain := 0

var arena_x0 := 0.0
var arena_x1 := 0.0
var beam_y := -560.0
var state := "dormant"
var st := 0.0
var phase := 0
var hits := 0
var bottom_y := -330.0       # y of the bell's mouth (world)
var x := 0.0
var tilt := 0.0
var shake := 0.0
var fog := 1.0
var t := 0.0
var flash := 0.0
var clap_flash := 0.0
var slams_left := 0

const W := 210.0
const H := 230.0

var home_x := 0.0

func _ready() -> void:
	add_to_group("hittable")
	add_to_group("hazard")
	x = global_position.x
	home_x = x
	bottom_y = -330.0

func reset() -> void:
	state = "dormant"
	st = 0.0
	hits = 0
	daze_hits = 0
	chain = 0
	tilt = 0.0
	slams_left = 0
	x = home_x
	bottom_y = -330.0

func start_fight() -> void:
	if state != "dormant":
		return
	_go("intro")
	Sfx.play("boss_clang", 0.0)

func _go(s: String) -> void:
	state = s
	st = 0.0
	if s == "dazed":
		daze_hits = 0

func _p() -> Player:
	return get_tree().get_first_node_in_group("player")

func _speed() -> float:
	return [190.0, 240.0, 290.0][clampi(phase, 0, 2)]

func _process(delta: float) -> void:
	t += delta
	st += delta
	flash = move_toward(flash, 0.0, delta * 5.0)
	clap_flash = move_toward(clap_flash, 0.0, delta * 4.0)
	shake = move_toward(shake, 0.0, delta * 3.0)
	var p := _p()
	match state:
		"dormant":
			bottom_y = -330.0 + sin(t * 1.2) * 6.0
		"intro":
			shake = 1.0
			if st > 2.2:
				_go("track")
		"track":
			var tx := clampf(p.global_position.x if p else x, arena_x0 + W * 0.6, arena_x1 - W * 0.6)
			x = move_toward(x, tx, _speed() * delta)
			bottom_y = move_toward(bottom_y, -330.0, 300.0 * delta)
			var dur: float = [1.9, 1.6, 1.3][clampi(phase, 0, 2)]
			if st > dur:
				_go("windup")
				Sfx.play("whoosh", -2.0, 0.5)
		"windup":
			bottom_y = move_toward(bottom_y, -380.0, 200.0 * delta)
			shake = 0.6
			if st > 0.75:
				_go("slam")
		"slam":
			bottom_y = move_toward(bottom_y, 0.0, 3200.0 * delta)
			if bottom_y >= 0.0:
				_impact()
		"dazed":
			if st < delta * 1.5:
				var mn := get_tree().get_first_node_in_group("main")
				if mn:
					mn.ui.hint("It's dazed! Ring the glowing clapper!", 2.5)
			bottom_y = move_toward(bottom_y, -120.0, 420.0 * delta)
			tilt = sin(st * 3.0) * 0.08
			var daze: float = [3.2, 2.8, 2.4][clampi(phase, 0, 2)]
			if slams_left > 0 and st > 0.5:
				slams_left -= 1
				_go("windup")
			elif st > daze:
				tilt = 0.0
				_go("track")
		"stagger":
			bottom_y = move_toward(bottom_y, -420.0, 500.0 * delta)
			shake = 0.8
			if st > 1.4:
				phase += 1
				hits = 0
				phase_changed.emit(phase)
				if phase >= 3:
					_go("freed")
					Sfx.play("bell_free", 0.0)
					defeated.emit()
				else:
					fog = 1.0 - phase * 0.3
					var main := get_tree().get_first_node_in_group("main")
					if main and phase == 2:
						for i in 1:
							main.spawn_hush("ling", Vector2(lerpf(arena_x0 + 150, arena_x1 - 150, randf()), -140.0), 120.0)
					Sfx.play("boss_clang", -3.0, 1.0 + phase * 0.1)
					_go("track")
		"freed":
			fog = move_toward(fog, 0.0, delta * 0.6)
			x = move_toward(x, (arena_x0 + arena_x1) * 0.5, 120.0 * delta)
			bottom_y = move_toward(bottom_y, -300.0, 120.0 * delta)
			tilt = sin(t * 2.2) * 0.12 * maxf(0.0, 1.0 - st / 4.0)
			if int(t * 10) % 3 == 0 and fog > 0.05:
				Fx.wisps(Vector2(x + randf_range(-90, 90), bottom_y - randf_range(40, 200)), 3)
	global_position = Vector2(x + (sin(t * 60.0) * 4.0 * shake), 0)
	queue_redraw()

func _impact() -> void:
	bottom_y = 0.0
	Sfx.play("boss_slam", 0.0)
	Sfx.play("boss_wave", -4.0)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(16.0)
	Fx.dust(Vector2(x - 90, 0), 10, 1.6)
	Fx.dust(Vector2(x + 90, 0), 10, 1.6)
	var waves := 2 if phase == 2 else 1
	for i in waves:
		for d in [-1.0, 1.0]:
			var w := Wave.new()
			w.dir = d
			w.speed = 320.0 + phase * 25.0
			w.delay = i * 0.8
			w.x0 = arena_x0
			w.x1 = arena_x1
			w.global_position = Vector2(x + d * W * 0.5, 0)
			get_parent().add_child(w)
	var p := _p()
	if p and absf(p.global_position.x - x) < W * 0.5 and p.global_position.y > -140.0:
		p.take_damage(Vector2(x, 0))
	if phase == 2:
		if chain == 0:
			chain = 1
			slams_left = 1
		else:
			chain = 0
			slams_left = 0
	_go("dazed")

func hurt_rect() -> Rect2:
	if state == "dazed" or state == "track" or state == "windup" or state == "dormant":
		return Rect2(Vector2(x - W * 0.5, bottom_y - H), Vector2(W, H + 70))
	return Rect2()

func _clapper_pos() -> Vector2:
	return Vector2(x, bottom_y + 34).rotated(0)

func take_hit(_dmg: int, _from: Vector2, _how: String) -> bool:
	if state == "dazed":
		var c := _clapper_pos()
		var pl := _p()
		# only the exposed clapper counts (it hangs low enough to reach from the ground)
		if pl and absf(pl.global_position.x - c.x) < 130.0 and daze_hits < HITS_PER_DAZE:
			hits += 1
			daze_hits += 1
			flash = 1.0
			clap_flash = 1.0
			Sfx.play("boss_clang", -6.0, 1.4 + hits * 0.12)
			Fx.ring(c, 1.4)
			damaged.emit(1.0 - float(phase * HITS_PER_PHASE + hits) / float(3 * HITS_PER_PHASE))
			if hits >= HITS_PER_PHASE:
				slams_left = 0
				_go("stagger")
				Fx.wisps(Vector2(x, bottom_y - 120), 20)
			elif daze_hits >= HITS_PER_DAZE:
				# shakes itself awake early
				shake = 1.0
				st = 99.0 if slams_left == 0 else st
				Fx.wisps(Vector2(x, bottom_y - 80), 8)
			return true
	# armoured: a dull clank
	if state != "freed" and state != "stagger" and state != "intro":
		Sfx.play("hush_hit", -8.0, 0.6)
		flash = 0.4
		return true
	return false

func hazard_rect() -> Rect2:
	if state == "slam":
		return Rect2(Vector2(x - W * 0.45, bottom_y - H), Vector2(W * 0.9, H))
	return Rect2()

func _draw() -> void:
	var ink := Color("1d1a22")
	var off := Vector2(0, 0)
	var top := Vector2(0, bottom_y - H)
	# rope / chain to beam
	var segs := 14
	for i in segs:
		var a := Vector2(0, beam_y).lerp(top + Vector2(0, -26), float(i) / segs)
		var b := Vector2(0, beam_y).lerp(top + Vector2(0, -26), float(i + 1) / segs)
		draw_line(a, b, ink, 7.0)
		draw_line(a, b, Color("7a6a58"), 3.0)
	draw_set_transform(Vector2(0, bottom_y), tilt, Vector2.ONE)
	# bell body (local: mouth at y=0)
	var body: PackedVector2Array = []
	var n := 24
	for i in n + 1:
		var k := float(i) / n
		var y := -H * k
		var wk := 0.5 * W * (1.0 - 0.55 * pow(k, 0.8))
		if k < 0.08:
			wk += 10.0 * (1.0 - k / 0.08)
		body.append(Vector2(wk, y))
	for i in range(n, -1, -1):
		var k := float(i) / n
		var y := -H * k
		var wk := 0.5 * W * (1.0 - 0.55 * pow(k, 0.8))
		if k < 0.08:
			wk += 10.0 * (1.0 - k / 0.08)
		body.append(Vector2(-wk, y))
	var bronze := Color("b8863a").lerp(Color.WHITE, flash * 0.6)
	draw_colored_polygon(body, bronze)
	var cl := body.duplicate(); cl.append(body[0])
	draw_polyline(cl, ink, 5.0, true)
	# bands and shine
	draw_line(Vector2(-W * 0.5 + 6, -16), Vector2(W * 0.5 - 6, -16), Color("8a5f25"), 6.0)
	draw_line(Vector2(-W * 0.36, -H * 0.62), Vector2(W * 0.36, -H * 0.62), Color("8a5f25"), 5.0)
	draw_line(Vector2(-W * 0.28, -H * 0.9), Vector2(-W * 0.42, -30), Color(1.0, 0.9, 0.6, 0.45), 8.0, true)
	# crown loop
	draw_arc(Vector2(0, -H - 10), 18, PI, TAU, 12, ink, 9.0, true)
	draw_arc(Vector2(0, -H - 10), 18, PI, TAU, 12, Color("8a5f25"), 5.0, true)
	# clapper
	var clap := Vector2(sin(t * 2.0) * 6.0, 34)
	draw_line(Vector2(0, -40), clap, ink, 7.0)
	var cc := Color("6a4a2a").lerp(Color(1.0, 0.9, 0.5), clap_flash)
	if state == "dazed":
		for i in 3:
			draw_circle(clap, 26 + i * 12 + sin(t * 6.0) * 3.0, Color(1.0, 0.85, 0.45, 0.14))
	draw_circle(clap, 20, ink)
	draw_circle(clap, 16, cc)
	# hush fog wrapped around the bell, with hollow eyes
	if fog > 0.02:
		for i in 18:
			var a := float(i) / 18.0 * TAU + t * 0.4
			var pr := Vector2(cos(a) * W * 0.45, -H * 0.5 + sin(a) * H * 0.42)
			draw_circle(pr, 34.0 + sin(t * 2.0 + i) * 6.0, Color(0.93, 0.95, 1.0, 0.42 * fog))
		var eye := Color(0.2, 0.24, 0.34, fog)
		var glow := Color(0.5, 0.85, 1.0, 0.6 * fog)
		for s in [-1.0, 1.0]:
			var e := Vector2(s * 36.0, -H * 0.56)
			draw_circle(e, 22, Color(0.93, 0.95, 1.0, 0.8 * fog))
			draw_colored_polygon(_oval(e, 11, 16), eye)
			if state in ["track", "windup", "slam", "intro"]:
				draw_circle(e + Vector2(0, 3), 4, glow)
		# pressed lips and a "shh" finger
		var fc := Color(0.93, 0.95, 1.0, 0.95 * fog)
		draw_arc(Vector2(0, -H * 0.27), 22.0, 0.25, PI - 0.25, 10, Color(0.2, 0.24, 0.34, 0.8 * fog), 4.0, true)
		draw_line(Vector2(6, -H * 0.12), Vector2(4, -H * 0.36), Color(0.55, 0.62, 0.78, 0.9 * fog), 15.0, true)
		draw_line(Vector2(6, -H * 0.12), Vector2(4, -H * 0.36), fc, 11.0, true)
		draw_circle(Vector2(4, -H * 0.36), 6.0, fc)
	if state == "dazed":
		for i in 3:
			var a := t * 4.0 + i * TAU / 3.0
			Fx.note_shape(self, Vector2(cos(a) * 70.0, -H - 30 + sin(a) * 14.0), 0.9, Color(1.0, 0.85, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# telegraph shadow on the floor
	if state == "track" or state == "windup" or state == "slam":
		var k := clampf(1.0 - (-bottom_y) / 420.0, 0.2, 1.0)
		draw_colored_polygon(_oval(Vector2(0, -2), W * 0.5 * k + 10, 10), Color(0.1, 0.1, 0.15, 0.35 + 0.3 * k))

func _oval(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

class Wave extends Node2D:
	var dir := 1.0
	var speed := 430.0
	var delay := 0.0
	var life := 0.0
	var x0 := 0.0
	var x1 := 0.0
	func _ready() -> void:
		add_to_group("hazard")
		add_to_group("boss_wave")
	func hazard_rect() -> Rect2:
		if delay > 0.0:
			return Rect2()
		return Rect2(global_position + Vector2(-18, -34), Vector2(36, 34))
	func _process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			visible = false
			return
		visible = true
		life += delta
		global_position.x += dir * speed * delta
		if global_position.x < x0 - 40 or global_position.x > x1 + 40 or life > 4.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var c := Color(0.93, 0.95, 1.0, 0.9)
		for i in 3:
			var r := 44.0 - i * 10.0
			draw_arc(Vector2(-dir * i * 10.0, 0), r, PI if dir > 0 else -PI * 0.0 + PI, TAU if dir > 0 else TAU, 12, Color(c, 0.9 - i * 0.25), 6.0 - i, true)
		draw_arc(Vector2(0, 0), 44.0, PI + (0.0 if dir > 0 else 0.0), TAU, 14, Color(0.55, 0.62, 0.78, 0.9), 2.5, true)
