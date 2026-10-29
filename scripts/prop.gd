class_name Prop
extends Node2D
## Procedurally drawn scenery. One node per piece; `kind` + `p` (params) decide the drawing.

var kind := ""
var p := {}
var t := 0.0
var animated := false
var lit := false
var lit_amount := 0.0
var rng_seed := 0

const INK := Color("1d1a22")

func _ready() -> void:
	if rng_seed == 0:
		rng_seed = int(global_position.x * 13.0 + global_position.y * 7.0) + 1
	animated = kind in ["line", "bunting", "water", "lamp", "fountain", "gate", "flag", "hanging_lantern", "candles"]
	set_process(animated)

func set_lit(v: bool) -> void:
	lit = v
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	lit_amount = move_toward(lit_amount, 1.0 if lit else 0.0, delta * 1.5)
	queue_redraw()

func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = rng_seed
	return r

func _box(r: Rect2, fill: Color, ow := 3.0) -> void:
	draw_rect(r, fill)
	draw_rect(r, INK, false, ow)

func _poly(pts: PackedVector2Array, fill: Color, ow := 3.0) -> void:
	draw_colored_polygon(pts, fill)
	var cl := pts.duplicate(); cl.append(pts[0])
	draw_polyline(cl, INK, ow, true)

func _draw() -> void:
	match kind:
		"wheat", "fence", "haystack", "barn", "roof_planks", "stream", "pond", "signpost", "ribbon_clue": _field_prop()
		"ground": _ground()
		"house": _house()
		"backhouse": _backhouse()
		"crate": _crate()
		"barrel": _barrel()
		"stall": _stall()
		"line": _line()
		"lamp": _lamp()
		"fountain": _fountain()
		"stage": _stage()
		"music_stand": _music_stand()
		"bunting": _bunting()
		"water": _water()
		"sign": _sign()
		"flowerbox": _flowerbox()
		"bench": _bench()
		"poster": _poster()
		"chimney": _chimney()
		"balcony": _balcony()
		"steps": _steps()
		"door": _door()
		"tower_base": _tower_base()
		"beam": _beam()
		"chalk": _chalk()
		"hanging_lantern": _hanging_lantern()
		"candles": _candles()
		"seats": _seats()
		"booth": _booth()
		"piano": _piano()
		"curtain": _curtain()
		"fallen_chandelier": _fallen_chandelier()
		"hall_floor": _hall_floor()
		"sheet": _sheet()
		"balcony_slab": _balcony_slab()
		"steps_block": _steps_block()

# ---------------------------------------------------------------- ground
func _ground() -> void:
	var w: float = p.get("w", 1000.0)
	var col: Color = p.get("col", Color("8a8178"))
	draw_rect(Rect2(0, 0, w, 900), Color("5b544e"))
	draw_rect(Rect2(0, 0, w, 26), col)
	draw_line(Vector2(0, 0), Vector2(w, 0), INK, 4.0)
	var r := _rng()
	var x := 0.0
	var row := 0
	while x < w:
		var bw := r.randf_range(26, 44)
		draw_rect(Rect2(x + 2, 4, bw - 4, 9), col.lightened(0.06 + r.randf() * 0.05))
		draw_rect(Rect2(x + bw * 0.5 + 2, 15, bw - 4, 9), col.darkened(0.04 + r.randf() * 0.05))
		x += bw
		row += 1
	draw_line(Vector2(0, 26), Vector2(w, 26), Color(INK, 0.6), 2.0)

