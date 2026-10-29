class_name FieldChase
extends Node2D
var main: Main
var active := false
var done := false
var wave_x := 3200.0
var t := 0.0
var shelter: Windmill
var roof: StaticBody2D
var roof_prop: Prop
var collapse := -1.0
func _ready() -> void:
	add_to_group("field_chase")
func restart() -> void:
	active = false
	wave_x = 3200.0
	collapse = -1.0
	if is_instance_valid(roof): main.set_solid_enabled(roof,true)
	if is_instance_valid(roof_prop): roof_prop.modulate.a = 1.0
func _process(d: float) -> void:
	t += d
	var p := main.player
	if done:
		wave_x -= d*650
		queue_redraw()
		return
	if main.state != "play" or p.control_locked: return
	if not active and p.global_position.x > 3900 and p.global_position.x < 4400:
		active = true
		wave_x = 3200
		p.respawn_pos = Vector2(3820,-50)
		main.ui.hint("The Hush is coming! Run to the singing mill. Hold Space in its wind!",5.0)
		Sfx.play("wind_whoosh",-5.0,0.65)
	if not active: return
	wave_x += d*300
	if p.global_position.x > 4610 and collapse < 0.0:
		collapse = 0.0
	if collapse >= 0.0:
		collapse += d
		if collapse > 0.6:
			main.set_solid_enabled(roof,false)
			roof_prop.modulate.a = maxf(0.0,1.0-(collapse-0.6)*2.0)
	if p.global_position.x > 6110 and p.global_position.y < -225:
		done = true
		active = false
		main.add_colour(Vector2(6100,-180),850,2.0)
		main.ui.hint("The mill's song holds the silence back.",4.0)
		Sfx.play("bell_free",-5.0)
	elif p.global_position.x < wave_x+24 or p.fainted or p.global_position.x < 3800:
		restart()
		if not p.fainted:
			p.fall_out()
		main.cam.snap()
	queue_redraw()
func _draw() -> void:
	if not active and not done: return
	draw_rect(Rect2(wave_x-1700,-1250,1700,1750),Color("e8e8ed"))
	for i in 27:
		var y := -1200+i*65.0
		draw_circle(Vector2(wave_x+sin(t*2+i)*25,y),80,Color(0.94,0.95,0.98,0.7))
		draw_arc(Vector2(wave_x-20,y),55,t+i,t+i+2.8,16,Color(0.64,0.65,0.73,0.4),3,true)
