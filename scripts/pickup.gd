class_name Pickup
extends Node2D
## kind "note" (currency), "heart", "page" (Lark's song page, id 0..2)

var kind := "note"
var page_id := 0
var vel := Vector2.ZERO
var t := 0.0
var settled := false
var floor_y := 1e9
var magnet := false
var life := -1.0
var taken := false

func _ready() -> void:
	add_to_group("pickup")
	t = randf() * 6.0

func _process(delta: float) -> void:
	t += delta
	if taken:
		return
	var p: Node2D = get_tree().get_first_node_in_group("player")
	if kind == "note" and not settled:
		vel.y += 1400.0 * delta
		global_position += vel * delta
		vel.x *= 0.98
		if global_position.y >= floor_y:
			global_position.y = floor_y
			vel.y = -vel.y * 0.35
			vel.x *= 0.6
			if absf(vel.y) < 80.0:
				settled = true
	if p:
		var target := p.global_position + Vector2(0, -6)
		var d := target - global_position
		var reach := 46.0 if kind != "page" else 54.0
		if kind == "note" and (d.length() < 110.0 or magnet) and t > 0.25:
			magnet = true
			settled = true
			global_position += d.normalized() * minf(d.length(), 700.0 * delta)
		if d.length() < reach and t > 0.2:
			_take()
	queue_redraw()

func _take() -> void:
	taken = true
	match kind:
		"note":
			GameState.add_notes(1)
			Sfx.play("note%d" % (randi() % 6), -10.0)
		"heart":
			GameState.heal_full()
			Sfx.play("checkpoint", -6.0, 1.3)
			Fx.text(global_position + Vector2(0, -30), "Courage restored", Color(1, 0.6, 0.6))
		"page":
			GameState.add_page(page_id)
			Sfx.play("page", -2.0)
			var main := get_tree().get_first_node_in_group("main")
			if main and main.has_method("show_page"):
				main.show_page(page_id)
	Fx.ring(global_position, 0.6 if kind == "note" else 1.2)
	queue_free()

func _draw() -> void:
	match kind:
		"note":
			var bob := 0.0 if not settled else sin(t * 4.0) * 2.0
			draw_circle(Vector2(0, bob), 14, Color(1.0, 0.8, 0.35, 0.18))
			Fx.note_shape(self, Vector2(0, bob), 1.15, Color(1.0, 0.82, 0.35))
		"heart":
			var b := sin(t * 3.0) * 4.0
			draw_circle(Vector2(0, b), 22, Color(1.0, 0.5, 0.5, 0.18))
			_heart(Vector2(0, b), 1.0)
		"page":
			var b := sin(t * 2.0) * 7.0
			var rot := sin(t * 1.3) * 0.12
			for i in 3:
				draw_circle(Vector2(0, b), 30 + i * 12 + sin(t * 3.0) * 3.0, Color(1.0, 0.9, 0.6, 0.12 - i * 0.03))
			var pts: PackedVector2Array = []
			for v in [Vector2(-16, -20), Vector2(16, -22), Vector2(18, 20), Vector2(-15, 22)]:
				pts.append(Vector2(0, b) + (v as Vector2).rotated(rot))
			draw_colored_polygon(pts, Color(0.97, 0.93, 0.82))
			var cl := pts.duplicate(); cl.append(pts[0])
			draw_polyline(cl, Color(0.35, 0.25, 0.18), 2.5, true)
			for i in 4:
				var y := -12.0 + i * 7.0
				draw_line(Vector2(-11, b + y).rotated(rot), Vector2(11, b + y - 1).rotated(rot), Color(0.45, 0.35, 0.28, 0.8), 1.2, true)
			Fx.note_shape(self, Vector2(2, b - 2).rotated(rot), 0.7, Color(0.3, 0.2, 0.15))

func _heart(c: Vector2, s: float) -> void:
	var pts: PackedVector2Array = []
	for i in 30:
		var a := TAU * i / 30.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(c + Vector2(x, y) * s * 0.9)
	draw_colored_polygon(pts, Color(0.92, 0.36, 0.38))
	var cl := pts.duplicate(); cl.append(pts[0])
	draw_polyline(cl, Color(0.3, 0.08, 0.1), 2.5, true)
