class_name Hush
extends Node2D
## A Hush: a creature made of silence. Sound shatters it into notes.
## kind "ling": floats along a patrol line, drifts toward Wren when close.
## kind "wing": a moth-like hush that circles, then swoops at Wren.

var kind := "ling"
var hp := 2
var home := Vector2.ZERO
var patrol := 120.0
var t := 0.0
var dir := 1.0
var vel := Vector2.ZERO
var flash := 0.0
var knock := Vector2.ZERO
var dying := -1.0
var swoop := -1.0
var swoop_from := Vector2.ZERO
var swoop_to := Vector2.ZERO
var cooldown := 1.5
var alert := 0.0
var size := 1.0
var drop_notes := 3
var silent_gfx := false

func _ready() -> void:
	add_to_group("hittable")
	add_to_group("hazard")
	add_to_group("hush")
	home = global_position
	t = randf() * 10.0
	if kind == "wing":
		hp = 2
		drop_notes = 4
	if kind == "listener":
		hp = 2
		drop_notes = 3
		size = 1.15

func hurt_rect() -> Rect2:
	var s := Vector2(52, 52) * size if kind == "ling" else Vector2(62, 40) * size
	return Rect2(global_position - s * 0.5, s)

var awake := 0.0          # listener: >0 while awake (seconds left)
var heard_at := Vector2.ZERO

func hear(pos: Vector2, radius: float) -> void:
	if kind != "listener" or dying >= 0.0:
		return
	if global_position.distance_to(pos) < radius:
		if awake <= 0.0:
			Sfx.play_var("hush_hit", -10.0, 0.5)
			Fx.text(global_position + Vector2(0, -40), "!", Color(0.7, 0.9, 1.0))
		awake = 4.5
		heard_at = pos

func hazard_rect() -> Rect2:
	if dying >= 0.0:
		return Rect2()
	if kind == "listener" and awake <= 0.0:
		return Rect2()
	var s := Vector2(36, 36) * size if kind == "ling" else Vector2(44, 28) * size
	return Rect2(global_position - s * 0.5, s)

func take_hit(dmg: int, from: Vector2, _how: String) -> bool:
	if dying >= 0.0:
		return false
	hp -= dmg
	flash = 1.0
	var d := signf(global_position.x - from.x)
	knock = Vector2(d * 420.0, -160.0)
	swoop = -1.0
	Sfx.play_var("hush_hit", -4.0)
	if hp <= 0:
		_die()
	return true

func _die() -> void:
	dying = 0.0
	remove_from_group("hazard")
	remove_from_group("hittable")
	Sfx.play_var("dissolve", -3.0)
	Fx.wisps(global_position, 12)
	Fx.notes_burst(global_position, 5)
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_notes"):
		main.spawn_notes(global_position, drop_notes)

func dissolve_now() -> void:
	if dying < 0.0:
		_die()

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	t += delta
	flash = move_toward(flash, 0.0, delta * 5.0)
	if dying >= 0.0:
		dying += delta
		modulate.a = 1.0 - dying / 0.35
		scale = Vector2.ONE * (1.0 + dying * 1.5)
		if dying > 0.35:
			queue_free()
		return
	var p := _player()
	# knockback
	if knock.length() > 1.0:
		global_position += knock * delta
		knock = knock.move_toward(Vector2.ZERO, 1600.0 * delta)
	if kind == "ling":
		_ling(delta, p)
	elif kind == "listener":
		_listener(delta, p)
	else:
		_wing(delta, p)
	queue_redraw()

func _listener(delta: float, p: Node2D) -> void:
	if awake > 0.0:
		awake -= delta
		alert = 1.0
		var target := heard_at + Vector2(0, -20)
		if p and p.global_position.distance_to(global_position) < 240.0:
			target = p.global_position + Vector2(0, -10)
		global_position = global_position.move_toward(target, 165.0 * delta)
		if absf(target.x - global_position.x) > 2.0:
			dir = signf(target.x - global_position.x)
		if awake <= 0.0:
			home = global_position
	else:
		alert = 0.0
		global_position = global_position.move_toward(home + Vector2(0, sin(t * 1.2) * 6.0), 30.0 * delta)

