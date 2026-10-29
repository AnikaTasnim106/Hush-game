class_name FestivalEcho
extends Node2D
var index := 0
var used := false
var t := 0.0
func _ready() -> void:
	add_to_group("hittable")
	add_to_group("echo")
func hurt_rect() -> Rect2:
	return Rect2() if used else Rect2(global_position+Vector2(-58,-130),Vector2(116,130))
func take_hit(_d: int,_from: Vector2,_how: String) -> bool:
	if used: return false
	used = true
	_replay()
	return true
func _process(d: float) -> void:
	t += d
	queue_redraw()
	# walking into the circle is enough to remember (no need to ring)
	if not used:
		var p = get_tree().get_first_node_in_group("player")
		if p and not p.control_locked and p.is_on_floor() and absf(p.global_position.x - global_position.x) < 60.0 and absf(p.global_position.y + 48.0 - global_position.y) < 40.0:
			used = true
			_replay()
func _draw() -> void:
	var col := Color("f4d58e")
	col.a = 0.25 if used else 0.75
	draw_arc(Vector2(0,-6),55,0,TAU,48,col,4,true)
	for i in 5:
		draw_circle(Vector2(sin(t+i*1.7)*35,-45-i*15+sin(t*2+i)*8),3,col)
	if not used: Fx.note_shape(self,Vector2(0,-65),1.8,col)
func _replay() -> void:
	var m = get_tree().get_first_node_in_group("main")
	m.player.control_locked = true
	m.ui.letterbox(true)
	m.cam.focus = global_position+Vector2(0,-140)
	m.cam.focus_zoom = 1.1
	var l := Rig.new()
	l.setup(Cast.lark())
	l.position = Vector2(140,-40)
	l.modulate = Color(1,0.88,0.60,0.65)
	l.carry = "guitar"
	add_child(l)
	var w := Rig.new()
	w.setup(Cast.wren())
	w.position = Vector2(-100,0)
	w.modulate = Color(1,0.88,0.60,0.75)
	add_child(w)
	l.state = "talk" if index == 0 else "frozen"
	l.expression = "happy" if index == 0 else "scared"
	l.frozen_pose = Cast.pose_mouth()
	if index == 1: Sfx.play("talk_blip",-16,0.7)
	if index == 2:
		w.facing = -1
		w.state = "run"
		var tw := create_tween()
		tw.tween_property(w,"position:x",-330,2.5)
	await get_tree().create_timer(2.8).timeout
	var lines: Array = [
		[["Wren","Her hands were shaking. She looked at the front row... and smiled.","sad"]],
		[["Wren","The middle of the song. She stopped. Then the laugh.","hurt"]],
		[["Wren","...That was me.","hurt"],["Wren","I didn't know what to do. So I left.","sad"],["Wren","You were looking for me. And I left.","sad"]]
	][index]
	await m._say(lines)
	var clues: Array = ["Lark looked to the front row and smiled as she began.","Lark froze halfway through. Silence, then Jory's nervous laugh.","Wren was in the front row. She turned and walked away when Lark needed her."]
	GameState.add_clue(clues[index])
	GameState.rescued.append("echo%d"%index)
	m.add_colour(global_position,800,2)
	if is_instance_valid(m.gate): m.gate.set_count(GameState.rescued.size())
	if GameState.rescued.size() >= 3: m.done_hints["gate4"] = true
	l.queue_free()
	w.queue_free()
	m.cam.focus = null
	m.ui.letterbox(false)
	m.ui.hint("A memory added to the journal. Keep climbing.",4)
	m.player.control_locked = false