# ---------------------------------------------------------------- buildings
func _house() -> void:
	var w: float = p.get("w", 300.0)
	var h: float = p.get("h", 240.0)
	var col: Color = p.get("col", Color("d9a066"))
	var trim: Color = p.get("trim", Color("6b4b3e"))
	var r := _rng()
	# wall
	_box(Rect2(0, 0, w, h + 60), col, 4.0)
	# plaster texture
	for i in int(w * h / 3000.0):
		var px := r.randf_range(8, w - 8)
		var py := r.randf_range(14, h)
		draw_rect(Rect2(px, py, r.randf_range(8, 22), 3), col.darkened(0.06))
	# cornice / roof edge
	_box(Rect2(-8, -12, w + 16, 16), trim, 3.0)
	draw_rect(Rect2(-8, 4, w + 16, 5), trim.darkened(0.3))
	# windows
	var cols := maxi(1, int((w - 40) / 90.0))
	var rows := maxi(1, int((h - 70) / 95.0))
	var lit_ratio: float = p.get("lit_ratio", 0.35)
	for cx in cols:
		for ry in rows:
			var wx := 30.0 + cx * ((w - 60.0) / maxf(1, cols - 1)) - 18.0 if cols > 1 else w * 0.5 - 18.0
			var wy := 34.0 + ry * 95.0
			if wy + 50 > h - 20 and p.get("door", false):
				continue
			var lit_w := r.randf() < lit_ratio
			_box(Rect2(wx - 4, wy - 4, 44, 62), trim, 3.0)
			draw_rect(Rect2(wx, wy, 36, 54), Color("f2c46d") if lit_w else Color("2a3448"))
			if lit_w:
				draw_rect(Rect2(wx - 10, wy - 10, 56, 74), Color(1.0, 0.8, 0.4, 0.08))
			draw_line(Vector2(wx + 18, wy), Vector2(wx + 18, wy + 54), trim, 3.0)
			draw_line(Vector2(wx, wy + 27), Vector2(wx + 36, wy + 27), trim, 3.0)
			# shutters
			if r.randf() < 0.5:
				draw_rect(Rect2(wx - 16, wy - 2, 12, 58), trim.lightened(0.15))
				draw_rect(Rect2(wx + 40, wy - 2, 12, 58), trim.lightened(0.15))
				draw_rect(Rect2(wx - 16, wy - 2, 12, 58), INK, false, 2.0)
				draw_rect(Rect2(wx + 40, wy - 2, 12, 58), INK, false, 2.0)
			# flower box
			if r.randf() < 0.3:
				_box(Rect2(wx - 6, wy + 56, 48, 10), Color("7a5a3a"), 2.0)
				for k in 4:
					draw_circle(Vector2(wx + k * 12, wy + 54), 5, [Color("e06666"), Color("f2b84b"), Color("d88fc9")][k % 3])
	if p.get("door", false):
		var dx: float = w * p.get("door_at", 0.5) - 26
		_box(Rect2(dx - 6, h - 96, 64, 102), trim, 3.0)
		_box(Rect2(dx, h - 90, 52, 90), Color("5a3a2c"), 2.0)
		draw_circle(Vector2(dx + 42, h - 44), 3.0, Color("e8c060"))
	if p.has("label"):
		var f: Font = p.get("font", ThemeDB.fallback_font)
		var lw := 170.0
		var lx := w * 0.5 - lw * 0.5
		_box(Rect2(lx, h - 150, lw, 36), Color("efe3c8"), 3.0)
		draw_string(f, Vector2(lx, h - 124), p["label"], HORIZONTAL_ALIGNMENT_CENTER, lw, 20, INK)

func _backhouse() -> void:
	# simpler house for the near background row (no outline-heavy detail)
	var w: float = p.get("w", 260.0)
	var h: float = p.get("h", 320.0)
	var col: Color = p.get("col", Color("b99a7a"))
	var r := _rng()
	draw_rect(Rect2(0, 0, w, h), col)
	draw_rect(Rect2(0, 0, w, h), Color(INK, 0.5), false, 3.0)
	var roof: String = p.get("roof", "peak")
	if roof == "peak":
		draw_colored_polygon(PackedVector2Array([Vector2(-14, 2), Vector2(w * 0.5, -h * 0.28), Vector2(w + 14, 2)]), col.darkened(0.35))
		draw_polyline(PackedVector2Array([Vector2(-14, 2), Vector2(w * 0.5, -h * 0.28), Vector2(w + 14, 2)]), Color(INK, 0.5), 3.0, true)
	else:
		draw_rect(Rect2(-6, -10, w + 12, 12), col.darkened(0.35))
	for i in int(w / 70.0):
		for j in int((h - 40) / 80.0):
			var wl := r.randf() < 0.3
			draw_rect(Rect2(20 + i * 70, 24 + j * 80, 28, 40), Color("f0c070") if wl else col.darkened(0.45))

func _chimney() -> void:
	var w: float = p.get("w", 40.0)
	var h: float = p.get("h", 60.0)
	_box(Rect2(0, 0, w, h + 6), Color("8c5a48"), 3.0)
	_box(Rect2(-5, -8, w + 10, 12), Color("5e3d33"), 3.0)
	for i in int(h / 14):
		draw_line(Vector2(0, 8 + i * 14), Vector2(w, 8 + i * 14), Color(INK, 0.35), 1.5)

func _balcony() -> void:
	var w: float = p.get("w", 110.0)
	_box(Rect2(0, 0, w, 10), Color("6b4b3e"), 3.0)
	for i in int(w / 14) + 1:
		draw_line(Vector2(i * 14, 0), Vector2(i * 14, -34), INK, 3.0)
	draw_line(Vector2(0, -34), Vector2(w, -34), INK, 4.0)
	draw_line(Vector2(6, 10), Vector2(16, 34), INK, 3.0)
	draw_line(Vector2(w - 6, 10), Vector2(w - 16, 34), INK, 3.0)

