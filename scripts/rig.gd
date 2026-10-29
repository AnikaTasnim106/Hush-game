class_name Rig
extends Node2D
## Procedural vector character rig.
## Origin = point between the feet on the ground. Local +x = facing direction.
## The owner sets the public state each frame; the rig blends a pose toward it,
## solves 2-bone IK for arms/legs, simulates scarf/hair with verlet, and draws.

# ------------------------------------------------------------------ public state
var state := "idle"          # idle run jump fall strike stomp hurt land talk wake cheer frozen
var vel := Vector2.ZERO
var on_floor := true
var facing := 1.0
var speed_ratio := 0.0
var strike_t := 0.0          # 0..1 progress through a strike
var strike_combo := 0
var expression := "neutral"  # neutral happy sad surprised scared determined hurt laugh worried
var talking := false
var look_at_global = null    # Vector2 or null
var freeze := 0.0            # 0 = full colour, 1 = stone-grey frozen
var frozen_pose := {}        # pose override used while state == "frozen"
var flash := 0.0             # white hit flash
var wind := 40.0             # scarf/hair wind (px/s^2, +x world)
var carry := ""              # "" | "lamp_pole" | "tray"

# ------------------------------------------------------------------ config
var cfg := {
	"scale": 1.0,
	"thigh": 25.0, "shin": 25.0, "upper": 19.0, "fore": 18.0,
	"torso": 35.0, "neck": 4.0, "head_r": 17.0,
	"w_shoulder": 22.0, "w_hip": 20.0, "skirt": 10.0, "belly": 0.0,
	"leg_w": 9.0, "arm_w": 7.0,
	"skin": Color("f1c7a4"), "hair": Color("4a2c22"), "coat": Color("3d5a80"),
	"coat_dark": Color("2c4362"), "pants": Color("3b3a4a"), "shoes": Color("5a3b2a"),
	"accent": Color("d1453b"), "outline": Color("1b1720"),
	"hair_style": "bob", "scarf": true, "bell": true,
	"hat": "", "beard": false, "mustache": false, "apron": false, "goggles": false,
	"cheeks": true, "eye_size": 1.0,
}

func setup(c: Dictionary) -> void:
	for k in c:
		cfg[k] = c[k]
	_init_chains()

# ------------------------------------------------------------------ internal pose
var P := {}   # current blended pose
var _t := 0.0
var _phase := 0.0
var _blink := 0.0
var _blink_timer := 2.0
var _face := {"brow": 0.0, "brow_y": 0.0, "eye": 1.0, "happy": 0.0, "mouth": 0.2, "open": 0.0}
var _turn := 1.0
var _land_squash := 0.0
var _gesture_t := 0.0
var _gesture := Vector2.ZERO
var _look := Vector2(1, 0)

var scarf: PackedVector2Array = []
var scarf_prev: PackedVector2Array = []
var tufts := []   # array of [points, prev]

const SCARF_N := 9
const SCARF_SEG := 7.0

func _ready() -> void:
	if scarf.is_empty():
		_init_chains()
	P = _pose_idle(0.0)

func _init_chains() -> void:
	var anchor := global_position + Vector2(0, -90)
	scarf.resize(SCARF_N)
	scarf_prev.resize(SCARF_N)
	for i in SCARF_N:
		scarf[i] = anchor + Vector2(-i * SCARF_SEG, i * 2.0)
		scarf_prev[i] = scarf[i]
	tufts.clear()
	for k in 3:
		var pts: PackedVector2Array = []
		var prv: PackedVector2Array = []
		for i in 3:
			pts.append(anchor)
			prv.append(anchor)
		tufts.append([pts, prv])

func notify_land(strength: float) -> void:
	_land_squash = clamp(strength, 0.0, 1.0)

# ------------------------------------------------------------------ pose library
# Pose fields (local, facing +x):
#  lean (rad, + = forward), hip (px down offset), sq (y scale), head (rad tilt),
#  hf/hb: front/back hand target relative to shoulder,
#  ff/fb: front/back foot target relative to origin (ground).
func _pose_idle(t: float) -> Dictionary:
	var br := sin(t * 2.2)
	return {
		"lean": 0.03 + br * 0.01, "hip": 1.5 + br * 1.0, "sq": 1.0 + br * 0.012, "head": br * 0.02,
		"hf": Vector2(6, 34 + br), "hb": Vector2(-5, 34 + br),
		"ff": Vector2(7, 0), "fb": Vector2(-7, 0),
	}

func _pose_run(t: float, sr: float) -> Dictionary:
	var s := 30.0 * (0.5 + sr * 0.7)   # stride half-length
	var lift := 14.0 * (0.4 + sr * 0.6)
	var ff := _foot_cycle(_phase, s, lift)
	var fb := _foot_cycle(fmod(_phase + 0.5, 1.0), s, lift)
	var bob := absf(sin(_phase * TAU)) * 3.5 * sr
	var arm := sin(_phase * TAU) * 15.0 * (0.4 + sr)
	return {
		"lean": 0.08 + 0.16 * sr, "hip": 4.0 * sr - bob, "sq": 1.0, "head": -0.06 * sr,
		"hf": Vector2(4 - arm, 26 - absf(arm) * 0.3), "hb": Vector2(-2 + arm, 26 - absf(arm) * 0.3),
		"ff": ff, "fb": fb,
	}

