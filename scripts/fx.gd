class_name Fx
extends Node2D
## Lightweight one-shot effects drawn with _draw. Spawn through the static helpers.

static var layer: Node = null   # set by Main to the hero canvas layer

var kind := ""
var t := 0.0
var life := 0.5
var dir := 1.0
var size := 1.0
var col := Color.WHITE
var parts := []

static func _spawn(k: String, pos: Vector2, l: float) -> Fx:
	var f := Fx.new()
	f.kind = k
	f.life = l
	f.global_position = pos
	if layer:
		layer.add_child(f)
	return f

static func ring(pos: Vector2, s := 1.0, c := Color(1.0, 0.86, 0.45), l := 0.45) -> void:
	var f := _spawn("ring", pos, l)
	if f: f.size = s; f.col = c

static func arc(pos: Vector2, facing: float, s := 1.0) -> void:
	# sound-wave arcs fanning out from the bell
	var f := _spawn("arc", pos, 0.38)
	if f: f.dir = facing; f.size = s

static func dust(pos: Vector2, n := 6, s := 1.0) -> void:
	var f := _spawn("dust", pos, 0.5)
	if f:
		f.size = s
		for i in n:
			f.parts.append([Vector2(randf_range(-8, 8), 0), Vector2(randf_range(-110, 110), randf_range(-80, -10)), randf_range(4, 8) * s])

static func shards(pos: Vector2, n := 18, c := Color(0.9, 0.93, 1.0)) -> void:
	var f := _spawn("shards", pos, 1.2)
	if f:
		f.col = c
		for i in n:
			var a := randf() * TAU
			var sp := randf_range(180, 520)
			f.parts.append([Vector2(randf_range(-30, 30), randf_range(-60, 20)), Vector2(cos(a), sin(a) - 0.6) * sp, randf_range(5, 13), randf() * TAU, randf_range(-12, 12)])

static func notes_burst(pos: Vector2, n := 6) -> void:
	var f := _spawn("notes", pos, 1.1)
	if f:
		for i in n:
			f.parts.append([Vector2(randf_range(-20, 20), randf_range(-20, 10)), Vector2(randf_range(-90, 90), randf_range(-220, -90)), randf_range(0.8, 1.3), randf() * 2.0 - 1.0])

static func wisps(pos: Vector2, n := 10) -> void:
	var f := _spawn("wisps", pos, 0.9)
	if f:
		for i in n:
			f.parts.append([Vector2(randf_range(-26, 26), randf_range(-26, 26)), Vector2(randf_range(-70, 70), randf_range(-150, -40)), randf_range(6, 14)])

static func text(pos: Vector2, s: String, c := Color(1, 0.95, 0.8)) -> void:
	var f := _spawn("text", pos, 1.2)
	if f:
		f.col = c
		f.set_meta("s", s)

func _process(delta: float) -> void:
	t += delta
	for p in parts:
		p[0] += p[1] * delta
		if kind == "shards":
			p[1].y += 1300.0 * delta
			p[3] += p[4] * delta
		elif kind == "dust":
			p[1] *= 0.9
		elif kind == "notes":
			p[1].x *= 0.97
			p[1].y += 120.0 * delta
	if t >= life:
		queue_free()
		return
	queue_redraw()

static func note_shape(node: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	node.draw_circle(c + Vector2(-3, 6) * s, 4.6 * s, Color(0.15, 0.1, 0.05, color.a))
	node.draw_circle(c + Vector2(-3, 6) * s, 3.4 * s, color)
	node.draw_line(c + Vector2(0.6, 6) * s, c + Vector2(0.6, -9) * s, Color(0.15, 0.1, 0.05, color.a), 3.2 * s, true)
	node.draw_line(c + Vector2(0.6, 6) * s, c + Vector2(0.6, -9) * s, color, 1.6 * s, true)
	node.draw_line(c + Vector2(0.6, -9) * s, c + Vector2(6, -5) * s, color, 2.4 * s, true)

func _draw() -> void:
	var k := t / life
	match kind:
		"ring":
			var r := lerpf(10.0, 90.0, 1.0 - pow(1.0 - k, 3.0)) * size
			draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(col, 1.0 - k), 5.0 * (1.0 - k) + 1.0, true)
			draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 32, Color(col, (1.0 - k) * 0.5), 2.0, true)
		"arc":
			for i in 3:
				var kk := clampf(k * 1.3 - i * 0.18, 0.0, 1.0)
				if kk <= 0.0:
					continue
				var r := lerpf(18.0, 95.0, kk) * size
				var a0 := (-0.9 if dir > 0 else PI - 0.9)
				var a1 := a0 + 1.8
				draw_arc(Vector2.ZERO, r, a0, a1, 18, Color(1.0, 0.88, 0.5, (1.0 - kk) * 0.9), 4.0 * (1.0 - kk) + 1.5, true)
		"dust":
			for p in parts:
				draw_circle(p[0], p[2] * (1.0 - k * 0.5), Color(0.85, 0.82, 0.78, 0.5 * (1.0 - k)))
		"shards":
			for p in parts:
				var s: float = p[2]
				var a: float = p[3]
				var pts: PackedVector2Array = [
					p[0] + Vector2(cos(a), sin(a)) * s,
					p[0] + Vector2(cos(a + 2.3), sin(a + 2.3)) * s * 0.6,
					p[0] + Vector2(cos(a + 4.0), sin(a + 4.0)) * s * 0.8,
				]
				draw_colored_polygon(pts, Color(col, 1.0 - k))
				var cl := pts.duplicate(); cl.append(pts[0])
				draw_polyline(cl, Color(0.55, 0.6, 0.7, 1.0 - k), 1.5, true)
		"notes":
			for p in parts:
				var cc := Color(1.0, 0.82, 0.35, 1.0 - k)
				Fx.note_shape(self, p[0], p[2], cc)
		"wisps":
			for p in parts:
				draw_circle(p[0], p[2] * (1.0 - k), Color(0.93, 0.95, 1.0, 0.7 * (1.0 - k)))
		"text":
			var f := ThemeDB.fallback_font
			var s: String = get_meta("s")
			var off := Vector2(0, -40.0 * k)
			draw_string_outline(f, off + Vector2(-60, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, 4, Color(0, 0, 0, 0.7 * (1.0 - k)))
			draw_string(f, off + Vector2(-60, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color(col, 1.0 - k))