# ---------------------------------------------------------------- small props
func _crate() -> void:
	var s: float = p.get("s", 60.0)
	_box(Rect2(0, 0, s, s), Color("b5834f"), 3.0)
	draw_rect(Rect2(5, 5, s - 10, s - 10), Color("c99560"))
	draw_line(Vector2(5, 5), Vector2(s - 5, s - 5), Color("8a5f35"), 5.0)
	draw_rect(Rect2(5, 5, s - 10, s - 10), INK, false, 2.0)
	if p.get("cracked", false):
		draw_polyline(PackedVector2Array([Vector2(s * 0.6, 4), Vector2(s * 0.5, s * 0.3), Vector2(s * 0.68, s * 0.5), Vector2(s * 0.55, s * 0.8)]), INK, 2.0, true)

func _barrel() -> void:
	var w: float = p.get("w", 46.0)
	var h: float = p.get("h", 62.0)
	var pts: PackedVector2Array = []
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(w * 0.5 + cos(a) * w * 0.5, h * 0.5 + sin(a) * h * 0.5).lerp(Vector2(w * 0.5 + cos(a) * w * 0.44, h * 0.5 + signf(sin(a)) * h * 0.5), 0.55))
	_poly(pts, Color("9a6b42"), 3.0)
	draw_line(Vector2(3, h * 0.25), Vector2(w - 3, h * 0.25), Color("4b4b52"), 4.0)
	draw_line(Vector2(3, h * 0.75), Vector2(w - 3, h * 0.75), Color("4b4b52"), 4.0)

func _stall() -> void:
	var w: float = p.get("w", 220.0)
	var awn: float = p.get("awn", 170.0)   # awning height above ground
	var c1: Color = p.get("c1", Color("d8433a"))
	var c2: Color = p.get("c2", Color("f3ead8"))
	# posts
	draw_rect(Rect2(6, -awn, 8, awn), Color("5e4030"))
	draw_rect(Rect2(w - 14, -awn, 8, awn), Color("5e4030"))
	draw_rect(Rect2(6, -awn, 8, awn), INK, false, 2.0)
	draw_rect(Rect2(w - 14, -awn, 8, awn), INK, false, 2.0)
	# counter
	_box(Rect2(-4, -70, w + 8, 70), Color("8a6240"), 3.0)
	draw_rect(Rect2(-4, -70, w + 8, 10), Color("6b4b30"))
	# goods on counter
	var r := _rng()
	var goods: String = p.get("goods", "fruit")
	for i in int(w / 26):
		var gx := 14 + i * 26
		match goods:
			"fruit": draw_circle(Vector2(gx, -78), 9, [Color("e0533d"), Color("f2b84b"), Color("8bbf56")][r.randi() % 3])
			"bread": _poly(PackedVector2Array([Vector2(gx - 11, -72), Vector2(gx - 6, -86), Vector2(gx + 8, -86), Vector2(gx + 12, -72)]), Color("d39a55"), 2.0)
			"flowers":
				draw_line(Vector2(gx, -70), Vector2(gx, -92), Color("4f7a3a"), 3.0)
				draw_circle(Vector2(gx, -94), 7, [Color("e66b8a"), Color("f0d264"), Color("9b7fd1")][r.randi() % 3])
	# awning stripes
	var stripes := int(w / 28.0)
	for i in stripes:
		var x0 := -14 + i * (w + 28) / stripes
		var x1 := -14 + (i + 1) * (w + 28) / stripes
		var c := c1 if i % 2 == 0 else c2
		draw_colored_polygon(PackedVector2Array([Vector2(x0 + 10, -awn - 30), Vector2(x1 + 10, -awn - 30), Vector2(x1, -awn), Vector2(x0, -awn)]), c)
		# scalloped edge
		draw_circle(Vector2((x0 + x1) * 0.5, -awn), (x1 - x0) * 0.5, c)
	draw_polyline(PackedVector2Array([Vector2(-4, -awn - 30), Vector2(w + 24, -awn - 30), Vector2(w + 14, -awn), Vector2(-14, -awn), Vector2(-4, -awn - 30)]), INK, 3.0, true)

func _line() -> void:
	# laundry line between two points, with clothes swaying
	var w: float = p.get("w", 200.0)
	var sag: float = p.get("sag", 14.0)
	var pts: PackedVector2Array = []
	for i in 21:
		var k := i / 20.0
		pts.append(Vector2(k * w, sin(k * PI) * sag))
	draw_polyline(pts, INK, 3.0, true)
	var r := _rng()
	var cols := [Color("e8e0d0"), Color("7fa7c9"), Color("e0a1b0"), Color("f2d27a"), Color("a7c98a")]
	var n := int(w / 46.0)
	for i in n:
		var k := (i + 0.5) / n
		var base := Vector2(k * w, sin(k * PI) * sag)
		var sway := sin(t * 2.2 + i * 1.3) * 0.12
		var cw := r.randf_range(22, 34)
		var ch := r.randf_range(28, 44)
		var c: Color = cols[r.randi() % cols.size()]
		var shirt: PackedVector2Array = [base + Vector2(-cw * 0.5, 0), base + Vector2(cw * 0.5, 0),
			base + Vector2(cw * 0.45, ch).rotated(sway), base + Vector2(-cw * 0.45, ch).rotated(sway)]
		_poly(shirt, c, 2.0)
		draw_rect(Rect2(base + Vector2(-cw * 0.3, -4), Vector2(4, 8)), Color("a07050"))