func _foot_cycle(p: float, s: float, lift: float) -> Vector2:
	if p < 0.5:  # stance: foot planted, sliding back relative to body
		var k := p / 0.5
		return Vector2(lerpf(s, -s, k), 0.0)
	var k2 := (p - 0.5) / 0.5  # swing
	var e := k2 * k2 * (3.0 - 2.0 * k2)
	return Vector2(lerpf(-s, s, e), -sin(k2 * PI) * lift)

func _pose_air(vy: float) -> Dictionary:
	var up := clampf(-vy / 800.0, -1.0, 1.0)  # +1 rising, -1 falling
	if up > 0.0:
		return {
			"lean": 0.12, "hip": -2.0, "sq": 1.0 + 0.08 * up, "head": -0.1,
			"hf": Vector2(14, -6 - 10 * up), "hb": Vector2(-16, 8),
			"ff": Vector2(12, -20 - 6 * up), "fb": Vector2(-10, -8),
		}
	var d := -up
	return {
		"lean": 0.05, "hip": -2.0, "sq": 1.0 - 0.03 * d, "head": 0.08 * d,
		"hf": Vector2(20, 4 - 8 * d), "hb": Vector2(-20, 2 - 8 * d),
		"ff": Vector2(9, -6 + 6 * d), "fb": Vector2(-8, -10 + 8 * d),
	}

func _pose_strike(t: float, combo: int, grounded: bool) -> Dictionary:
	# t: 0..1 ; anticipation 0-.28, swing .28-.5, follow .5-1
	var reach: float = (cfg.upper + cfg.fore) * 0.95
	var a0 := -2.5; var a1 := 0.55; var lean0 := -0.12; var lean1 := 0.2
	if combo == 1:
		a0 = 0.9; a1 = -1.2; lean0 = 0.15; lean1 = -0.05
	elif combo == 2:
		a0 = -3.0; a1 = 0.9; lean0 = -0.2; lean1 = 0.3
	var ang: float
	var lean: float
	if t < 0.28:
		var k := t / 0.28
		k = 1.0 - pow(1.0 - k, 2.0)
		ang = lerpf(0.9, a0, k)
		lean = lerpf(0.05, lean0, k)
	elif t < 0.5:
		var k := (t - 0.28) / 0.22
		k = k * k
		ang = lerpf(a0, a1, k)
		lean = lerpf(lean0, lean1, k)
	else:
		var k := (t - 0.5) / 0.5
		k = k * k * (3.0 - 2.0 * k)
		ang = lerpf(a1, a1 + 0.25, k)
		lean = lerpf(lean1, 0.06, k)
	var hand: Vector2 = Vector2(cos(ang), sin(ang)) * reach
	var base := _pose_idle(_t)
	base["lean"] = lean
	base["hf"] = hand
	base["hb"] = Vector2(-12, 18)
	base["head"] = -lean * 0.5
	if grounded:
		base["ff"] = Vector2(15, 0)
		base["fb"] = Vector2(-13, 0)
		base["hip"] = 6.0
	else:
		var air := _pose_air(vel.y)
		base["ff"] = air["ff"]
		base["fb"] = air["fb"]
		base["hip"] = -2.0
	return base

func _pose_stomp() -> Dictionary:
	return {
		"lean": 0.0, "hip": -6.0, "sq": 0.95, "head": 0.15,
		"hf": Vector2(4, -34), "hb": Vector2(-8, -28),
		"ff": Vector2(8, -26), "fb": Vector2(-8, -24),
	}

func _pose_hurt() -> Dictionary:
	return {
		"lean": -0.3, "hip": 2.0, "sq": 1.0, "head": -0.3,
		"hf": Vector2(18, -18), "hb": Vector2(-18, -20),
		"ff": Vector2(14, -6), "fb": Vector2(-6, 0),
	}

func _pose_cheer(t: float) -> Dictionary:
	var b := absf(sin(t * 6.0))
	return {
		"lean": -0.05, "hip": -b * 6.0, "sq": 1.0 + b * 0.04, "head": -0.15,
		"hf": Vector2(10, -36), "hb": Vector2(-8, -34),
		"ff": Vector2(7, -b * 8.0), "fb": Vector2(-7, -b * 8.0),
	}

func _pose_wake(t: float) -> Dictionary:
	# stumble out of the shell: arms out for balance, wobble
	var w := sin(t * 9.0) * exp(-t * 1.6)
	return {
		"lean": 0.25 * w, "hip": 4.0, "sq": 1.0, "head": 0.2 * w,
		"hf": Vector2(22, 6 + w * 8.0), "hb": Vector2(-22, 6 - w * 8.0),
		"ff": Vector2(10, 0), "fb": Vector2(-10, 0),
	}

