class_name LevelObjects
## Small gameplay objects: checkpoint lantern, breakable crate, silence gate.

class Checkpoint extends Node2D:
	var active := false
	var t := 0.0
	var on := 0.0
	func _ready() -> void:
		add_to_group("checkpoint")
	func _process(delta: float) -> void:
		t += delta
		on = move_toward(on, 1.0 if active else 0.0, delta * 2.0)
		var p: Player = get_tree().get_first_node_in_group("player")
		if p and not active and absf(p.global_position.x - global_position.x) < 40.0 and absf(p.global_position.y + 48.0 - global_position.y) < 90.0:
			activate(p)
		queue_redraw()
	func activate(p: Player) -> void:
		for c in get_tree().get_nodes_in_group("checkpoint"):
			c.active = false
		active = true
		p.respawn_pos = global_position + Vector2(0, -50)
		Sfx.play("checkpoint", -4.0)
		Fx.ring(global_position + Vector2(0, -96), 1.0)
		Fx.text(global_position + Vector2(0, -150), "Lantern lit")
	func _draw() -> void:
		var ink := Color("1d1a22")
		draw_rect(Rect2(-4, -80, 8, 80), Color("3b3a44"))
		draw_rect(Rect2(-4, -80, 8, 80), ink, false, 2.0)
		draw_rect(Rect2(-12, -6, 24, 6), Color("3b3a44"))
		var c := Vector2(0, -96)
		if on > 0.01:
			for i in 3:
				draw_circle(c, 26 + i * 18 + sin(t * 4.0) * 2.0, Color(1.0, 0.75, 0.35, 0.12 * on))
		var glass := Color("4a5163").lerp(Color("ffcf70"), on)
		var pts := PackedVector2Array([c + Vector2(-11, -14), c + Vector2(11, -14), c + Vector2(13, 14), c + Vector2(-13, 14)])
		draw_colored_polygon(pts, glass)
		var cl := pts.duplicate(); cl.append(pts[0])
		draw_polyline(cl, ink, 2.5, true)
		draw_rect(Rect2(c.x - 14, c.y - 20, 28, 6), Color("3b3a44"))
		if on > 0.1:
			var fl := c + Vector2(0, 4)
			draw_circle(fl, 4.0 + sin(t * 12.0), Color(1.0, 0.95, 0.7, on))

class Breakable extends StaticBody2D:
	var size := 60.0
	var hp := 2
	var contents := ""     # "page:1" | "heart" | "notes:5" | ""
	var visual: Prop
	var broken := false
	func _ready() -> void:
		add_to_group("hittable")
		collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(size, size)
		cs.shape = sh
		cs.position = Vector2(size * 0.5, size * 0.5)
		add_child(cs)
		visual = Prop.new()
		visual.kind = "crate"
		visual.p = {"s": size, "cracked": contents.begins_with("page")}
		add_child(visual)
	func hurt_rect() -> Rect2:
		if broken:
			return Rect2()
		return Rect2(global_position - Vector2(6, 6), Vector2(size + 12, size + 12))
	func take_hit(dmg: int, _from: Vector2, _how: String) -> bool:
		if broken:
			return false
		hp -= dmg
		visual.position = Vector2(randf_range(-3, 3), 0)
		Sfx.play_var("crack0", -6.0, 0.15)
		if hp <= 0:
			_break()
		return true
	func _break() -> void:
		broken = true
		remove_from_group("hittable")
		Fx.shards(global_position + Vector2(size * 0.5, size * 0.5), 12, Color("c99560"))
		Fx.dust(global_position + Vector2(size * 0.5, size), 8)
		Sfx.play("land", -2.0, 0.7)
		var main := get_tree().get_first_node_in_group("main")
		var c := global_position + Vector2(size * 0.5, size * 0.4)
		if main:
			if contents.begins_with("page:"):
				main.spawn_page(int(contents.split(":")[1]), c + Vector2(0, -20))
			elif contents == "heart":
				main.spawn_heart(c)
			elif contents.begins_with("notes:"):
				main.spawn_notes(c, int(contents.split(":")[1]))
		queue_free()