func _lamp() -> void:
	# street lamp post; origin at ground
	var h: float = p.get("h", 210.0)
	draw_rect(Rect2(-6, -h, 12, h), Color("3b3a44"))
	draw_rect(Rect2(-6, -h, 12, h), INK, false, 2.0)
	_box(Rect2(-14, -12, 28, 12), Color("3b3a44"), 2.0)
	draw_line(Vector2(0, -h), Vector2(26, -h - 10), INK, 5.0)
	var lc := Vector2(30, -h + 8)
	var on := lit_amount
	var glass := Color("4a5163").lerp(Color("ffd27a"), on)
	if on > 0.01:
		for i in 4:
			draw_circle(lc, 34 + i * 26 + sin(t * 3.0) * 2.0, Color(1.0, 0.78, 0.4, 0.09 * on))
	_poly(PackedVector2Array([lc + Vector2(-12, -14), lc + Vector2(12, -14), lc + Vector2(9, 14), lc + Vector2(-9, 14)]), glass, 2.5)
	_box(Rect2(lc.x - 15, lc.y - 20, 30, 7), Color("3b3a44"), 2.0)

func _hanging_lantern() -> void:
	var on := lit_amount
	var sw := sin(t * 1.6 + rng_seed) * 0.08
	var c := Vector2(0, 40).rotated(sw)
	draw_line(Vector2.ZERO, c, INK, 2.0, true)
	if on > 0.01:
		draw_circle(c + Vector2(0, 14), 46, Color(1.0, 0.75, 0.35, 0.12 * on))
	_poly(PackedVector2Array([c + Vector2(-10, 0), c + Vector2(10, 0), c + Vector2(13, 26), c + Vector2(-13, 26)]), Color("8a5040").lerp(Color("ffb35c"), on), 2.0)

func _fountain() -> void:
	var w: float = p.get("w", 170.0)
	_poly(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - 8, -60), Vector2(8, -60)]), Color("a9a298"), 3.0)
	draw_rect(Rect2(10, -56, w - 20, 8), Color("6fa5c4"))
	_box(Rect2(w * 0.5 - 14, -150, 28, 92), Color("b9b2a8"), 3.0)
	_poly(PackedVector2Array([Vector2(w * 0.5 - 40, -150), Vector2(w * 0.5 + 40, -150), Vector2(w * 0.5 + 26, -166), Vector2(w * 0.5 - 26, -166)]), Color("a9a298"), 3.0)
	# statue: a little stone musician holding a lyre
	var sx := w * 0.5
	draw_circle(Vector2(sx, -214), 14, Color("c9c2b8"))
	_poly(PackedVector2Array([Vector2(sx - 14, -200), Vector2(sx + 14, -200), Vector2(sx + 18, -166), Vector2(sx - 18, -166)]), Color("c9c2b8"), 3.0)
	draw_arc(Vector2(sx, -214), 14, 0, TAU, 20, INK, 3.0, true)
	draw_arc(Vector2(sx + 14, -184), 12, -1.4, 1.4, 10, INK, 3.0, true)
	if p.get("flowing", false):
		for i in 6:
			var k := fmod(t * 0.9 + i / 6.0, 1.0)
			draw_circle(Vector2(sx + (i - 2.5) * 10 * k, -160 + k * 100 * k), 3.0, Color(0.7, 0.85, 1.0, 1.0 - k))

