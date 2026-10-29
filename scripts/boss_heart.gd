class_name HushHeart
extends Node2D
signal defeated
signal phase_changed(p)
signal damaged(frac)
signal resolved(ending)
var state := "dormant"
var phase := 0
var hits := 0
var st := 0.0
var pulse := 0.0
var lower := 0.0
var t := 0.0
var lark: Rig
func _ready() -> void:
	add_to_group("hittable")
	lark = Rig.new()
	lark.setup(Cast.lark())
	lark.position = Vector2(310,-15)
	lark.state = "frozen"
	lark.freeze = 1.0
	lark.frozen_pose = {"lean":0.7,"hip":22.0,"sq":0.75,"head":0.6,"hf":Vector2(3,0),"hb":Vector2(-2,0),"ff":Vector2(13,-10),"fb":Vector2(-8,-5)}
	lark.show_behind_parent = true
	add_child(lark)
func start_fight() -> void:
	state = "warning"
	st = 0
func reset() -> void:
	state = "dormant"
	st = 0
	lower = 0
func weak_x() -> float: return global_position.x-220
func hurt_rect() -> Rect2:
	if state not in ["dazed","choice"]: return Rect2()
	return Rect2(Vector2(weak_x()-50,global_position.y-155),Vector2(100,125))
func take_hit(_d: int,_from: Vector2,_how: String) -> bool:
	if state == "choice":
		hits += 1
		if hits>=8:
			state = "ended"
			resolved.emit("A")
		return true
	if state != "dazed": return false
	hits += 1
	damaged.emit(1.0-float(hits)/6.0)
	Fx.ring(Vector2(weak_x(),global_position.y-90),1.7,Color("f5d492"),0.5)
	Sfx.play("boss_clang",-8,1.2)
	if hits%2==0:
		phase += 1
		phase_changed.emit(phase)
		get_tree().get_first_node_in_group("main").spawn_heart(Vector2(weak_x(),global_position.y-70))
	if hits>=6:
		state = "choice"
		st = 0
		for w in get_tree().get_nodes_in_group("boss_wave"): w.queue_free()
	else:
		state = "warning"
		st = 0
	return true
func _process(d: float) -> void:
	t += d
	st += d
	var m = get_tree().get_first_node_in_group("main")
	var p: Player = m.player
	match state:
		"warning":
			if st>1.2:
				state="waves"
				st=0
		"waves":
			pulse -= d
			if pulse<=0:
				pulse=1.6-phase*0.12
				_wave()
			if st>2.6:
				state="dazed"
				st=0
		"dazed":
			if st>4.2:
				state="warning"
				st=0
		"choice":
			m.ui.hint("The Heart has stopped fighting. J: keep ringing   ·   Hold S / Down: lower the bell",0.4)
			if p._held("down"): lower += d
			else: lower = 0
			if lower>0.9:
				state="approach"
				st=0
				p.strike_t=-1
				m.ui.hide_boss()
		"approach":
			m.ui.hint("Walk right toward Lark. Stay with her. Jump the pale waves. Your bell can rest.",0.4)
			p.wind_push=-330
			p.strike_t=-1
			pulse -= d
			if pulse<=0:
				pulse=2.6
				_wave()
			if p.global_position.x>global_position.x+240:
				p.wind_push=0
				state="ended"
				resolved.emit("TRUE" if GameState.pages.size() >= 12 else "B")
	queue_redraw()
func _wave() -> void:
	var w := BossChoir.ChoirRing.new()
	w.position = global_position+Vector2(280,-26)
	w.dir=-1
	w.speed=250+phase*20
	get_parent().add_child(w)
func _draw() -> void:
	if state=="ended": return
	for i in 15:
		var q := Vector2(260+sin(t*0.7+i*2.3)*95,-140+cos(i*2.7+t*0.4)*110)
		draw_circle(q,75+sin(t+i)*12,Color(0.71,0.74,0.85,0.28))
	var c := Vector2(-220,-90)
	var col := Color("f4d58e") if state in ["dazed","choice"] else Color("787b90")
	draw_circle(c,45,Color("25283a"))
	draw_circle(c,34+sin(t*3)*3,col)
	Fx.note_shape(self,c,1.6,Color("25283a"))
	draw_arc(Vector2(310,-100),120,0,TAU,48,Color(0.91,0.92,1,0.65),5,true)
	if state=="warning": draw_arc(c,62,0,TAU,40,Color("efc788"),3,true)