# ------------------------------------------------------------------ update
func _process(delta: float) -> void:
	_t += delta
	var sr := clampf(speed_ratio, 0.0, 1.0)
	if state == "run":
		var stride := 60.0 * (0.5 + sr * 0.7)
		_phase = fmod(_phase + absf(vel.x) * delta / (stride * 2.0) + delta * 0.2, 1.0)

	var target: Dictionary
	var rate := 14.0
	match state:
		"run": target = _pose_run(_t, sr); rate = 22.0
		"glide": target = {"lean":0.1,"hip":-3.0,"sq":1.02,"head":-0.12,"hf":Vector2(12,-49),"hb":Vector2(-31,-8),"ff":Vector2(13,-9),"fb":Vector2(-13,-15)}; rate = 10.0
		"jump", "fall": target = _pose_air(vel.y); rate = 12.0
		"strike": target = _pose_strike(strike_t, strike_combo, on_floor); rate = 40.0
		"stomp": target = _pose_stomp(); rate = 30.0
		"hurt": target = _pose_hurt(); rate = 20.0
		"cheer": target = _pose_cheer(_t); rate = 18.0
		"wake": target = _pose_wake(_t); rate = 16.0
		"frozen":
			target = _pose_idle(0.0)
			for k in frozen_pose:
				target[k] = frozen_pose[k]
			rate = 60.0
		_:
			target = _pose_idle(_t)
			if state == "talk" or talking:
				_update_gesture(delta)
				target["hf"] = target["hf"] + _gesture
	if P.is_empty():
		P = target.duplicate()
	var k := 1.0 - exp(-rate * delta)
	for key in target:
		if P.has(key):
			if P[key] is Vector2:
				P[key] = (P[key] as Vector2).lerp(target[key], k)
			else:
				P[key] = lerpf(P[key], target[key], k)
		else:
			P[key] = target[key]

	_land_squash = move_toward(_land_squash, 0.0, delta * 5.0)
	_turn = move_toward(_turn, signf(facing) if facing != 0.0 else _turn, delta * 14.0)
	scale = Vector2(_turn if absf(_turn) > 0.08 else 0.08 * signf(_turn + 0.0001), 1.0) * cfg.scale
	flash = move_toward(flash, 0.0, delta * 6.0)

	_update_face(delta)
	if state != "frozen":
		_step_chains(delta)
	queue_redraw()

func _update_gesture(delta: float) -> void:
	_gesture_t -= delta
	if _gesture_t <= 0.0:
		_gesture_t = randf_range(0.5, 1.4)
		_gesture = Vector2(randf_range(4, 16), randf_range(-24, -6)) if randf() < 0.6 else Vector2.ZERO

func _update_face(delta: float) -> void:
	var tgt := {"brow": 0.0, "brow_y": 0.0, "eye": 1.0, "happy": 0.0, "mouth": 0.15, "open": 0.0}
	match expression:
		"happy": tgt = {"brow": -0.1, "brow_y": -1.0, "eye": 1.0, "happy": 1.0, "mouth": 0.9, "open": 0.15}
		"laugh": tgt = {"brow": -0.15, "brow_y": -2.0, "eye": 1.0, "happy": 1.0, "mouth": 1.0, "open": 0.8}
		"sad": tgt = {"brow": 0.45, "brow_y": 0.0, "eye": 0.75, "happy": 0.0, "mouth": -0.6, "open": 0.0}
		"worried": tgt = {"brow": 0.35, "brow_y": -1.0, "eye": 1.0, "happy": 0.0, "mouth": -0.3, "open": 0.1}
		"surprised": tgt = {"brow": 0.1, "brow_y": -3.5, "eye": 1.25, "happy": 0.0, "mouth": 0.0, "open": 0.7}
		"scared": tgt = {"brow": 0.5, "brow_y": -2.5, "eye": 1.2, "happy": 0.0, "mouth": -0.5, "open": 0.4}
		"determined": tgt = {"brow": -0.45, "brow_y": 1.0, "eye": 0.85, "happy": 0.0, "mouth": -0.05, "open": 0.0}
		"hurt": tgt = {"brow": 0.4, "brow_y": 1.0, "eye": 0.3, "happy": 0.0, "mouth": -0.7, "open": 0.5}
	var k := 1.0 - exp(-12.0 * delta)
	for key in tgt:
		_face[key] = lerpf(_face[key], tgt[key], k)
	if talking:
		_face["open"] = maxf(_face["open"], (0.5 + 0.5 * sin(_t * 22.0)) * 0.6)
	# blink
	if state != "frozen":
		_blink_timer -= delta
		if _blink_timer <= 0.0:
			_blink = 1.0
			_blink_timer = randf_range(2.0, 4.5)
		_blink = move_toward(_blink, 0.0, delta * 9.0)
	# look direction
	var want := Vector2(1, 0)
	if look_at_global != null:
		var d: Vector2 = to_local(look_at_global) - _head_center()
		if d.length() > 1.0:
			want = d.normalized()
	_look = _look.lerp(want, 1.0 - exp(-8.0 * delta))