func _stage() -> void:
	var w: float = p.get("w", 500.0)
	var h: float = p.get("h", 90.0)
	_box(Rect2(0, -h, w, h), Color("7a5236"), 3.0)
	for i in int(w / 40):
		draw_line(Vector2(i * 40, -h), Vector2(i * 40, 0), Color(INK, 0.4), 2.0)
	_box(Rect2(-10, -h - 12, w + 20, 14), Color("94673f"), 3.0)
	# curtain frame
	_box(Rect2(-6, -h - 330, 22, 330 - 12), Color("5e3d33"), 3.0)
	_box(Rect2(w - 16, -h - 330, 22, 330 - 12), Color("5e3d33"), 3.0)
	_box(Rect2(-20, -h - 350, w + 40, 30), Color("5e3d33"), 3.0)
	var cur := Color("9e2f3a")
	for side in [0, 1]:
		var x0: float = 16 if side == 0 else w - 16
		var dirx: float = 1.0 if side == 0 else -1.0
		var pts: PackedVector2Array = [Vector2(x0, -h - 320), Vector2(x0 + dirx * 90, -h - 320), Vector2(x0 + dirx * 40, -h - 120), Vector2(x0 + dirx * 60, -h - 12), Vector2(x0, -h - 12)]
		_poly(pts, cur, 3.0)
		draw_line(Vector2(x0 + dirx * 45, -h - 300), Vector2(x0 + dirx * 25, -h - 40), cur.darkened(0.3), 3.0)
	# banner
	var f: Font = p.get("font", ThemeDB.fallback_font)
	_box(Rect2(w * 0.5 - 150, -h - 318, 300, 40), Color("efe3c8"), 3.0)
	draw_string(f, Vector2(w * 0.5 - 150, -h - 290), "WILLOWMERE FESTIVAL", HORIZONTAL_ALIGNMENT_CENTER, 300, 20, INK)
	# loose board hint
	if p.get("loose", -1.0) >= 0.0:
		var lx: float = p["loose"]
		draw_rect(Rect2(lx, -h + 14, 56, h - 24), Color("6a452c"))
		draw_rect(Rect2(lx, -h + 14, 56, h - 24), INK, false, 2.0)
		draw_line(Vector2(lx + 8, -h + 20), Vector2(lx + 48, -16), Color(INK, 0.6), 2.0)

func _music_stand() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -80), INK, 4.0)
	draw_line(Vector2(-16, 0), Vector2(0, -12), INK, 3.0)
	draw_line(Vector2(16, 0), Vector2(0, -12), INK, 3.0)
	_poly(PackedVector2Array([Vector2(-26, -112), Vector2(26, -112), Vector2(22, -80), Vector2(-22, -80)]), Color("3b3a44"), 3.0)
	# fallen chair beside it
	var cx := 48.0
	_poly(PackedVector2Array([Vector2(cx, -6), Vector2(cx + 46, -14), Vector2(cx + 48, -4), Vector2(cx + 2, 4)]), Color("8a6240"), 2.5)
	draw_line(Vector2(cx + 8, -8), Vector2(cx + 2, -40), INK, 3.0)
	# scattered sheet music
	for i in 3:
		var sx := -70.0 + i * 34
		_poly(PackedVector2Array([Vector2(sx, -2), Vector2(sx + 22, -6), Vector2(sx + 24, 0), Vector2(sx + 2, 3)]).duplicate(), Color("efe8da"), 1.5)

func _bunting() -> void:
	var w: float = p.get("w", 600.0)
	var sag: float = p.get("sag", 60.0)
	var pts: PackedVector2Array = []
	for i in 31:
		var k := i / 30.0
		pts.append(Vector2(k * w, sin(k * PI) * sag))
	draw_polyline(pts, INK, 2.5, true)
	var cols := [Color("d8433a"), Color("f2b84b"), Color("4f8fbf"), Color("6fae6a"), Color("d88fc9")]
	var n := int(w / 36.0)
	var torn: int = p.get("torn", 3)
	for i in n:
		if i % 7 == torn:
			continue
		var k := (i + 0.5) / n
		var b := Vector2(k * w, sin(k * PI) * sag)
		var sw := sin(t * 2.0 + i) * 0.1
		var tri: PackedVector2Array = [b + Vector2(-12, 0), b + Vector2(12, 0), b + Vector2(0, 26).rotated(sw)]
		_poly(tri, cols[i % cols.size()], 2.0)

func _water() -> void:
	var w: float = p.get("w", 270.0)
	draw_rect(Rect2(0, 18, w, 800), Color("2f5466"))
	for i in 6:
		var y := 30.0 + i * 22
		var pts: PackedVector2Array = []
		for k in 13:
			pts.append(Vector2(k * w / 12.0, y + sin(t * 2.0 + k * 0.9 + i) * 3.0))
		draw_polyline(pts, Color(0.6, 0.8, 0.9, 0.35 - i * 0.04), 2.0, true)
	# stone canal walls
	_box(Rect2(-18, 0, 18, 300), Color("8a8178"), 3.0)
	_box(Rect2(w, 0, 18, 300), Color("8a8178"), 3.0)

func _sign() -> void:
	var w: float = p.get("w", 150.0)
	var txt: String = p.get("text", "")
	var f: Font = p.get("font", ThemeDB.fallback_font)
	draw_line(Vector2(w * 0.2, 0), Vector2(w * 0.2, -20), INK, 3.0)
	draw_line(Vector2(w * 0.8, 0), Vector2(w * 0.8, -20), INK, 3.0)
	_box(Rect2(0, 0, w, 34), Color("efe3c8"), 3.0)
	draw_string(f, Vector2(0, 24), txt, HORIZONTAL_ALIGNMENT_CENTER, w, 18, INK)