class SilenceGate extends StaticBody2D:
	## Blocks the way to the bell tower until enough voices are freed.
	var needed := 3
	var have := 0
	var opening := -1.0
	var t := 0.0
	var h := 520.0
	func _ready() -> void:
		collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(70, h)
		cs.shape = sh
		cs.position = Vector2(35, -h * 0.5)
		add_child(cs)
	func set_count(n: int) -> void:
		have = n
		if have >= needed and opening < 0.0:
			opening = 0.0
			Sfx.play("shatter", 0.0, 0.8)
			Fx.shards(global_position + Vector2(35, -h * 0.5), 30)
			get_child(0).set_deferred("disabled", true)
	func _process(delta: float) -> void:
		t += delta
		if opening >= 0.0:
			opening += delta
			if opening > 1.5:
				queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 if opening < 0.0 else clampf(1.0 - opening / 1.5, 0.0, 1.0)
		# wrought-iron gate
		var ink := Color("1d1a22")
		for i in 6:
			var x := 6.0 + i * 12.0
			draw_line(Vector2(x, 0), Vector2(x, -h * 0.62), Color(ink, a), 5.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, -h * 0.62), Vector2(x + 5, -h * 0.62), Vector2(x, -h * 0.62 - 14)]), Color(ink, a))
		draw_line(Vector2(0, -h * 0.2), Vector2(76, -h * 0.2), Color(ink, a), 5.0)
		draw_line(Vector2(0, -h * 0.5), Vector2(76, -h * 0.5), Color(ink, a), 5.0)
		# silence fog wrapped around it
		for i in 14:
			var y := -float(i) / 14.0 * h
			var r := 34.0 + sin(t * 1.5 + i) * 6.0
			draw_circle(Vector2(35 + sin(t + i * 0.7) * 10.0, y), r, Color(0.92, 0.95, 1.0, 0.33 * a))
		# three lock glyphs
		for i in needed:
			var c := Vector2(35, -h * 0.35 - i * 70)
			var lit := i < have
			draw_circle(c, 18, Color(0.15, 0.17, 0.22, 0.85 * a))
			draw_circle(c, 13, Color(1.0, 0.8, 0.4, a) if lit else Color(0.75, 0.8, 0.9, 0.6 * a))
			Fx.note_shape(self, c + Vector2(1, 1), 0.7, Color(0.2, 0.15, 0.1, a))

class Mover extends StaticBody2D:
	## Moving platform: "raft" (bobbing debris on water) or "chandelier" (swings on a chain).
	var kind := "raft"
	var w := 120.0
	var axis := Vector2(0, 1)
	var amp := 20.0
	var speed := 1.0
	var phase := 0.0
	var base := Vector2.ZERO
	var t := 0.0
	var chain_top := 0.0
	func _ready() -> void:
		add_to_group("mover")
		collision_layer = 2
		constant_linear_velocity = Vector2.ZERO
		base = position
		chain_top = base.y - 420.0
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(w, 14)
		cs.shape = sh
		cs.position = Vector2(w * 0.5, 7)
		cs.one_way_collision = true
		add_child(cs)
	func _physics_process(delta: float) -> void:
		t += delta
		var next := base + axis * sin(t * speed + phase) * amp
		constant_linear_velocity = (next-position)/maxf(delta,0.0001)
		position = next
		queue_redraw()
	func centre() -> Vector2:
		return global_position + Vector2(w * 0.5, 0)
	func _draw() -> void:
		var ink := Color("1d1a22")
		if kind == "raft":
			for i in int(w / 30):
				var r := Rect2(i * 30 + 2, 0, 28, 16)
				draw_rect(r, Color("8a6240").darkened((i % 2) * 0.1))
				draw_rect(r, ink, false, 2.0)
			draw_line(Vector2(4, 8), Vector2(w - 4, 8), Color(ink, 0.35), 2.0)
			# ripple
			for k in 2:
				var rr := 8.0 + fmod(t * 20.0 + k * 20.0, 40.0)
				draw_arc(Vector2(w * 0.5, 22), w * 0.5 + rr, 0.15, PI - 0.15, 18, Color(0.7, 0.85, 1.0, 0.25 * (1.0 - rr / 48.0)), 2.0, true)
		else:
			# chain up to the ceiling
			var top := Vector2(w * 0.5 - (position.x - base.x) * 0.9, chain_top - position.y)
			draw_line(Vector2(w * 0.5, -40), top, ink, 4.0)
			draw_line(Vector2(w * 0.5, -40), top, Color("9a8a6a"), 2.0)
			# brass ring + candles
			draw_rect(Rect2(0, 0, w, 12), Color("b8863a"))
			draw_rect(Rect2(0, 0, w, 12), ink, false, 2.5)
			draw_line(Vector2(12, 0), Vector2(w * 0.5, -40), ink, 3.0)
			draw_line(Vector2(w - 12, 0), Vector2(w * 0.5, -40), ink, 3.0)
			for i in 5:
				var cx := 10.0 + i * (w - 20.0) / 4.0
				draw_rect(Rect2(cx - 3, -14, 6, 14), Color("efe8da"))
				draw_circle(Vector2(cx, -18), 3.5 + sin(t * 9.0 + i) * 0.8, Color(1.0, 0.8, 0.4))
				draw_circle(Vector2(cx, -18), 12, Color(1.0, 0.75, 0.35, 0.15))
			for i in 4:
				draw_circle(Vector2(14 + i * (w - 28) / 3.0, 20), 5, Color(0.85, 0.92, 1.0, 0.9))
