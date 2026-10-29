class_name OrganFinale
extends Node2D
## Chapter 3 finale: THE HOLLOW ORGAN. The hall's great organ, choked with silence.
## Three bell-stops around the loft. One glows at a time: ring it 3 times.
## Meanwhile the organ drops silence columns where Wren stands and breathes out Hush.
## Same interface as BossBell (start_fight, reset, signals, state, phase).

signal defeated
signal phase_changed(p)
signal damaged(frac)

const HITS_PER_STOP := 3

var arena_x0 := 0.0
var arena_x1 := 0.0
var stops: Array[Vector2] = []    # world positions (feet of each stop stand)
var state := "dormant"            # dormant intro fight calm freed
var st := 0.0
var phase := 0
var hits := 0
var fog := 1.0
var t := 0.0
var col_t := 2.0
var spawn_t := 3.0
var flash := 0.0
var x := 0.0

func _ready() -> void:
	add_to_group("hittable")
	x = global_position.x

func start_fight() -> void:
	if state != "dormant":
		return
	_go("intro")
	Sfx.play("boss_clang", -2.0, 0.6)

func reset() -> void:
	state = "dormant"
	st = 0.0
	hits = 0
	for c in get_tree().get_nodes_in_group("boss_wave"):
		c.queue_free()

func _go(s: String) -> void:
	state = s
	st = 0.0

func _p() -> Player:
	return get_tree().get_first_node_in_group("player")

func active_stop() -> Vector2:
	return stops[clampi(phase, 0, stops.size() - 1)]

func hurt_rect() -> Rect2:
	if state != "fight":
		return Rect2()
	var s := active_stop()
	return Rect2(s + Vector2(-34, -120), Vector2(68, 120))

func take_hit(_dmg: int, _from: Vector2, _how: String) -> bool:
	if state != "fight":
		return false
	hits += 1
	flash = 1.0
	Sfx.play("strike2", -2.0, 0.8 + hits * 0.12)
	Fx.ring(active_stop() + Vector2(0, -80), 1.6)
	damaged.emit(1.0 - float(phase * HITS_PER_STOP + hits) / float(3 * HITS_PER_STOP))
	if hits >= HITS_PER_STOP:
		_stop_rung()
	return true

func _stop_rung() -> void:
	hits = 0
	phase += 1
	Sfx.play("bell_free", -3.0, 0.7 + phase * 0.12)
	Fx.ring(Vector2(x, -300), 6.0, Color(1.0, 0.9, 0.6), 1.4)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(10.0)
	for h in get_tree().get_nodes_in_group("hush"):
		h.dissolve_now()
	for c in get_tree().get_nodes_in_group("boss_wave"):
		c.queue_free()
	fog = 1.0 - phase * 0.3
	phase_changed.emit(phase)
	if phase >= 3:
		_go("freed")
		defeated.emit()
	else:
		_go("calm")

func _process(delta: float) -> void:
	t += delta
	st += delta
	flash = move_toward(flash, 0.0, delta * 4.0)
	match state:
		"intro":
			if st > 2.0:
				_go("fight")
				col_t = 2.0
				spawn_t = 2.5
		"calm":
			if st > 1.8:
				_go("fight")
				col_t = 1.6
				var main := get_tree().get_first_node_in_group("main")
				if main:
					main.ui.hint("Another bell-stop is glowing. Climb up and ring it!", 4.0)
		"fight":
			var p := _p()
			col_t -= delta
			spawn_t -= delta
			var col_every: float = [3.4, 2.8, 2.3][clampi(phase, 0, 2)]
			if col_t <= 0.0 and p:
				col_t = col_every
				_column(p.global_position.x)
				if phase == 2 and randf() < 0.5:
					_column(clampf(p.global_position.x + randf_range(-360, 360), arena_x0 + 80, arena_x1 - 80))
			if spawn_t <= 0.0:
				spawn_t = [5.0, 4.5, 4.0][clampi(phase, 0, 2)]
				if get_tree().get_nodes_in_group("hush").size() < 1 + phase:
					var main := get_tree().get_first_node_in_group("main")
					if main:
						var kind := "ling"
						var h: Hush = main.spawn_hush(kind, Vector2(lerpf(arena_x0 + 160, arena_x1 - 160, randf()), -320.0), 90.0)
						Fx.wisps(h.global_position, 10)
		"freed":
			fog = move_toward(fog, 0.0, delta * 0.5)
	queue_redraw()

func _column(cx: float) -> void:
	var c := Column.new()
	c.global_position = Vector2(cx, 0)
	get_parent().add_child(c)

