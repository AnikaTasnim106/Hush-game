class_name Background
extends Node2D
## Sky (screen-fixed) + three parallax silhouette layers.

class Silhouette extends Node2D:
	var kind := "far"
	var width := 3000.0
	var t := 0.0
	var seed_ := 1
	var golden := false
	func _ready() -> void:
		set_process(kind == "far" or kind == "hall_far")
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_
		match kind:
			"far":
				# rolling hills
				var hill := Color("b3955f") if golden else Color("5c5370")
				var pts: PackedVector2Array = [Vector2(-800, 400)]
				var x := -800.0
				while x < width + 800:
					pts.append(Vector2(x, -40 - sin(x * 0.0021) * 50 - sin(x * 0.0057 + 1.0) * 26))
					x += 40
				pts.append(Vector2(width + 800, 400))
				draw_colored_polygon(pts, hill)
				# windmills (Windmill Fields, foreshadowing)
				for i in 5:
					var wx := 300.0 + i * 260.0 + r.randf_range(-40, 40)
					var wy := -40 - sin(wx * 0.0021) * 50 - sin(wx * 0.0057 + 1.0) * 26
					var mc := Color("4a4260")
					draw_colored_polygon(PackedVector2Array([Vector2(wx - 14, wy + 4), Vector2(wx + 14, wy + 4), Vector2(wx + 8, wy - 70), Vector2(wx - 8, wy - 70)]), mc)
					var hub := Vector2(wx, wy - 70)
					for b in 4:
						var a := t * 0.25 * (0.6 + i * 0.1) + b * PI * 0.5
						var d := Vector2(cos(a), sin(a))
						var n := Vector2(-d.y, d.x)
						draw_colored_polygon(PackedVector2Array([hub, hub + d * 48 + n * 3, hub + d * 52 + n * 10, hub + d * 14 + n * 9]), mc)
				# the Silent Tower, far away at the end of town
				var tx := 1240.0
				var tc := Color("3c3550")
				draw_rect(Rect2(tx - 40, -420, 80, 400), tc)
				draw_colored_polygon(PackedVector2Array([Vector2(tx - 52, -420), Vector2(tx + 52, -420), Vector2(tx, -520)]), tc)
				draw_rect(Rect2(tx - 14, -380, 28, 36), Color("2a2438"))
				for i in 8:
					draw_circle(Vector2(tx + sin(t * 0.5 + i) * 30.0, -430 + i * 22.0), 22.0 + sin(t + i) * 4.0, Color(0.85, 0.88, 0.98, 0.1))
			"hall_far":
				# back wall of the concert hall: tall arched windows with moonlight
				var wall := Color("2e3446")
				draw_rect(Rect2(-800, -900, width + 1600, 1300), wall)
				var x := -600.0
				while x < width + 600:
					var wx := x
					draw_rect(Rect2(wx, -760, 120, 520), Color("1b2233"))
					draw_circle(Vector2(wx + 60, -760), 60, Color("1b2233"))
					draw_rect(Rect2(wx + 8, -752, 104, 504), Color("8fa6c8"))
					draw_circle(Vector2(wx + 60, -752), 52, Color("8fa6c8"))
					draw_line(Vector2(wx + 60, -804), Vector2(wx + 60, -248), Color("1b2233"), 5.0)
					draw_line(Vector2(wx + 8, -560), Vector2(wx + 112, -560), Color("1b2233"), 5.0)
					draw_line(Vector2(wx + 8, -400), Vector2(wx + 112, -400), Color("1b2233"), 5.0)
					# moonbeam
					draw_colored_polygon(PackedVector2Array([Vector2(wx + 10, -250), Vector2(wx + 110, -250), Vector2(wx + 220, 200), Vector2(wx + 60, 200)]), Color(0.7, 0.8, 1.0, 0.07 + 0.02 * sin(t + wx)))
					x += 420.0
			"hall_mid":
				# columns and the curve of the upper balcony
				var col := Color("3a3f55")
				var x := -700.0
				while x < width + 700:
					draw_rect(Rect2(x, -900, 70, 1100), col)
					draw_rect(Rect2(x - 12, -620, 94, 26), col.lightened(0.08))
					draw_rect(Rect2(x - 12, -140, 94, 26), col.lightened(0.08))
					for k in 6:
						draw_line(Vector2(x + 10 + k * 10, -594), Vector2(x + 10 + k * 10, -140), col.darkened(0.15), 2.0)
					x += 520.0
				draw_rect(Rect2(-800, -700, width + 1600, 40), col.darkened(0.1))
			"mid":
				if golden:
					for i in 30: draw_circle(Vector2(i*220-800,150),210+sin(i)*50,Color("a59558"))
					return
				var col := Color("6e5a72")
				var x := -800.0
				while x < width + 800:
					var w := r.randf_range(90, 180)
					var h := r.randf_range(120, 260)
					draw_rect(Rect2(x, -h, w, h + 400), col)
					if r.randf() < 0.6:
						draw_colored_polygon(PackedVector2Array([Vector2(x - 8, -h), Vector2(x + w * 0.5, -h - r.randf_range(30, 70)), Vector2(x + w + 8, -h)]), col.darkened(0.15))
					if r.randf() < 0.5:
						draw_rect(Rect2(x + w * 0.7, -h - 40, 16, 40), col.darkened(0.1))
					for k in int(w / 40):
						for j in int(h / 60):
							if r.randf() < 0.18:
								draw_rect(Rect2(x + 14 + k * 40, -h + 24 + j * 60, 14, 22), Color("e8b866"))
					x += w + r.randf_range(-10, 20)

var sky_rect: ColorRect
var sky_mat: ShaderMaterial
var layers := []

var theme := "town"

func build(level_width: float, th := "town") -> void:
	theme = th
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)
	sky_rect = ColorRect.new()
	sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_rect.material = sky_mat
	cl.add_child(sky_rect)
	if theme == "fields":
		sky_mat.set_shader_parameter("top_col",Color("738c9b"))
		sky_mat.set_shader_parameter("mid_col",Color("e5b77c"))
		sky_mat.set_shader_parameter("low_col",Color("ffda8b"))
	if theme == "hall" or theme == "tower":
		sky_mat.set_shader_parameter("top_col", Color(0.05, 0.07, 0.13))
		sky_mat.set_shader_parameter("mid_col", Color(0.12, 0.16, 0.26))
		sky_mat.set_shader_parameter("low_col", Color(0.2, 0.26, 0.36))
		sky_mat.set_shader_parameter("sun", Vector2(0.25, 0.2))
		_add_layer("hall_far", 0.3, -120.0, level_width * 0.3 + 1600, 31)
		_add_layer("hall_mid", 0.6, -40.0, level_width * 0.6 + 1600, 37)
	else:
		_add_layer("far", 0.12, -300.0, level_width * 0.12 + 1600, 11)
		_add_layer("mid", 0.4, -210.0, level_width * 0.4 + 1600, 23)

func _add_layer(kind: String, s: float, base_y: float, w: float, sd: int) -> void:
	var px := Parallax2D.new()
	px.scroll_scale = Vector2(s, 1.0)
	add_child(px)
	var sil := Silhouette.new()
	sil.position = Vector2(0, base_y)
	sil.kind = kind
	sil.golden = theme == "fields"
	sil.width = w
	sil.seed_ = sd
	px.add_child(sil)
	layers.append(px)

func _process(_d: float) -> void:
	if sky_mat:
		sky_mat.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
		var cam := get_viewport().get_camera_2d()
		if cam:
			sky_mat.set_shader_parameter("scroll", cam.global_position.x * 0.05)