# ------------------------------------------------------------------ verlet chains
func _step_chains(delta: float) -> void:
	if scarf.is_empty():
		return
	var dt := minf(delta, 1.0 / 30.0)
	var neck_g := to_global(_neck_point() + Vector2(-3, 3))
	var grav := Vector2(wind, 520.0)
	if state == "glide": grav = Vector2(-facing*1100,-850 if vel.y < 0 else -100)
	# scarf
	scarf[0] = neck_g
	for i in range(1, SCARF_N):
		var cur := scarf[i]
		var v := (cur - scarf_prev[i]) * 0.93
		scarf_prev[i] = cur
		scarf[i] = cur + v + grav * dt * dt + Vector2(sin(_t * 7.0 + i) * 6.0, 0) * dt
	for _it in 4:
		scarf[0] = neck_g
		for i in range(1, SCARF_N):
			var d := scarf[i] - scarf[i - 1]
			var l := d.length()
			if l > 0.0001:
				scarf[i] = scarf[i - 1] + d / l * SCARF_SEG
	# hair tufts
	var hc := to_global(_head_center())
	var r: float = cfg.head_r * cfg.scale
	for k in tufts.size():
		var pts: PackedVector2Array = tufts[k][0]
		var prv: PackedVector2Array = tufts[k][1]
		var base := hc + Vector2(-facing * r * (0.55 + k * 0.15), -r * (0.55 - k * 0.35))
		pts[0] = base
		for i in range(1, pts.size()):
			var cur := pts[i]
			var v := (cur - prv[i]) * 0.86
			prv[i] = cur
			pts[i] = cur + v + Vector2(wind * 0.5, 300.0) * dt * dt
		for _it in 3:
			pts[0] = base
			for i in range(1, pts.size()):
				var d := pts[i] - pts[i - 1]
				var l := d.length()
				var seg: float = 6.0 * cfg.scale
				if l > 0.0001:
					pts[i] = pts[i - 1] + d / l * seg
		tufts[k][0] = pts
		tufts[k][1] = prv

# ------------------------------------------------------------------ skeleton helpers
func _hip() -> Vector2:
	var hip_h: float = cfg.thigh + cfg.shin - 3.0
	return Vector2(0, -hip_h + P.get("hip", 0.0))

func _torso_dir() -> Vector2:
	var l: float = P.get("lean", 0.0)
	return Vector2(sin(l), -cos(l))

func _neck_point() -> Vector2:
	var sq: float = P.get("sq", 1.0) * (1.0 - _land_squash * 0.15)
	return _hip() + _torso_dir() * cfg.torso * sq

func _shoulder() -> Vector2:
	var sq: float = P.get("sq", 1.0) * (1.0 - _land_squash * 0.15)
	return _hip() + _torso_dir() * (cfg.torso - 5.0) * sq

func _head_center() -> Vector2:
	var hd := _torso_dir().rotated(P.get("head", 0.0))
	return _neck_point() + hd * (cfg.neck + cfg.head_r)

static func ik(a: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> Array:
	# returns [joint, end]; bend = +1 / -1 chooses the elbow/knee side
	var d := target - a
	var dist := clampf(d.length(), 0.001, l1 + l2 - 0.01)
	var dir := d.normalized() if d.length() > 0.001 else Vector2(0, 1)
	var cos_a := clampf((l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist), -1.0, 1.0)
	var ang := acos(cos_a)
	var joint := a + dir.rotated(ang * bend) * l1
	var end := a + dir * dist
	return [joint, end]

# ------------------------------------------------------------------ colour helpers
func _c(col: Color, outline := false) -> Color:
	var c := col
	if outline and freeze > 0.0:
		return col.lerp(Color(0.33, 0.36, 0.42), freeze)
	if freeze > 0.0:
		var g := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
		var stone := Color(0.62 + g * 0.3, 0.66 + g * 0.3, 0.72 + g * 0.28, c.a)
		c = c.lerp(stone, freeze)
	if flash > 0.0:
		c = c.lerp(Color(1, 1, 1, c.a), flash)
	return c

# ------------------------------------------------------------------ drawing
func _limb(a: Vector2, j: Vector2, b: Vector2, w: float, col: Color, col2: Color) -> void:
	var o: Color = _c(cfg.outline, true)
	var ow := w + 4.0
	draw_line(a, j, o, ow, true)
	draw_line(j, b, o, ow, true)
	draw_circle(a, ow * 0.5, o)
	draw_circle(j, ow * 0.5, o)
	draw_circle(b, ow * 0.5, o)
	draw_line(a, j, _c(col), w, true)
	draw_line(j, b, _c(col2), w, true)
	draw_circle(a, w * 0.5, _c(col))
	draw_circle(j, w * 0.5, _c(col2))
	draw_circle(b, w * 0.5, _c(col2))

func _shape(pts: PackedVector2Array, fill: Color, outline_w := 3.0) -> void:
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, _c(fill))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, _c(cfg.outline, true), outline_w, true)

func _ellipse(center: Vector2, rx: float, ry: float, rot := 0.0, n := 18) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts

func _draw() -> void:
	if P.is_empty():
		return
	var hip := _hip()
	var td := _torso_dir()
	var tn := Vector2(-td.y, td.x)  # perpendicular (points "forward-down" when upright -> +x)
	var sh := _shoulder()
	var neck := _neck_point()
	var hc := _head_center()

	# ground shadow
	if on_floor and state != "frozen":
		draw_colored_polygon(_ellipse(Vector2(0, 1), 22, 4.5), Color(0, 0, 0, 0.22))

	# --- scarf tail (behind body)
	if cfg.scarf and scarf.size() == SCARF_N:
		_draw_scarf_tail()

	# --- hair tufts behind head
	_draw_tufts()

	# --- back arm & back leg
	var hb: Vector2 = P["hb"]
	var arm_b := ik(sh + Vector2(-3, 0), sh + Vector2(-3, 0) + hb, cfg.upper, cfg.fore, 1.0)
	var fb: Vector2 = P["fb"]
	var leg_b := ik(hip + Vector2(-3, 0), fb + Vector2(0, -3), cfg.thigh, cfg.shin, -1.0)
	var dark := Color(0.82, 0.82, 0.86)
	_limb(sh + Vector2(-3, 0), arm_b[0], arm_b[1], cfg.arm_w, cfg.coat_dark, cfg.coat_dark)
	draw_circle(arm_b[1], cfg.arm_w * 0.62 + 2, _c(cfg.outline, true))
	draw_circle(arm_b[1], cfg.arm_w * 0.62, _c(cfg.skin * dark))
	if carry == "crook":
		draw_line(arm_b[1]+Vector2(0,45),arm_b[1]+Vector2(0,-80),_c(Color("b89561")),5,true)
		draw_arc(arm_b[1]+Vector2(12,-80),12,PI,TAU+0.5,16,_c(Color("b89561")),5,true)
	if carry == "lamp_pole":
		_draw_lamp_pole(arm_b[1])
	_limb(hip + Vector2(-3, 0), leg_b[0], leg_b[1], cfg.leg_w, cfg.pants * dark, cfg.pants * dark)
	_draw_shoe(leg_b[1], cfg.shoes * dark)

	# --- front leg
	var ff: Vector2 = P["ff"]
	var leg_f := ik(hip + Vector2(3, 0), ff + Vector2(0, -3), cfg.thigh, cfg.shin, -1.0)
	_limb(hip + Vector2(3, 0), leg_f[0], leg_f[1], cfg.leg_w, cfg.pants, cfg.pants)
	_draw_shoe(leg_f[1], cfg.shoes)

	# --- torso / coat
	_draw_torso(hip, sh, td, tn)

	# --- scarf wrap at neck
	if cfg.scarf:
		var nw := neck + td * -2.0
		draw_line(nw - tn * 10, nw + tn * 10, _c(cfg.outline, true), 12, true)
		draw_line(nw - tn * 9, nw + tn * 9, _c(cfg.accent), 8, true)
		draw_circle(nw + tn * 9, 4, _c(cfg.accent))
		draw_circle(nw - tn * 9, 4, _c(cfg.accent))

	# --- head
	_draw_head(hc)

	# --- front arm (+ bell)
	var hf: Vector2 = P["hf"]
	var arm_f := ik(sh + Vector2(3, 0), sh + Vector2(3, 0) + hf, cfg.upper, cfg.fore, 1.0 if hf.y > -10 else -1.0)
	_limb(sh + Vector2(3, 0), arm_f[0], arm_f[1], cfg.arm_w, cfg.coat, cfg.coat)
	if cfg.bell:
		_draw_bell(arm_f[1], (arm_f[1] - arm_f[0]).angle())
	if carry == "guitar":
		var gc := sh+Vector2(4,28)
		_shape(_ellipse(gc,24,30),Color("c5934e"),3)
		draw_circle(gc,9,_c(Color("443329")))
		draw_line(gc+Vector2(12,-10),gc+Vector2(50,-46),_c(Color("65432c")),9,true)
		for si in 3: draw_line(gc+Vector2(si*2,7),gc+Vector2(49+si,-44),_c(Color("e5d6b4")),0.8,true)
	if carry == "tray":
		_draw_tray(arm_f[1], arm_b[1])
	draw_circle(arm_f[1], cfg.arm_w * 0.62 + 2, _c(cfg.outline, true))
	draw_circle(arm_f[1], cfg.arm_w * 0.62, _c(cfg.skin))

func _draw_shoe(p: Vector2, col: Color) -> void:
	var pts := _ellipse(p + Vector2(4, 1), 8.5, 4.5, 0.0, 14)
	_shape(pts, col, 2.5)

func _draw_torso(hip: Vector2, sh: Vector2, td: Vector2, tn: Vector2) -> void:
	var ws: float = cfg.w_shoulder * 0.5
	var wh: float = cfg.w_hip * 0.5
	var belly: float = cfg.belly
	var skirt: float = cfg.skirt
	var flare := clampf(absf(vel.x) / 400.0, 0.0, 1.0) * 4.0 + (3.0 if not on_floor else 0.0)
	var top := sh + td * 6.0
	var mid := hip.lerp(sh, 0.45)
	var pts: PackedVector2Array = [
		top - tn * ws, top + tn * ws * 0.9,
		mid + tn * (wh + belly), hip + tn * (wh + belly * 0.6) - td * (skirt * 0.3),
		hip + tn * (wh + 2 + flare) - td * skirt,
		hip - tn * (wh + 2 + flare * 1.6) - td * skirt,
		hip - tn * wh - td * (skirt * 0.3), mid - tn * (wh + 1),
	]
	_shape(pts, cfg.coat, 3.0)
	# coat details: front seam + buttons + collar shadow
	var seam_a := top + tn * ws * 0.35
	var seam_b := hip + tn * (wh * 0.5) + td * -skirt
	draw_line(seam_a, seam_b, _c(cfg.coat_dark), 2.0, true)
	for i in 3:
		draw_circle(seam_a.lerp(seam_b, 0.25 + i * 0.22) + tn * 3, 1.6, _c(cfg.coat_dark))
	if cfg.apron:
		var ap: PackedVector2Array = [
			top.lerp(mid, 0.5) + tn * 2, top.lerp(mid, 0.5) + tn * (ws + 2),
			hip + tn * (wh + belly * 0.6 + 2) - td * (skirt + 2), hip + tn * 0 - td * (skirt + 2),
		]
		_shape(ap, Color("efe8dc"), 2.0)
	# belt
	var bl := hip + td * 3.0
	draw_line(bl - tn * (wh + 1), bl + tn * (wh + belly * 0.7 + 1), _c(cfg.outline, true), 4.0, true)