func _flowerbox() -> void:
	var w: float = p.get("w", 80.0)
	_box(Rect2(0, -22, w, 22), Color("7a5a3a"), 2.5)
	var r := _rng()
	for i in int(w / 12):
		draw_line(Vector2(6 + i * 12, -22), Vector2(6 + i * 12, -36), Color("4f7a3a"), 2.0)
		draw_circle(Vector2(6 + i * 12, -38), 5, [Color("e06666"), Color("f2b84b"), Color("d88fc9")][r.randi() % 3])

func _bench() -> void:
	_box(Rect2(0, -36, 110, 10), Color("8a6240"), 2.5)
	_box(Rect2(0, -66, 110, 10), Color("8a6240"), 2.5)
	draw_line(Vector2(10, -26), Vector2(10, 0), INK, 4.0)
	draw_line(Vector2(100, -26), Vector2(100, 0), INK, 4.0)
	draw_line(Vector2(10, -56), Vector2(10, -36), INK, 4.0)
	draw_line(Vector2(100, -56), Vector2(100, -36), INK, 4.0)

func _poster() -> void:
	var f: Font = p.get("font", ThemeDB.fallback_font)
	_box(Rect2(0, 0, 70, 96), Color("efe3c8"), 2.5)
	draw_string(f, Vector2(0, 22), "TONIGHT", HORIZONTAL_ALIGNMENT_CENTER, 70, 13, INK)
	draw_circle(Vector2(35, 48), 14, Color("e2b23c"))
	draw_string(f, Vector2(0, 84), "LARK", HORIZONTAL_ALIGNMENT_CENTER, 70, 15, Color("9e2f3a"))

func _steps() -> void:
	var w: float = p.get("w", 80.0)
	var n: int = p.get("n", 2)
	for i in n:
		var sh := (i + 1) * 45.0 / n
		_box(Rect2(i * w / n, -sh, w - i * w / n, sh), Color("94673f"), 2.5)

func _door() -> void:
	var open: float = p.get("open", 0.0)
	_box(Rect2(0, -200, 120, 200), Color("3a2a24"), 3.0)
	draw_rect(Rect2(8, -192, 104 * (1.0 - open), 192), Color("6b4b30"))
	draw_rect(Rect2(8, -192, 104 * (1.0 - open), 192), INK, false, 2.0)

func _tower_base() -> void:
	var w: float = p.get("w", 420.0)
	var h: float = p.get("h", 900.0)
	_box(Rect2(0, -h, w, h), Color("8f8a86"), 4.0)
	var r := _rng()
	for j in int(h / 34):
		var off := 0.0 if j % 2 == 0 else 30.0
		for i in int(w / 60) + 1:
			draw_rect(Rect2(off + i * 60, -h + j * 34, 56, 30), Color("8f8a86").darkened(r.randf() * 0.12))
	draw_rect(Rect2(0, -h, w, h), INK, false, 4.0)

func _beam() -> void:
	var w: float = p.get("w", 700.0)
	_box(Rect2(0, 0, w, 34), Color("5e4030"), 3.0)
	for i in int(w / 60):
		draw_line(Vector2(i * 60 + 30, 4), Vector2(i * 60 + 30, 30), Color(INK, 0.4), 2.0)

func _chalk() -> void:
	var c := Color(0.96, 0.96, 0.92, 0.9)
	draw_line(Vector2(0, 0), Vector2(70, 0), c, 4.0, true)
	draw_line(Vector2(70, 0), Vector2(52, -14), c, 4.0, true)
	draw_line(Vector2(70, 0), Vector2(52, 14), c, 4.0, true)
	var f: Font = p.get("font", ThemeDB.fallback_font)
	draw_string(f, Vector2(-20, -26), "~ L", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, c)


# ---------------------------------------------------------------- concert hall (chapter 3)
func _candles() -> void:
	var on := lit_amount
	draw_line(Vector2(0, 0), Vector2(0, -70), INK, 6.0)
	draw_line(Vector2(0, 0), Vector2(0, -70), Color("b8863a"), 3.0)
	draw_line(Vector2(-22, -70), Vector2(22, -70), INK, 6.0)
	draw_line(Vector2(-22, -70), Vector2(22, -70), Color("b8863a"), 3.0)
	_box(Rect2(-16, -6, 32, 6), Color("b8863a"), 2.0)
	for i in 3:
		var cx := -20.0 + i * 20.0
		var ch := 22.0 if i == 1 else 16.0
		_box(Rect2(cx - 4, -70 - ch, 8, ch), Color("efe8da"), 2.0)
		if on > 0.01:
			var fl := Vector2(cx, -76 - ch)
			draw_circle(fl, 26, Color(1.0, 0.75, 0.35, 0.12 * on))
			draw_circle(fl, 4.5 + sin(t * 11.0 + i) * 1.0, Color(1.0, 0.85, 0.45, on))

