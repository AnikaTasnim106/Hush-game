class_name Townsfolk
extends Node2D
## A frozen townsperson inside a shell of silence. Ring the shell to free them.

signal freed(who)

var id := ""
var display_name := ""
var rig_cfg := {}
var pose := {}
var carry := ""
var face_dir := 1.0
var lines: Array = []        # dialogue on rescue: [[speaker, text, expression], ...]
var repeat_line: Array = []  # what they say if you talk again
var clue := ""
var extra := []:             # extra people in the same shell: [[cfg, pose, offset, facing], ...]
	set(v):
		extra = v
		if is_inside_tree():
			_make_extra()
var extra_rigs: Array[Rig] = []

var rig: Rig
var shell_hp := 3
var frozen := true
var crack_seed := 0
var t := 0.0
var wobble := 0.0
var shell_scale := 1.0
var _shell_size := Vector2(56, 82)
var _shell_offset := Vector2.ZERO

func _ready() -> void:
	add_to_group("hittable")
	add_to_group("townsfolk")
	rig = Rig.new()
	add_child(rig)
	rig.setup(rig_cfg)
	rig.state = "frozen"
	rig.frozen_pose = pose
	rig.freeze = 1.0
	rig.facing = face_dir
	rig.carry = carry
	rig.wind = -30.0
	rig.show_behind_parent = true
	var s: float = rig_cfg.get("scale", 1.0)
	_shell_size = Vector2(60, 84) * s
	_make_extra()
	crack_seed = randi()

func _make_extra() -> void:
	for r in extra_rigs:
		r.queue_free()
	extra_rigs.clear()
	for e in extra:
		var r := Rig.new()
		r.position = e[2]
		add_child(r)
		r.setup(e[0])
		r.state = "frozen"
		r.frozen_pose = e[1]
		r.freeze = 1.0
		r.facing = e[3]
		r.show_behind_parent = true
		extra_rigs.append(r)
	if extra.size() > 0:
		_shell_size = Vector2(_shell_size.x + 30.0, _shell_size.y)
		_shell_offset = Vector2(21, 0)

func hurt_rect() -> Rect2:
	if not frozen:
		return Rect2()
	var c := global_position + _shell_offset + Vector2(0, -_shell_size.y)
	return Rect2(c - _shell_size, _shell_size * 2.0)

func take_hit(dmg: int, _from: Vector2, _how: String) -> bool:
	if not frozen:
		return false
	shell_hp -= dmg
	wobble = 1.0
	if shell_hp <= 0:
		_shatter()
	else:
		Sfx.play("crack%d" % clampi(2 - shell_hp, 0, 2), -2.0)
		Fx.shards(global_position + _shell_offset + Vector2(0, -_shell_size.y), 4)
	return true

func _shatter() -> void:
	frozen = false
	remove_from_group("hittable")
	Sfx.play("shatter", 0.0)
	Fx.shards(global_position + Vector2(0, -_shell_size.y), 26)
	Fx.notes_burst(global_position + Vector2(0, -_shell_size.y), 10)
	rig.state = "wake"
	var tw := create_tween()
	tw.tween_property(rig, "freeze", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	for r in extra_rigs:
		r.state = "wake"
		create_tween().tween_property(r, "freeze", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	freed.emit(self)

func can_interact() -> bool:
	return not frozen and repeat_line.size() > 0

func interact_label() -> String:
	return "Talk to %s" % display_name

func _process(delta: float) -> void:
	t += delta
	wobble = move_toward(wobble, 0.0, delta * 3.0)
	if not frozen and rig.state == "wake" and rig.freeze < 0.05:
		rig.state = "idle"
		for r in extra_rigs:
			r.state = "idle"
	if frozen or wobble > 0.0:
		queue_redraw()
	elif shell_scale > 0.0:
		shell_scale = 0.0
		queue_redraw()

func _draw() -> void:
	if not frozen:
		return
	var c := _shell_offset + Vector2(0, -_shell_size.y)
	var w := sin(t * 40.0) * 3.0 * wobble
	var rx := _shell_size.x + w
	var ry := _shell_size.y - w * 0.5
	var pts: PackedVector2Array = []
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, Color(0.86, 0.9, 1.0, 0.22 + 0.04 * sin(t * 2.0)))
	var cl := pts.duplicate(); cl.append(pts[0])
	draw_polyline(cl, Color(0.92, 0.95, 1.0, 0.85), 3.0, true)
	# highlight
	draw_arc(c + Vector2(-rx * 0.3, -ry * 0.35), rx * 0.45, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.75), 4.0, true)
	draw_arc(c + Vector2(rx * 0.2, ry * 0.3), rx * 0.6, 0.2, 0.7, 8, Color(1, 1, 1, 0.35), 2.0, true)
	# cracks grow with damage
	var dmg := 3 - shell_hp
	var rng := RandomNumberGenerator.new()
	rng.seed = crack_seed
	for k in dmg * 3:
		var a := rng.randf() * TAU
		var p := c + Vector2(cos(a) * rx * 0.95, sin(a) * ry * 0.95)
		var line: PackedVector2Array = [p]
		var dir := (c - p).normalized()
		for j in 4:
			p += dir.rotated(rng.randf_range(-0.7, 0.7)) * rng.randf_range(9, 18)
			line.append(p)
		draw_polyline(line, Color(0.45, 0.5, 0.62, 0.9), 2.0, true)
	# floating "shh" motes
	for i in 4:
		var a := t * 0.6 + i * TAU / 4.0
		draw_circle(c + Vector2(cos(a) * (rx + 14), sin(a) * (ry * 0.6)), 3.0, Color(0.92, 0.95, 1.0, 0.6))