func _draw_head(hc: Vector2) -> void:
	var r: float = cfg.head_r
	var o: Color = _c(cfg.outline, true)
	var ht: float = P.get("head", 0.0) + P.get("lean", 0.0)
	# hair back mass
	var hs: String = cfg.hair_style
	if hs == "braid":
		for i in 7:
			var bc := hc+Vector2(-18+sin(i*2.5)*3,8+i*7)
			draw_circle(bc,8-i*0.5,o)
			draw_circle(bc,6-i*0.5,_c(cfg.hair))
	if hs == "bob" or hs == "long":
		var back := _ellipse(hc + Vector2(-r * 0.25, -r * 0.05).rotated(ht), r * 1.12, r * (1.15 if hs == "bob" else 1.4), ht, 20)
		if hs == "long":
			back = _ellipse(hc + Vector2(-r * 0.35, r * 0.35).rotated(ht), r * 1.05, r * 1.55, ht + 0.1, 20)
		_shape(back, cfg.hair, 3.0)
	# head
	draw_circle(hc, r + 2.0, o)
	draw_circle(hc, r, _c(cfg.skin))
	# ear
	if cfg.hair_style in ["short", "bald"]:
		var ear := hc + Vector2(-r * 0.5, r * 0.15).rotated(ht)
		draw_circle(ear, r * 0.22 + 1.5, o)
		draw_circle(ear, r * 0.22, _c(cfg.skin * Color(0.93, 0.88, 0.86)))
	# nose (profile bump)
	var nose := hc + Vector2(r * 0.98, r * 0.08).rotated(ht)
	draw_circle(nose, r * 0.16 + 1.5, o)
	draw_circle(nose, r * 0.16, _c(cfg.skin))
	draw_circle(hc + Vector2(r * 0.85, r * 0.06).rotated(ht), r * 0.13, _c(cfg.skin))
	_draw_face(hc, r, ht)
	# hair front / hats
	match hs:
		"bob", "braid":
			var fringe: PackedVector2Array = []
			for i in 9:
				var a := lerpf(-3.1, -0.55, i / 8.0)
				var rr := r * (1.07 if i % 2 == 0 else 0.92)
				fringe.append(hc + Vector2(cos(a), sin(a)).rotated(ht) * rr)
			fringe.append(hc + Vector2(r * 0.62, -r * 0.42).rotated(ht))
			fringe.append(hc + Vector2(r * 0.15, -r * 0.5).rotated(ht))
			fringe.append(hc + Vector2(-r * 0.45, -r * 0.15).rotated(ht))
			fringe.append(hc + Vector2(-r * 0.75, r * 0.45).rotated(ht))
			_shape(fringe, cfg.hair, 2.5)
		"long":
			var top: PackedVector2Array = []
			for i in 8:
				var a := lerpf(-3.0, -0.4, i / 7.0)
				top.append(hc + Vector2(cos(a), sin(a)).rotated(ht) * r * 1.07)
			top.append(hc + Vector2(r * 0.3, -r * 0.3).rotated(ht))
			_shape(top, cfg.hair, 2.5)
		"bald":
			pass
		"short":
			var cap: PackedVector2Array = []
			for i in 8:
				var a := lerpf(-3.1, -0.5, i / 7.0)
				cap.append(hc + Vector2(cos(a), sin(a)).rotated(ht) * r * 1.05)
			cap.append(hc + Vector2(r * 0.2, -r * 0.45).rotated(ht))
			_shape(cap, cfg.hair, 2.5)
	if hs == "bun":
		var cap2: PackedVector2Array = []
		for i in 8:
			var a := lerpf(-3.1, -0.5, i / 7.0)
			cap2.append(hc + Vector2(cos(a), sin(a)).rotated(ht) * r * 1.05)
		cap2.append(hc + Vector2(r * 0.2, -r * 0.45).rotated(ht))
		_shape(cap2, cfg.hair, 2.5)
		var bun := hc + Vector2(-r * 0.7, -r * 0.75).rotated(ht)
		draw_circle(bun, r * 0.48 + 2.0, o)
		draw_circle(bun, r * 0.48, _c(cfg.hair))
	if cfg.get("glasses", false):
		for e in [Vector2(r * 0.74, -r * 0.1), Vector2(r * 0.3, -r * 0.1)]:
			draw_arc(hc + (e as Vector2).rotated(ht), r * 0.24, 0, TAU, 14, o, 2.0, true)
		draw_line(hc + Vector2(r * 0.42, -r * 0.12).rotated(ht), hc + Vector2(r * 0.62, -r * 0.12).rotated(ht), o, 2.0, true)
	if cfg.beard:
		var bd: PackedVector2Array = [
			hc + Vector2(-r * 0.2, r * 0.35).rotated(ht), hc + Vector2(r * 0.95, r * 0.35).rotated(ht),
			hc + Vector2(r * 0.7, r * 1.25).rotated(ht), hc + Vector2(r * 0.15, r * 1.45).rotated(ht),
			hc + Vector2(-r * 0.3, r * 0.9).rotated(ht),
		]
		_shape(bd, cfg.hair, 2.5)
	if cfg.mustache:
		var m := hc + Vector2(r * 0.72, r * 0.38).rotated(ht)
		draw_line(m - Vector2(r * 0.35, -2).rotated(ht), m + Vector2(r * 0.25, 2).rotated(ht), o, 6, true)
		draw_line(m - Vector2(r * 0.33, -2).rotated(ht), m + Vector2(r * 0.23, 2).rotated(ht), _c(cfg.hair), 3.5, true)
	match cfg.hat:
		"cap":
			var crown := _ellipse(hc + Vector2(-r * 0.05, -r * 0.62).rotated(ht), r * 1.0, r * 0.55, ht, 18)
			_shape(crown, cfg.accent, 2.5)
			var brim: PackedVector2Array = [
				hc + Vector2(r * 0.3, -r * 0.55).rotated(ht), hc + Vector2(r * 1.55, -r * 0.45).rotated(ht),
				hc + Vector2(r * 1.5, -r * 0.3).rotated(ht), hc + Vector2(r * 0.3, -r * 0.35).rotated(ht),
			]
			_shape(brim, cfg.accent * Color(0.8, 0.8, 0.8), 2.5)
		"baker":
			var band: PackedVector2Array = [
				hc + Vector2(-r * 0.95, -r * 0.5).rotated(ht), hc + Vector2(r * 0.95, -r * 0.5).rotated(ht),
				hc + Vector2(r * 0.9, -r * 0.95).rotated(ht), hc + Vector2(-r * 0.9, -r * 0.95).rotated(ht),
			]
			var puff := _ellipse(hc + Vector2(0, -r * 1.35).rotated(ht), r * 1.15, r * 0.65, ht, 18)
			_shape(puff, Color("f4efe6"), 2.5)
			_shape(band, Color("e6dfd2"), 2.5)
		"flat":
			var fc := _ellipse(hc + Vector2(r * 0.1, -r * 0.7).rotated(ht), r * 1.15, r * 0.45, ht - 0.08, 18)
			_shape(fc, cfg.accent, 2.5)
	if cfg.goggles:
		var g := hc + Vector2(r * 0.55, -r * 0.62).rotated(ht)
		draw_circle(g, r * 0.32 + 2, o)
		draw_circle(g, r * 0.32, _c(Color("b87333")))
		draw_circle(g, r * 0.2, _c(Color("9fd3d9")))