func _ling(delta: float, p: Node2D) -> void:
	var target := home + Vector2(sin(t * 0.9) * patrol, sin(t * 2.1) * 8.0)
	alert = move_toward(alert, 0.0, delta)
	if p:
		var d := p.global_position + Vector2(0, -10) - global_position
		if d.length() < 260.0 and absf(p.global_position.x - home.x) < patrol + 220.0:
			alert = 1.0
			target = global_position + d.normalized() * 60.0
	var sp := 95.0 if alert > 0.5 else 60.0
	global_position = global_position.move_toward(target, sp * delta)
	if absf(target.x - global_position.x) > 2.0:
		dir = signf(target.x - global_position.x)

func _wing(delta: float, p: Node2D) -> void:
	cooldown -= delta
	if swoop >= 0.0:
		swoop += delta / 0.9
		var k := clampf(swoop, 0.0, 1.0)
		var mid := (swoop_from + swoop_to) * 0.5 + Vector2(0, 120)
		var a := swoop_from.lerp(mid, k)
		var b := mid.lerp(swoop_to, k)
		global_position = a.lerp(b, k)
		dir = signf(swoop_to.x - swoop_from.x)
		if swoop >= 1.0:
			swoop = -1.0
			cooldown = randf_range(1.6, 2.4)
		return
	var hover := home + Vector2(sin(t * 0.7) * patrol, sin(t * 1.7) * 30.0)
	global_position = global_position.move_toward(hover, 120.0 * delta)
	if p:
		var d := p.global_position - global_position
		dir = signf(d.x) if absf(d.x) > 4.0 else dir
		if cooldown <= 0.0 and d.length() < 420.0 and d.y > 40.0:
			swoop = 0.0
			swoop_from = global_position
			swoop_to = p.global_position + Vector2(d.x * 0.9, -150.0)
			alert = 1.0

func _draw() -> void:
	var body := Color(0.93, 0.95, 1.0, 0.96).lerp(Color.WHITE, flash)
	var line := Color(0.62, 0.68, 0.8, 0.9)
	var eye := Color(0.26, 0.3, 0.42).lerp(Color(0.45, 0.85, 1.0), alert * 0.6)
	if kind == "listener":
		_draw_listener(body, line, eye)
		return
	if kind == "ling":
		var s := size
		var pts: PackedVector2Array = []
		var n := 22
		for i in n:
			var a := TAU * i / n
			var rr := 24.0 * s
			if a > 0.35 and a < PI - 0.35:   # lower half: wavy wispy tail
				rr += 8.0 * s + sin(a * 6.0 + t * 7.0) * 5.0 * s
			else:
				rr += sin(a * 3.0 + t * 2.0) * 1.5 * s
			pts.append(Vector2(cos(a) * rr * 1.05, sin(a) * rr))
		# glow
		draw_circle(Vector2.ZERO, 38 * s, Color(0.85, 0.9, 1.0, 0.12))
		draw_colored_polygon(pts, body)
		var cl := pts.duplicate(); cl.append(pts[0])
		draw_polyline(cl, line, 2.5, true)
		# hollow eyes
		var ex := dir * 5.0 * s
		draw_colored_polygon(_oval(Vector2(ex - 8 * s, -4 * s), 4.0 * s, 6.5 * s), eye)
		draw_colored_polygon(_oval(Vector2(ex + 8 * s, -4 * s), 4.0 * s, 6.5 * s), eye)
		# "shh" finger wisp
		var hand := Vector2(ex + 1 * s, 9 * s)
		draw_line(hand + Vector2(-10 * s, 10 * s), hand, line, 4.5, true)
		draw_line(hand, hand + Vector2(0, -9 * s), line, 3.5, true)
	else:
		var s := size
		var flap := sin(t * 14.0) * 0.6
		for side in [-1.0, 1.0]:
			var w: PackedVector2Array = [
				Vector2(0, -2) * s,
				Vector2(side * 40, -18 + flap * 22 * side * side) * s,
				Vector2(side * 46, 2 + flap * 10) * s,
				Vector2(side * 16, 10) * s,
			]
			draw_colored_polygon(w, Color(body, 0.85))
			var wl := w.duplicate(); wl.append(w[0])
			draw_polyline(wl, line, 2.0, true)
		var core := _oval(Vector2.ZERO, 16 * s, 13 * s)
		draw_colored_polygon(core, body)
		var cc := core.duplicate(); cc.append(core[0])
		draw_polyline(cc, line, 2.0, true)
		var tail: PackedVector2Array = []
		for i in 6:
			tail.append(Vector2(-dir * i * 7.0, 10.0 + i * 3.0 + sin(t * 8.0 + i) * 3.0) * s)
		draw_polyline(tail, Color(body, 0.8), 5.0, true)
		draw_colored_polygon(_oval(Vector2(dir * 5 - 5, -2) * s, 3.0 * s, 5.0 * s), eye)
		draw_colored_polygon(_oval(Vector2(dir * 5 + 5, -2) * s, 3.0 * s, 5.0 * s), eye)

