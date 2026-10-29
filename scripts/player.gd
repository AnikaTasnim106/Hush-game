class_name Player
extends CharacterBody2D
## Wren. Platformer controller + bell combat.

signal died
signal struck(combo)
signal made_noise(pos, radius)

var on_moving := false
var fall_respawn: Callable

const RUN := 340.0
const ACCEL := 2700.0
const DECEL := 3200.0
const AIR_ACCEL := 1800.0
const GRAV := 2200.0
const FALL_MULT := 1.3
const MAX_FALL := 1150.0
const JUMP_V := -840.0
const COYOTE := 0.11
const BUFFER := 0.13
const STRIKE_LEN := [0.30, 0.30, 0.42]

var rig: Rig
var facing := 1.0
var control_locked := false
var invuln := 0.0
var hurt_t := 0.0
var coyote := 0.0
var buffer := 0.0
var strike_t := -1.0
var strike_combo := 0
var combo_window := 0.0
var strike_hit := {}
var stomping := false
var stomp_hang := 0.0
var drop_t := 0.0
var was_on_floor := true
var fall_peak_vy := 0.0
var step_acc := 0.0
var respawn_pos := Vector2.ZERO
var kill_y := 900.0
var unlocked_stomp := true
var gliding := false
var glide_armed := false
var in_updraft := false
var wind_push := 0.0
var auto_walk := 0.0   # cutscene: walk toward this x if != 0

# bot / scripted input
var use_bot := false
var bot := {"x": 0.0, "jump": false, "jump_p": false, "strike_p": false, "down_p": false, "stomp_p": false}

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1 << 2      # layer 3 = player
	collision_mask = 1 | 2         # solids + one-way
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(50)
	var shape := CapsuleShape2D.new()
	shape.radius = 13.0
	shape.height = 96.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	rig = Rig.new()
	rig.position = Vector2(0, 48)
	add_child(rig)
	rig.setup(Cast.wren())
	rig.wind = -50.0
	respawn_pos = global_position

# ------------------------------------------------------------------ input helpers
func _axis() -> float:
	if control_locked:
		return 0.0
	if use_bot:
		return bot["x"]
	return Input.get_axis("left", "right")

func _pressed(a: String) -> bool:
	if control_locked:
		return false
	if use_bot:
		var key: String = {"jump": "jump_p", "strike": "strike_p", "down": "down_p", "stomp": "stomp_p"}.get(a, "")
		if key != "" and bot.get(key, false):
			bot[key] = false
			return true
		return false
	return Input.is_action_just_pressed(a)

func _held(a: String) -> bool:
	if control_locked:
		return false
	if use_bot:
		return bot.get(a, false)
	return Input.is_action_pressed(a)

