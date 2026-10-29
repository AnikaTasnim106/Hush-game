class_name CameraDirector
extends Camera2D
## Follows Wren with look-ahead; supports focus shots (dialogue), zoom and shake.

var target: Node2D
var look := 0.0
var focus = null          # Vector2 or null
var focus_zoom := 1.0
var base_zoom := 1.0
var _shake := 0.0
var min_x := -1e9
var max_x := 1e9
var lock_rect = null      # Rect2: clamp camera centre inside (arena)
var y_bias := -120.0

func _ready() -> void:
	position_smoothing_enabled = false
	make_current()

func shake(a: float) -> void:
	_shake = maxf(_shake, a)

func snap() -> void:
	if target:
		global_position = _desired()

func _desired() -> Vector2:
	if focus != null:
		return focus
	var p := target.global_position
	var d := Vector2(p.x + look, p.y + y_bias)
	return d

func _process(delta: float) -> void:
	if target == null:
		return
	var v := Vector2.ZERO
	if target is CharacterBody2D:
		v = (target as CharacterBody2D).velocity
	var want_look := 0.0
	if target is Player:
		want_look = (target as Player).facing * 130.0 + clampf(v.x * 0.25, -60, 60)
	look = lerpf(look, want_look, 1.0 - exp(-2.0 * delta))
	var d := _desired()
	if lock_rect != null:
		var r: Rect2 = lock_rect
		d.x = clampf(d.x, r.position.x, r.end.x)
		d.y = clampf(d.y, r.position.y, r.end.y)
	d.x = clampf(d.x, min_x, max_x)
	var k := 1.0 - exp(-(6.0 if focus == null else 3.0) * delta)
	# vertical: follow slower unless falling fast
	var gp := global_position
	gp.x = lerpf(gp.x, d.x, k)
	var ky := 1.0 - exp(-(4.0 if v.y < 700.0 else 9.0) * delta)
	gp.y = lerpf(gp.y, d.y, ky if focus == null else k)
	global_position = gp
	var zt := focus_zoom if focus != null else base_zoom
	zoom = zoom.lerp(Vector2.ONE * zt, 1.0 - exp(-3.0 * delta))
	_shake = move_toward(_shake, 0.0, 30.0 * delta)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