func _draw_listener(body: Color, line: Color, eye: Color) -> void:
	var s := size
	var sleeping := awake <= 0.0
	var b := Color(body, 0.75 if sleeping else 0.96)
	draw_circle(Vector2.ZERO, 44 * s, Color(0.8, 0.88, 1.0, 0.08 if sleeping else 0.16))
	# big ear-like wisps that twitch toward sound
	for sd in [-1.0, 1.0]:
		var tw := sin(t * (2.0 if sleeping else 9.0) + sd) * (2.0 if sleeping else 6.0)
		var ear: PackedVector2Array = [Vector2(sd * 10, -16) * s, Vector2(sd * 34 + tw, -44) * s, Vector2(sd * 24, -8) * s]
		draw_colored_polygon(ear, b)
		var el := ear.duplicate(); el.append(ear[0])
		draw_polyline(el, line, 2.0, true)
	var pts: PackedVector2Array = []
	for i in 22:
		var a := TAU * i / 22.0
		var rr := 25.0 * s
		if a > 0.35 and a < PI - 0.35:
			rr += 7.0 * s + sin(a * 5.0 + t * 4.0) * 4.0 * s
		pts.append(Vector2(cos(a) * rr * 1.1, sin(a) * rr * 0.95))
	draw_colored_polygon(pts, b)
	var cl := pts.duplicate(); cl.append(pts[0])
	draw_polyline(cl, line, 2.5, true)
	if sleeping:
		for sd in [-1.0, 1.0]:
			draw_arc(Vector2(sd * 9, -4) * s, 5.0 * s, 0.2, PI - 0.2, 8, eye, 2.5, true)
		# floating "z"-like hush mark
		var zp := Vector2(18, -40 - fmod(t * 10.0, 20.0)) * s
		draw_line(zp, zp + Vector2(8, 0), Color(line, 0.7), 2.0)
		draw_line(zp + Vector2(8, 0), zp + Vector2(0, 8), Color(line, 0.7), 2.0)
		draw_line(zp + Vector2(0, 8), zp + Vector2(8, 8), Color(line, 0.7), 2.0)
	else:
		draw_colored_polygon(_oval(Vector2(dir * 4 - 9, -4) * s, 4.5 * s, 7.0 * s), eye)
		draw_colored_polygon(_oval(Vector2(dir * 4 + 9, -4) * s, 4.5 * s, 7.0 * s), eye)
		draw_arc(Vector2(dir * 4, 10) * s, 6.0 * s, 0.0, TAU, 12, line, 2.5, true)

func _oval(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
