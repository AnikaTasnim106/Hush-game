class_name Windmill
extends Node2D
## A ground-level sail hub and a generous column beside the mill.
var active := false
var hits := 0
var t := 0.0
var sails := 0.0
var height := 560.0
var sound_t := 0.0
const INK := Color("1d1a22")
func _ready() -> void:
	add_to_group("hittable")
	add_to_group("windmill")
func hurt_rect() -> Rect2:
	return Rect2() if active else Rect2(global_position + Vector2(-45, -125), Vector2(90, 100))
func wind_rect() -> Rect2:
	return Rect2(global_position + Vector2(-100, -height), Vector2(240, height + 30))
func take_hit(_dmg: int, _from: Vector2, _how: String) -> bool:
	if active: return false
	hits += 1
	Sfx.play("boss_clang", -12.0, 1.5)
	Fx.ring(global_position + Vector2(0, -80), 0.8, Color("f1cf78"), 0.4)
	if hits >= 3: free_mill()
	return true
func free_mill() -> void:
	if active: return
	active = true
	var m = get_tree().get_first_node_in_group("main")
	m.add_colour(global_position + Vector2(0, -180), 740.0, 2.5)
	Sfx.play("wind_whoosh", -12.0)
	m.ui.hint("Wind restored! Hold Space in the wind to rise; keep holding to glide.", 4.0)
func _process(d: float) -> void:
	t += d
	if active:
		sails += d * 0.8
		sound_t -= d
		if sound_t <= 0.0:
			sound_t = 5.0
			var p = get_tree().get_first_node_in_group("player")
			if p and absf(p.global_position.x - global_position.x) < 650:
				Sfx.play("mill_creak", -22.0)
	queue_redraw()
func _draw() -> void:
	var body: PackedVector2Array = [Vector2(-105,0), Vector2(105,0), Vector2(62,-335), Vector2(-62,-335)]
	draw_colored_polygon(body, Color("e3c698")); body.append(body[0]); draw_polyline(body, INK, 4.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-86,-335), Vector2(0,-410), Vector2(86,-335)]), Color("805547"))
	for y in [-270,-210,-150]:
		draw_rect(Rect2(-17,y,34,42), INK)
		draw_rect(Rect2(-12,y+5,24,30), Color("efc86a") if active else Color("7a7783"))
	var hub := Vector2(0,-320)
	for i in 4:
		var v := Vector2.from_angle(sails + i * PI/2.0)
		var n := v.orthogonal()
		var blade: PackedVector2Array = [hub+v*25,hub+v*207,hub+v*207+n*39,hub+v*55+n*39]
		draw_colored_polygon(blade, Color("f3e4b6")); blade.append(blade[0]); draw_polyline(blade, INK, 3.0, true)
		for j in range(3,10): draw_line(hub+v*j*20,hub+v*j*20+n*36,Color("876749"),2.0)
	draw_circle(hub, 19, INK)
	draw_line(hub,Vector2(0,-80),INK,5.0)
	draw_circle(Vector2(0,-80),37,INK)
	draw_circle(Vector2(0,-80),30,Color("f2ca67") if active else Color("9895a4"))
	for i in 3: draw_circle(Vector2(-16+i*16,-80),5,Color("fff0ac") if active or i < hits else INK)
	if active:
		for i in 13:
			var y := -fmod(t*170+i*47,height)
			var x := sin(t*2+i*1.7)*55+20
			draw_arc(Vector2(x,y),32,0.2,2.6,18,Color(1.0,0.94,0.75,0.55),2.5,true)