func _seats() -> void:
	# a raised tier of red velvet theatre seats (the tier itself is solid)
	var w: float = p.get("w", 160.0)
	var h: float = p.get("h", 60.0)
	_box(Rect2(0, 0, w, h + 400), Color("4a3b3a"), 3.0)
	var n := int(w / 34)
	for i in n:
		var x := 4.0 + i * 34.0
		_box(Rect2(x, -26, 28, 26), Color("9e2f3a"), 2.0)
		_box(Rect2(x - 2, -10, 32, 10), Color("7a2430"), 2.0)
	draw_line(Vector2(0, 0), Vector2(w, 0), Color("6b4b30"), 5.0)

func _booth() -> void:
	_box(Rect2(0, -230, 170, 230), Color("6b4b3e"), 3.0)
	_box(Rect2(20, -200, 130, 80), Color("2a3448"), 2.0)
	draw_line(Vector2(85, -200), Vector2(85, -120), INK, 3.0)
	_box(Rect2(-10, -110, 190, 16), Color("94673f"), 2.5)
	var f: Font = p.get("font", ThemeDB.fallback_font)
	_box(Rect2(25, -258, 120, 30), Color("efe3c8"), 2.5)
	draw_string(f, Vector2(25, -236), "TICKETS", HORIZONTAL_ALIGNMENT_CENTER, 120, 18, INK)

func _piano() -> void:
	var w: float = p.get("w", 200.0)
	_poly(PackedVector2Array([Vector2(0, -90), Vector2(w, -90), Vector2(w, -60), Vector2(0, -60)]), Color("2b2530"), 3.0)
	_poly(PackedVector2Array([Vector2(10, -90), Vector2(w * 0.85, -90), Vector2(w * 0.55, -170)]), Color("3a3240"), 3.0)
	draw_line(Vector2(w * 0.55, -170), Vector2(w * 0.5, -90), INK, 3.0)
	for i in 14:
		draw_rect(Rect2(8 + i * ((w - 16) / 14.0), -64, (w - 16) / 14.0 - 2, 12), Color("f2ece0"))
	for k in [6.0, w - 12.0]:
		draw_rect(Rect2(k, -60, 6, 60), Color("2b2530"))

func _curtain() -> void:
	var h: float = p.get("h", 700.0)
	var cur := Color("9e2f3a")
	for i in 5:
		var x := i * 34.0
		_poly(PackedVector2Array([Vector2(x, -h), Vector2(x + 38, -h), Vector2(x + 30 + sin(t + i) * 3.0, 0), Vector2(x + 4, 0)]), cur.darkened((i % 2) * 0.15), 2.0)
	_box(Rect2(-10, -h - 30, 190, 34), Color("b8863a"), 3.0)

func _fallen_chandelier() -> void:
	_poly(PackedVector2Array([Vector2(-80, 0), Vector2(80, 0), Vector2(60, -26), Vector2(-60, -26)]), Color("b8863a"), 3.0)
	for i in 6:
		var x := -60.0 + i * 24.0
		draw_line(Vector2(x, -26), Vector2(x + 6, -54 + (i % 2) * 10), INK, 3.0)
		draw_circle(Vector2(x + 6, -56 + (i % 2) * 10), 5, Color(0.85, 0.92, 1.0))
	draw_line(Vector2(0, -26), Vector2(40, -140), INK, 3.0)

func _hall_floor() -> void:
	var w: float = p.get("w", 1000.0)
	draw_rect(Rect2(0, 0, w, 900), Color("3a2f2c"))
	draw_rect(Rect2(0, 0, w, 22), Color("6b4b30"))
	for i in int(w / 60):
		draw_line(Vector2(i * 60, 0), Vector2(i * 60, 22), Color(INK, 0.5), 2.0)
	draw_line(Vector2(0, 0), Vector2(w, 0), INK, 4.0)
	# puddles
	var r := _rng()
	for i in int(w / 300):
		var px := r.randf_range(20, w - 120)
		draw_rect(Rect2(px, 2, r.randf_range(60, 140), 5), Color(0.55, 0.7, 0.85, 0.5))

func _sheet() -> void:
	var rot: float = p.get("rot", 0.2)
	var pts: PackedVector2Array = []
	for v in [Vector2(-14, -10), Vector2(14, -12), Vector2(16, 10), Vector2(-12, 12)]:
		pts.append((v as Vector2).rotated(rot))
	_poly(pts, Color("efe8da"), 1.5)
	for i in 3:
		draw_line(Vector2(-9, -5 + i * 6).rotated(rot), Vector2(9, -6 + i * 6).rotated(rot), Color(INK, 0.5), 1.0)

