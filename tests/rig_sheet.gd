extends Node2D
var rigs := []
var f := 0
func _ready():
	RenderingServer.set_default_clear_color(Color("cfc7bb"))
	var specs = [
		[Cast.wren(), "idle", "neutral", {}], [Cast.wren(), "run", "determined", {}],
		[Cast.wren(), "jump", "determined", {}], [Cast.wren(), "strike", "determined", {}],
		[Cast.wren(), "hurt", "hurt", {}], [Cast.wren(), "cheer", "happy", {}],
		[Cast.baker(), "frozen", "neutral", Cast.pose_checking_watch()], [Cast.baker(), "talk", "sad", {}],
		[Cast.lamplighter(), "frozen", "neutral", Cast.pose_turning_away()], [Cast.lamplighter(), "idle", "worried", {}],
		[Cast.twin(Color("3f7cc4"), Color("e0e0e0")), "frozen", "neutral", Cast.pose_whisper_a()],
		[Cast.twin(Color("4aa36b"), Color("f0d36b")), "idle", "surprised", {}],
		[Cast.lark(), "idle", "sad", {}],
	]
	for i in specs.size():
		var r := Rig.new()
		r.position = Vector2(80 + (i % 7) * 175, 280 + (i / 7) * 330)
		if "--zoom" in OS.get_cmdline_user_args(): r.position = Vector2(110 + (i % 5) * 260, 300 + (i / 5) * 380)
		add_child(r)
		r.setup(specs[i][0])
		if "--zoom" in OS.get_cmdline_user_args(): r.cfg.scale *= 2.0
		r.state = specs[i][1]
		r.expression = specs[i][2]
		r.frozen_pose = specs[i][3]
		if r.state == "frozen": r.freeze = 1.0
		if r.state == "run": r.vel = Vector2(360, 0); r.speed_ratio = 1.0
		if r.state == "jump": r.vel = Vector2(200, -700); r.on_floor = false
		if r.state == "strike": r.strike_t = 0.42
		if i == 6: r.carry = "tray"
		if i == 8: r.carry = "lamp_pole"
		rigs.append(r)
func _process(_d):
	f += 1
	for r in rigs:
		if r.state == "run": r.global_position.x += 0.0
	if f == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/rig_sheet%s.png" % ("_zoom" if "--zoom" in OS.get_cmdline_user_args() else ""))
		get_tree().quit()
