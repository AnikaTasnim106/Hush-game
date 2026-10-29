class_name BossChoir
extends Node2D
signal phase_changed(p)
signal defeated
signal damaged(frac)
var state := "dormant"
var phase := 0
var hp := [3,3,3]
var singer := 0
var st := 0.0
var pulse := 0.0
var t := 0.0
var arena_x0 := 0.0
var arena_x1 := 0.0
var x := 0.0
var hits := 0
const INK := Color("1d1a22")
func _ready() -> void:
	add_to_group("hittable")
	x = global_position.x
func chest_x(i: int) -> float:
	return global_position.x+(i-1)*330.0
func reset() -> void:
	state = "dormant"
	for i in 3:
		if hp[i]>0:
			singer=i
			break
	st = 0
func start_fight() -> void:
	_go("warning")
	var m = get_tree().get_first_node_in_group("main")
	m.spawn_hush("wing", Vector2(chest_x(1),-360),200)
	Sfx.play("crow_soft",-16)
func _go(s: String) -> void:
	state = s
	st = 0.0
	pulse = 0.0
	if s == "singing": Sfx.play("choir_hum",-10.0,1.0+phase*0.12)
func hurt_rect() -> Rect2:
	if state != "dazed": return Rect2()
	return Rect2(Vector2(chest_x(singer)-44,-150),Vector2(88,110))
func take_hit(_dmg: int, _from: Vector2, _how: String) -> bool:
	if state != "dazed": return false
	hp[singer] -= 1
	hits += 1
	Sfx.play("strike2",-5.0,1.3)
	Fx.ring(Vector2(chest_x(singer),-100),1.6,Color("ffd87b"),0.5)
	damaged.emit(float(9-hits)/9.0)
	if hp[singer] <= 0:
		phase += 1
		phase_changed.emit(phase)
		Fx.wisps(Vector2(chest_x(singer),-140),20)
		var m = get_tree().get_first_node_in_group("main")
		m.spawn_heart(Vector2(chest_x(singer),-70))
		if phase == 3:
			_go("freed")
			Sfx.play("bell_free",-3)
			defeated.emit()
		else:
			_next()
	return true
func _next() -> void:
	for step in range(1,4):
		var i: int = (singer+step)%3
		if hp[i]>0:
			singer=i
			break
	_go("warning")
func _process(d: float) -> void:
	t += d
	st += d
	match state:
		"warning":
			if st > 1.4: _go("singing")
		"singing":
			pulse -= d
			if pulse <= 0.0:
				pulse = 1.25-phase*0.16
				for dir in [-1.0,1.0]:
					var w := ChoirRing.new()
					w.position = Vector2(chest_x(singer),-26)
					w.dir = dir
					w.speed = 300+phase*55
					get_parent().add_child(w)
				Sfx.play("boss_wave",-16)
			if st > 3.5-phase*0.35:
				_go("dazed")
		"dazed":
			if st > 3.4: _next()
	queue_redraw()
func _draw() -> void:
	for i in 3:
		var cx := (i-1)*330.0
		var freed: bool = hp[i]<=0
		var exposed := i==singer and state=="dazed"
		var cy := -110.0 if exposed else -225.0
		draw_line(Vector2(cx,0),Vector2(cx,-300),INK,14)
		draw_line(Vector2(cx-85,cy-40),Vector2(cx+85,cy-40),Color("886149"),12)
		var coat: PackedVector2Array = [Vector2(cx-42,cy-65),Vector2(cx+42,cy-65),Vector2(cx+60,cy+48),Vector2(cx-60,cy+48)]
		draw_colored_polygon(coat,Color("bc9b53") if freed else Color("42424e")); coat.append(coat[0]); draw_polyline(coat,INK,4,true)
		draw_circle(Vector2(cx,cy-96),32,INK)
		draw_circle(Vector2(cx,cy-96),27,Color("e6c88d") if freed else Color("a3a2ae"))
		draw_line(Vector2(cx-48,cy-122),Vector2(cx+48,cy-122),INK,9)
		draw_colored_polygon(PackedVector2Array([Vector2(cx-26,cy-126),Vector2(cx+24,cy-126),Vector2(cx+9,cy-169)]),Color("76604a"))
		for ex in [-10,10]: draw_circle(Vector2(cx+ex,cy-100),3,INK)
		if i==singer and state=="singing":
			draw_circle(Vector2(cx,cy-83),11,Color("eef0fc"))
			draw_arc(Vector2(cx,cy-90),50+sin(t*7)*5,0,TAU,40,Color(0.95,0.95,1,0.5),3,true)
		else: draw_line(Vector2(cx-9,cy-82),Vector2(cx+9,cy-82),INK,3)
		draw_rect(Rect2(cx-24,cy-22,48,40),Color("ffe29c") if exposed or freed else Color("6c6879"))
		Fx.note_shape(self,Vector2(cx,cy),0.9,INK)
		for j in hp[i]: draw_circle(Vector2(cx-14+j*14,cy+32),4,Color("f1dbad"))
		if i==singer and state=="warning":
			draw_arc(Vector2(cx,cy-96),65,0,TAU,40,Color("f4d98f"),2.5,true)

class ChoirRing extends Node2D:
	var dir := 1.0
	var speed := 300.0
	var delay := 0.0
	var age := 0.0
	func _ready() -> void:
		add_to_group("hazard")
		add_to_group("boss_wave")
	func hazard_rect() -> Rect2:
		return Rect2(global_position+Vector2(-12,-26),Vector2(24,52))
	func _physics_process(d: float) -> void:
		age += d
		position.x += dir*speed*d
		if age>5: queue_free()
		queue_redraw()
	func _draw() -> void:
		draw_arc(Vector2.ZERO,26,0,TAU,32,Color("eff1ff"),5,true)
		draw_arc(Vector2.ZERO,18,0,TAU,24,Color(0.72,0.7,0.84,0.55),2,true)