func _draw_face(hc: Vector2, r: float, ht: float) -> void:
	var o: Color = _c(cfg.outline, true)
	var es: float = cfg.eye_size
	var look := _look * 1.6
	var eye_open: float = _face["eye"] * (1.0 - _blink)
	if state == "frozen":
		eye_open = 0.12
	var eyes := [[Vector2(r * 0.74, -r * 0.1), 0.9], [Vector2(r * 0.3, -r * 0.1), 1.0]]
	for e in eyes:
		var p: Vector2 = hc + (e[0] as Vector2).rotated(ht)
		var s: float = e[1] * es
		if _face["happy"] > 0.5 and eye_open > 0.3:
			# happy closed arcs
			var arc: PackedVector2Array = []
			for i in 7:
				var a := lerpf(PI + 0.3, TAU - 0.3, i / 6.0)
				arc.append(p + Vector2(cos(a) * 3.2 * s, sin(a) * 3.0 * s + 2.0).rotated(ht))
			draw_polyline(arc, o, 2.2, true)
		elif eye_open < 0.25:
			draw_line(p - Vector2(3 * s, 0).rotated(ht), p + Vector2(3 * s, 0).rotated(ht), o, 2.0, true)
		else:
			var pts := _ellipse(p + look * 0.5, 2.4 * s, 3.8 * s * eye_open, ht, 12)
			draw_colored_polygon(pts, o)
			draw_circle(p + look * 0.5 + Vector2(0.9, -1.2).rotated(ht), 0.9 * s, Color(1, 1, 1, 0.9 * (1.0 - freeze)))
		# brow
		var by: float = -r * 0.5 + _face["brow_y"]
		var bang: float = _face["brow"] * (1.0 if e[1] == 1.0 else -1.0)
		var bc := hc + Vector2((e[0] as Vector2).x, by - 1.0).rotated(ht)
		var bd := Vector2(3.2 * s, 0).rotated(ht + bang)
		draw_line(bc - bd, bc + bd, o, 2.2, true)
	# cheeks
	if cfg.cheeks and freeze < 0.5:
		draw_circle(hc + Vector2(r * 0.42, r * 0.32).rotated(ht), r * 0.17, Color(0.95, 0.5, 0.5, 0.35))
	# mouth
	var mc := hc + Vector2(r * 0.55, r * 0.64).rotated(ht)
	var curve: float = _face["mouth"]
	var op: float = _face["open"]
	var mw := r * 0.2
	if op > 0.12:
		var mp: PackedVector2Array = []
		for i in 10:
			var a := TAU * i / 10.0
			mp.append(mc + Vector2(cos(a) * mw * 0.75, sin(a) * mw * 0.75 * op + curve * -1.0).rotated(ht))
		draw_colored_polygon(mp, _c(Color("5a2430")))
		var cl := mp.duplicate(); cl.append(mp[0])
		draw_polyline(cl, o, 1.8, true)
	else:
		var line: PackedVector2Array = []
		for i in 7:
			var x := lerpf(-mw, mw, i / 6.0)
			var y := -curve * 3.0 * pow(x / mw, 2.0) + curve * 1.0
			line.append(mc + Vector2(x, y).rotated(ht))
		draw_polyline(line, o, 1.7, true)