func _balcony_slab() -> void:
	var w: float = p.get("w", 600.0)
	# support columns down into the flood
	for i in int(w / 260) + 1:
		var x := 40.0 + i * 260.0
		if x > w - 20:
			continue
		draw_rect(Rect2(x - 14, 40, 28, 700), Color("4a3f44"))
		draw_rect(Rect2(x - 14, 40, 28, 700), INK, false, 2.0)
	_box(Rect2(0, 0, w, 40), Color("6b4b3e"), 3.0)
	draw_rect(Rect2(0, 22, w, 18), Color("9e2f3a"))
	for i in int(w / 40):
		draw_circle(Vector2(20 + i * 40, 31), 4, Color("d9a441"))
	# railing
	draw_line(Vector2(0, -34), Vector2(w, -34), INK, 4.0)
	for i in int(w / 22) + 1:
		draw_line(Vector2(i * 22, 0), Vector2(i * 22, -34), Color(INK, 0.8), 2.5)

func _steps_block() -> void:
	var w: float = p.get("w", 100.0)
	_box(Rect2(0, 0, w, 900), Color("5a4a48"), 3.0)
	draw_rect(Rect2(0, 0, w, 12), Color("9e2f3a"))
	draw_line(Vector2(0, 12), Vector2(w, 12), INK, 2.0)

func _field_prop() -> void:
	var w: float = p.get("w",180.0)
	var h: float = p.get("h",100.0)
	match kind:
		"wheat":
			for i in int(w / 14):
				var x := i*14.0
				var tip := Vector2(x+sin(t*1.8+i*0.7)*7,-35-absf(sin(i*13.0))*35)
				draw_line(Vector2(x,0),tip,Color("aa7d38"),2,true)
				for j in 3:
					var q := tip+Vector2(0,j*6)
					draw_line(q,q+Vector2(-7,6),Color("d8b253"),3,true)
					draw_line(q,q+Vector2(7,6),Color("e9cb7c"),3,true)
		"fence":
			for i in int(w/32)+1: _box(Rect2(i*32,-70,10,70),Color("bc996a"),2)
			for y in [-52,-25]: _box(Rect2(-5,y,w+15,8),Color("aa8056"),2)
		"haystack":
			_poly(PackedVector2Array([Vector2(0,0),Vector2(0,-h+18),Vector2(18,-h),Vector2(w-18,-h),Vector2(w,-h+18),Vector2(w,0)]),Color("d4ad53"))
			for i in int(w/14): draw_line(Vector2(i*14+7,-h+15),Vector2(i*14+7,-8),Color("af853b"),2)
			draw_line(Vector2(0,-h*0.45),Vector2(w,-h*0.45),Color("7e6543"),4)
		"barn":
			_box(Rect2(0,-h,w,h),Color("af735c"))
			for i in int(w/24): draw_line(Vector2(i*24,-h),Vector2(i*24,0),Color("855342"),2)
			_poly(PackedVector2Array([Vector2(-22,-h),Vector2(w*0.5,-h-100),Vector2(w+22,-h)]),Color("675451"))
			_box(Rect2(w*0.35,-h*0.65,w*0.3,h*0.65),Color("6e5244"))
			draw_line(Vector2(w*0.35,-h*0.65),Vector2(w*0.65,0),Color("cda77b"),5)
		"roof_planks":
			_box(Rect2(0,0,w,14),Color("b89470"))
			for i in int(w/25): draw_line(Vector2(i*25,0),Vector2(i*25,14),INK,2)
		"pond", "stream":
			draw_rect(Rect2(0,0,w,460),Color("668d92"))
			for i in 20:
				var x := fmod(i*71+t*12,w)
				var y := 8+i*17.0
				draw_line(Vector2(x,y),Vector2(minf(x+40,w),y),Color(0.95,0.84,0.62,0.5),2)
		"signpost":
			_box(Rect2(-5,-150,10,150),Color("896b4b"))
			_box(Rect2(-50,-150,260,44),Color("dec89e"))
			var font: Font = p.get("font")
			if font: draw_string(font,Vector2(-39,-121),p.get("text",""),HORIZONTAL_ALIGNMENT_LEFT,240,17,INK)
		"ribbon_clue":
			draw_polyline(PackedVector2Array([Vector2(-30,-4),Vector2(-12,-15),Vector2(8,-8),Vector2(27,-21),Vector2(43,-12)]),INK,13,true)
			draw_polyline(PackedVector2Array([Vector2(-30,-4),Vector2(-12,-15),Vector2(8,-8),Vector2(27,-21),Vector2(43,-12)]),Color("f0ca52"),8,true)