func _draw() -> void:
	var ink := Color("1d1a22")
	var lx := arena_x0 - x + 120.0
	var rx := arena_x1 - x - 120.0
	# pipes
	var n := 15
	for i in n:
		var k := float(i) / (n - 1)
		var px := lerpf(lx + 120, rx - 120, k)
		var h := 380.0 + sin(k * PI) * 320.0
		var w := 34.0
		var r := Rect2(px - w * 0.5, -h - 140, w, h)
		draw_rect(r, Color("b8863a").darkened(0.1 + (i % 2) * 0.1))
		draw_rect(r, ink, false, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(px - w * 0.5, -h - 140), Vector2(px + w * 0.5, -h - 140), Vector2(px, -h - 160)]), Color("8a5f25"))
		draw_rect(Rect2(px - 8, -190, 16, 10), ink)
		if fog > 0.05:
			draw_circle(Vector2(px, -h - 150 + sin(t * 1.5 + i) * 8.0), 26, Color(0.93, 0.95, 1.0, 0.25 * fog))
	# console
	draw_rect(Rect2(-130, -140, 260, 140), Color("5e3d33"))
	draw_rect(Rect2(-130, -140, 260, 140), ink, false, 3.0)
	for i in 3:
		draw_rect(Rect2(-110, -126 + i * 18, 220, 10), Color("f2ece0"))
	# hollow eyes in the fog over the pipes
	if fog > 0.05:
		for s in [-1.0, 1.0]:
			var e := Vector2(s * 70.0, -560.0)
			draw_circle(e, 40, Color(0.93, 0.95, 1.0, 0.6 * fog))
			draw_colored_polygon(_oval(e, 16, 24), Color(0.2, 0.24, 0.34, fog))
	# stops
	for i in stops.size():
		var sp: Vector2 = stops[i] - Vector2(x, 0)
		var done := i < phase
		var active := i == phase and state == "fight"
		draw_line(sp, sp + Vector2(0, -60), ink, 8.0)
		draw_line(sp, sp + Vector2(0, -60), Color("6b4b30"), 4.0)
		var c := sp + Vector2(0, -84)
		if active:
			for k in 3:
				draw_circle(c, 30 + k * 14 + sin(t * 5.0) * 3.0, Color(1.0, 0.85, 0.45, 0.14))
			# bouncing arrow + label so it's obvious what to hit
			var ay := -150.0 - absf(sin(t * 4.0)) * 18.0
			var ap := sp + Vector2(0, ay)
			draw_colored_polygon(PackedVector2Array([ap + Vector2(-18, -20), ap + Vector2(18, -20), ap + Vector2(0, 6)]), Color(1.0, 0.85, 0.4))
			draw_polyline(PackedVector2Array([ap + Vector2(-18, -20), ap + Vector2(18, -20), ap + Vector2(0, 6), ap + Vector2(-18, -20)]), ink, 3.0, true)
			var f := ThemeDB.fallback_font
			draw_string_outline(f, ap + Vector2(-60, -30), "RING ME  %d/3" % hits, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, 6, Color(0, 0, 0, 0.8))
			draw_string(f, ap + Vector2(-60, -30), "RING ME  %d/3" % hits, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color(1.0, 0.92, 0.6))
		var bc := Color("d9a441") if (done or active) else Color("8b8f98")
		bc = bc.lerp(Color.WHITE, flash if active else 0.0)
		var pts := PackedVector2Array([c + Vector2(-8, -18), c + Vector2(8, -18), c + Vector2(20, 14), c + Vector2(-20, 14)])
		draw_colored_polygon(pts, bc)
		var cl := pts.duplicate(); cl.append(pts[0])
		draw_polyline(cl, ink, 3.0, true)
		draw_circle(c + Vector2(0, 18), 5, ink)
		if active:
			for k in hits:
				draw_circle(c + Vector2(-14 + k * 14, -34), 4, Color(1.0, 0.9, 0.5))

func _oval(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

class Column extends Node2D:
	## Telegraphed falling column of silence.
	var t := 0.0
	const WARN := 1.15
	const HIT := 0.55
	func _ready() -> void:
		add_to_group("hazard")
		add_to_group("boss_wave")
	func hazard_rect() -> Rect2:
		if t < WARN or t > WARN + HIT:
			return Rect2()
		return Rect2(global_position + Vector2(-26, -900), Vector2(52, 900))
	func _process(delta: float) -> void:
		var before := t
		t += delta
		if before < WARN and t >= WARN:
			Sfx.play("boss_wave", -6.0, 1.3)
		if t > WARN + HIT + 0.3:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		if t < WARN:
			var k := t / WARN
			draw_rect(Rect2(-36, -6, 72, 6), Color(0.9, 0.93, 1.0, 0.3 + 0.5 * k))
			draw_rect(Rect2(-36 * k, -900, 72 * k, 900), Color(0.9, 0.93, 1.0, 0.08))
		else:
			var a := clampf(1.0 - (t - WARN - HIT) / 0.3, 0.0, 1.0)
			draw_rect(Rect2(-36, -900, 72, 900), Color(0.93, 0.95, 1.0, 0.75 * a))
			draw_rect(Rect2(-36, -900, 72, 900), Color(0.55, 0.62, 0.78, a), false, 3.0)