# ------------------------------------------------------------------ physics
func _physics_process(delta: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	combo_window = maxf(0.0, combo_window - delta)
	drop_t = maxf(0.0, drop_t - delta)
	set_collision_mask_value(2, drop_t <= 0.0)

	var on_floor := is_on_floor()
	var ax := _axis()
	if auto_walk != 0.0 and hurt_t <= 0.0:
		var dx := auto_walk - global_position.x
		ax = clampf(dx / 40.0, -0.6, 0.6) if absf(dx) > 6.0 else 0.0
		if absf(ax) > 0.05:
			facing = signf(ax)
		if absf(dx) <= 6.0:
			auto_walk = 0.0

	# coyote / buffer
	if on_floor:
		coyote = COYOTE
	else:
		coyote = maxf(0.0, coyote - delta)
	if _pressed("jump"):
		buffer = BUFFER
	else:
		buffer = maxf(0.0, buffer - delta)

	# horizontal
	if hurt_t <= 0.0 and not stomping:
		var target := ax * RUN
		var acc := ACCEL if on_floor else AIR_ACCEL
		if absf(ax) < 0.05:
			acc = DECEL if on_floor else AIR_ACCEL * 0.6
		if strike_t >= 0.0 and on_floor:
			target *= 0.35
		velocity.x = move_toward(velocity.x, target, acc * delta)
		if absf(ax) > 0.1 and strike_t < 0.0:
			facing = signf(ax)
	elif stomping:
		velocity.x = move_toward(velocity.x, 0.0, 4000.0 * delta)

	# jump / drop through
	if buffer > 0.0 and coyote > 0.0 and not stomping and hurt_t <= 0.0:
		if _held("down") and on_floor and _standing_on_oneway():
			drop_t = 0.25
			position.y += 2
		else:
			velocity.y = JUMP_V
			coyote = 0.0
			Sfx.play_var("jump", -6.0)
			Fx.dust(global_position + Vector2(0, 48), 5, 0.8)
		buffer = 0.0

	# variable jump height
	if velocity.y < 0.0 and not _held("jump") and not stomping and hurt_t <= 0.0 and auto_walk == 0.0:
		velocity.y = maxf(velocity.y, velocity.y * 0.55) if velocity.y < -300.0 else velocity.y

	# stomp
	if not on_floor and not stomping and unlocked_stomp and (_pressed("stomp") or _pressed("down")) and hurt_t <= 0.0:
		stomping = true
		stomp_hang = 0.09
		strike_t = -1.0
		velocity = Vector2(0, -180)
		Sfx.play("whoosh", -4.0, 0.8)

	# gravity
	if stomping:
		if stomp_hang > 0.0:
			stomp_hang -= delta
			velocity.y = -120.0
		else:
			velocity.y = 1500.0
	else:
		var g := GRAV * (FALL_MULT if velocity.y > 0.0 else 1.0)
		if strike_t >= 0.0 and not on_floor and velocity.y > 0.0:
			g *= 0.35   # a little hang time when striking in the air
		velocity.y = minf(velocity.y + g * delta, MAX_FALL)

	gliding = false
	in_updraft = false
	# glide only on a fresh press of Jump while already airborne (normal jumps stay snappy)
	if on_floor:
		glide_armed = false
	elif buffer >= BUFFER - 0.0001 and coyote <= 0.0:
		glide_armed = true
	if not _held("jump"):
		glide_armed = false
	if GameState.chapter >= 2 and not stomping and hurt_t <= 0.0 and _held("jump"):
		for mill in get_tree().get_nodes_in_group("windmill"):
			if mill.active and mill.wind_rect().has_point(global_position):
				velocity.y = move_toward(velocity.y, -520.0, 3600.0 * delta)
				in_updraft = true
				break
		if glide_armed and not on_floor and velocity.y > 0.0 and not in_updraft:
			velocity.y = move_toward(velocity.y, 175.0, 3000.0 * delta) if velocity.y > 175.0 else velocity.y
			gliding = true

	velocity.x += wind_push * delta
	# strike
	if _pressed("strike") and not stomping and hurt_t <= 0.0:
		if strike_t < 0.0 or (combo_window > 0.0 and strike_t > STRIKE_LEN[strike_combo] * 0.55):
			strike_combo = (strike_combo + 1) % 3 if combo_window > 0.0 else 0
			strike_t = 0.0
			strike_hit.clear()
			combo_window = 0.0
			Sfx.play("whoosh", -9.0, 1.0 + strike_combo * 0.12)
			if not on_floor and velocity.y > 0.0:
				velocity.y *= 0.3
	if strike_t >= 0.0:
		strike_t += delta
		var L: float = STRIKE_LEN[strike_combo]
		var k := strike_t / L
		if k > 0.33 and k < 0.6:
			_strike_hits()
		if k >= 1.0:
			strike_t = -1.0
			combo_window = 0.28 if strike_combo < 2 else 0.0

	var pre_vy := velocity.y
	move_and_slide()
	on_floor = is_on_floor()
	on_moving = false
	for i in get_slide_collision_count():
		var cc := get_slide_collision(i).get_collider()
		if cc is AnimatableBody2D or (cc is Node and cc.is_in_group("mover")):
			on_moving = true
	# bouncy awnings
	if pre_vy > 150.0:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var col := c.get_collider()
			if col and col.has_meta("bounce") and c.get_normal().y < -0.6:
				velocity.y = -float(col.get_meta("bounce")) * (1.0 if _held("jump") or pre_vy > 600.0 else 0.82)
				stomping = false
				on_floor = false
				rig.notify_land(0.7)
				Sfx.play_var("bounce", -4.0)
				Fx.dust(global_position + Vector2(0, 48), 5, 0.7)
				break

	# landing
	if on_floor and not was_on_floor:
		var strength := clampf(pre_vy / 1100.0, 0.0, 1.0)
		if stomping:
			_stomp_impact()
		else:
			rig.notify_land(strength * 0.8)
			if strength > 0.35:
				Sfx.play_var("land", -8.0 + strength * 6.0)
			if strength > 0.75:
				made_noise.emit(global_position, 240.0)
				Fx.dust(global_position + Vector2(0, 48), 6, 0.9)
	was_on_floor = on_floor
	if stomping and on_floor:
		stomping = false

	# stomp onto enemies' heads bounces
	if stomping:
		for h in get_tree().get_nodes_in_group("hittable"):
			if h.has_method("hurt_rect") and h.hurt_rect().has_point(global_position + Vector2(0, 50)):
				_stomp_impact()
				stomping = false
				velocity.y = -720.0
				break

	# hazards
	if invuln <= 0.0:
		var me := Rect2(global_position + Vector2(-14, -46), Vector2(28, 94))
		for h in get_tree().get_nodes_in_group("hazard"):
			if h.has_method("hazard_rect") and h.hazard_rect().intersects(me):
				take_damage(h.global_position)
				break

	# footsteps
	if on_floor and absf(velocity.x) > 60.0:
		step_acc += absf(velocity.x) * delta
		if step_acc > 62.0:
			step_acc = 0.0
			Sfx.play("step%d" % (randi() % 3), -12.0, randf_range(0.9, 1.1))

	# fell out
	if global_position.y > kill_y:
		fall_out()

	_update_rig(on_floor)

func _standing_on_oneway() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		if col is CollisionObject2D and col.get_collision_layer_value(2):
			return true
	return false

func _strike_rect() -> Rect2:
	var big := strike_combo == 2
	var sz := Vector2(118, 104) if big else Vector2(92, 84)
	var center := global_position + Vector2(facing * (sz.x * 0.5 + 4), -14)
	return Rect2(center - sz * 0.5, sz)

func _strike_hits() -> void:
	var r := _strike_rect()
	var landed := false
	for h in get_tree().get_nodes_in_group("hittable"):
		if strike_hit.has(h.get_instance_id()):
			continue
		if h.has_method("hurt_rect") and h.hurt_rect().intersects(r):
			strike_hit[h.get_instance_id()] = true
			var dmg := 2 if strike_combo == 2 else 1
			if h.take_hit(dmg, global_position, "strike"):
				landed = true
	if not strike_hit.has(-1):
		strike_hit[-1] = true
		Sfx.play("strike%d" % strike_combo, -3.0 if landed else -7.0)
		made_noise.emit(global_position, 430.0)
		Fx.arc(global_position + Vector2(facing * 30, -16), facing, 1.25 if strike_combo == 2 else 1.0)
		struck.emit(strike_combo)
	if landed:
		_hitstop(0.055)
		_shake(4.0)

func _stomp_impact() -> void:
	made_noise.emit(global_position, 620.0)
	rig.notify_land(1.0)
	Sfx.play("stomp", -2.0)
	Fx.ring(global_position + Vector2(0, 46), 1.6, Color(1.0, 0.85, 0.45), 0.5)
	Fx.dust(global_position + Vector2(0, 48), 10, 1.3)
	_shake(9.0)
	var c := global_position + Vector2(0, 40)
	for h in get_tree().get_nodes_in_group("hittable"):
		if h.has_method("hurt_rect"):
			var hr: Rect2 = h.hurt_rect()
			var closest := Vector2(clampf(c.x, hr.position.x, hr.end.x), clampf(c.y, hr.position.y, hr.end.y))
			if closest.distance_to(c) < 110.0:
				h.take_hit(2, global_position, "stomp")

func take_damage(from: Vector2) -> void:
	if invuln > 0.0 or fainted or control_locked:
		return
	GameState.damage(1)
	Sfx.play("hurt", -2.0)
	invuln = 1.7
	hurt_t = 0.38
	stomping = false
	strike_t = -1.0
	var d := signf(global_position.x - from.x)
	if d == 0.0:
		d = -facing
	velocity = Vector2(d * 360.0, -460.0)
	rig.flash = 1.0
	_shake(7.0)
	if GameState.hearts <= 0:
		_faint()

var fainted := false

func fall_out() -> void:
	if fainted:
		return
	GameState.damage(1)
	Sfx.play("hurt", -2.0)
	if GameState.hearts <= 0:
		_faint()
		return
	if fall_respawn.is_valid():
		global_position = fall_respawn.call()
		velocity = Vector2.ZERO
		stomping = false
		strike_t = -1.0
		hurt_t = 0.0
	else:
		respawn()
	invuln = 1.2

func _faint() -> void:
	if fainted:
		return
	fainted = true
	velocity = Vector2.ZERO
	died.emit()

func respawn() -> void:
	fainted = false
	global_position = respawn_pos
	velocity = Vector2.ZERO
	stomping = false
	strike_t = -1.0
	hurt_t = 0.0

func _hitstop(d: float) -> void:
	Engine.time_scale = 0.05
	var tm := get_tree().create_timer(d, true, false, true)
	tm.timeout.connect(func(): Engine.time_scale = 1.0)

func _shake(a: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(a)

func _update_rig(on_floor: bool) -> void:
	rig.vel = velocity
	rig.on_floor = on_floor
	rig.facing = facing
	rig.speed_ratio = absf(velocity.x) / RUN
	var st := "idle"
	if hurt_t > 0.0:
		st = "hurt"
		rig.expression = "hurt"
	elif stomping:
		st = "stomp"
		rig.expression = "determined"
	elif strike_t >= 0.0:
		st = "strike"
		rig.strike_t = strike_t / STRIKE_LEN[strike_combo]
		rig.strike_combo = strike_combo
		rig.expression = "determined"
	elif not on_floor:
		st = "glide" if gliding or in_updraft else ("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 25.0:
		st = "run"
	if st != "hurt" and st != "strike" and st != "stomp":
		if rig.expression in ["hurt", "determined"] and invuln <= 0.0:
			rig.expression = "neutral"
	rig.state = st
	# invulnerability blink
	rig.modulate.a = 0.45 if (invuln > 0.0 and int(invuln * 14.0) % 2 == 0) else 1.0