func _draw_bell(hand: Vector2, ang: float) -> void:
	# handheld brass bell, mouth pointing along the forearm
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var base := hand + dir * 3.0
	var mouth := hand + dir * 21.0
	var pts: PackedVector2Array = [
		base + nrm * 4.0, base - nrm * 4.0,
		hand + dir * 15.0 - nrm * 8.5, mouth - nrm * 12.0,
		mouth + nrm * 12.0, hand + dir * 15.0 + nrm * 8.5,
	]
	_shape(pts, Color("d9a441"), 2.5)
	draw_line(base + nrm * 2.0 + dir * 2.0, mouth + nrm * 7.0 - dir * 3.0, _c(Color("f7dc8a")), 2.5, true)
	draw_line(mouth - nrm * 12.5, mouth + nrm * 12.5, _c(Color("8a5a1c")), 3.0, true)
	draw_circle(mouth + dir * 3.0, 3.2, _c(cfg.outline, true))
	draw_circle(mouth + dir * 3.0, 2.0, _c(Color("8a5a1c")))

func _draw_lamp_pole(hand: Vector2) -> void:
	var top := hand + Vector2(-12, -70)
	var bot := hand + Vector2(4, 40)
	draw_line(bot, top, _c(cfg.outline, true), 6, true)
	draw_line(bot, top, _c(Color("5b4636")), 3, true)
	draw_line(top, top + Vector2(14, 2), _c(cfg.outline, true), 4, true)
	var lamp := top + Vector2(14, 12)
	if freeze < 0.5:
		draw_circle(lamp, 22, Color(1.0, 0.8, 0.4, 0.18))
	_shape(_ellipse(lamp, 6, 8), Color("f2c96b") if freeze < 0.5 else Color("8b8f98"), 2.0)

func _draw_tray(hf: Vector2, hb: Vector2) -> void:
	var a := hb + Vector2(-6, -3)
	var b := hf + Vector2(14, -3)
	draw_line(a, b, _c(cfg.outline, true), 6, true)
	draw_line(a, b, _c(Color("a7793f")), 3, true)
	for i in 3:
		var c := a.lerp(b, 0.2 + i * 0.3) + Vector2(0, -8)
		_shape(_ellipse(c, 9, 6), Color("d79a52"), 2.0)
		draw_line(c + Vector2(-4, -2), c + Vector2(4, -3), _c(Color("f3d29b")), 1.5, true)

func _draw_scarf_tail() -> void:
	var pts: PackedVector2Array = []
	for p in scarf:
		pts.append(to_local(p))
	var n := pts.size()
	var o: Color = _c(cfg.outline, true)
	var col: Color = _c(cfg.accent)
	for i in n - 1:
		var w := lerpf(10.0, 6.5, float(i) / (n - 1))
		draw_line(pts[i], pts[i + 1], o, w + 4.0, true)
		draw_circle(pts[i + 1], (w + 4.0) * 0.5, o)
	for i in n - 1:
		var w := lerpf(10.0, 6.5, float(i) / (n - 1))
		draw_line(pts[i], pts[i + 1], col, w, true)
		draw_circle(pts[i + 1], w * 0.5, col)
	# stripe + fringe at the end
	var tip := pts[n - 1]
	var td := (tip - pts[n - 2]).normalized()
	draw_line(pts[n - 3], pts[n - 2], _c(cfg.accent.lightened(0.35)), 2.0, true)
	for k in 3:
		var off := Vector2(-td.y, td.x) * (k - 1) * 2.6
		draw_line(tip + off, tip + off + td * 7.0, o, 3.0, true)
		draw_line(tip + off, tip + off + td * 6.0, col, 1.6, true)

func _draw_tufts() -> void:
	var hs: String = cfg.hair_style
	if not (hs in ["bob", "long"]):
		return
	for t in tufts:
		var pts: PackedVector2Array = t[0]
		var loc: PackedVector2Array = []
		for p in pts:
			loc.append(to_local(p))
		if loc.size() >= 2:
			draw_polyline(loc, _c(cfg.outline, true), 7.0, true)
			draw_polyline(loc, _c(cfg.hair), 4.0, true)
