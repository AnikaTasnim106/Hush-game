class_name HushFinale
extends CanvasLayer
var main: Main
var ending := "B"
var canvas: Control
var scene_t := 0.0
var stage := "talk"
var wren: Rig
var lark: Rig
var crowd: Array[Rig] = []
var music: AudioStreamPlayer
var subtitle := ""
func _ready() -> void:
	layer=9
	canvas=Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.draw.connect(_draw_scene)
	wren=_rig(Cast.wren(),Vector2(600,510))
	lark=_rig(Cast.lark(),Vector2(760,510))
	lark.carry="guitar"
	_run()
func _rig(cfg: Dictionary,pos: Vector2) -> Rig:
	var r := Rig.new()
	r.setup(cfg)
	r.position=pos
	canvas.add_child(r)
	return r
func _run() -> void:
	main.player.control_locked=true
	main.player.set_physics_process(false)
	main.ui.hide_boss()
	main.ui.menus.hide()
	main.ui.set_hud_visible(false)
	main.ui.fade.color.a=0
	Sfx.silence_all()
	if ending=="A":
		subtitle="The silence breaks. So does the shape holding Lark."
		var tw:=create_tween()
		tw.tween_property(lark,"modulate:a",0.0,4)
		await get_tree().create_timer(4.5).timeout
	elif ending=="B":
		subtitle="Wren gives Lark the pages she found."
		await get_tree().create_timer(2).timeout
		await main._say([["Lark","I don't think I can play it yet.","sad"],["Wren","Then we can sit here a while.","sad"],["Lark","Will you stay?","worried"],["Wren","Yes.","determined"]],{"Lark":lark})
	else:
		await main._say([["Wren","I left. You needed me, and I left.","sad"],["Lark","I thought...","sad"],["Wren","I know. I'm here now. Every page. Even the ending.","sad"],["Lark","Would you listen?","worried"],["Wren","All the way.","happy"]],{"Lark":lark})
		var path := ""
		for ext in ["ogg", "mp3", "wav"]:
			if ResourceLoader.exists("res://audio/theme_track.%s" % ext):
				path = "res://audio/theme_track.%s" % ext
				break
		if path != "":
			music=AudioStreamPlayer.new()
			music.bus="Music"
			music.stream=load(path)
			if music.stream is AudioStreamWAV: music.stream.loop_mode=AudioStreamWAV.LOOP_DISABLED
			elif music.stream is AudioStreamOggVorbis or music.stream is AudioStreamMP3: music.stream.loop=false
			add_child(music)
			stage="song"
			print("THEME: beginning complete 60-second playback")
			music.play()
			await music.finished
			print("THEME: finished; clap begins after track end")
			wren.set_process(true)
			lark.set_process(true)
			stage="clap"
			wren.state="cheer"
			subtitle="One clap. Then another. Then Willowmere."
			Sfx.play("clap",-2)
			await get_tree().create_timer(1.2).timeout
			Sfx.play("applause",-4)
			for r in crowd: r.set_process(true); r.state="cheer"
			await get_tree().create_timer(4.5).timeout
		else:
			subtitle="Theme music file missing. The song continues in Willowmere."
			await get_tree().create_timer(3).timeout
	stage="credits"
	for r in crowd: r.hide()
	wren.hide()
	lark.hide()
	scene_t=0
	print("ENDING: ",ending," credits reached")
	if GameState.autoplay:
		print("BOT: reached end card. chapter=4 ending=",ending)
		await get_tree().create_timer(0.3).timeout
		get_tree().quit(0)
		return
	await get_tree().create_timer(3).timeout
	while not Input.is_action_just_pressed("advance"):
		await get_tree().process_frame
	GameState.chapter=1
	GameState.reset_run()
	get_tree().reload_current_scene()
func _process(d: float) -> void:
	scene_t+=d
	if stage=="song" and music:
		scene_t=music.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency()
		if scene_t<22:
			subtitle="For Willowmere"
			lark.state="talk"
			wren.state="idle"
		elif scene_t<41:
			subtitle=["The Lantern Market","Windmill Fields","The Sunken Concert Hall","The Silent Tower"][mini(3,int((scene_t-22)/4.75))]
			lark.hide()
			wren.state="run"
			wren.position=Vector2(100+fmod((scene_t-22)*130,1050),520)
		else:
			if crowd.is_empty(): _gather()
			lark.show()
			lark.position=Vector2(790,350)
			wren.position=Vector2(620,540)
			wren.state="idle"
			lark.state="talk" if scene_t<54 else "idle"
			subtitle="" if scene_t<54 else "Wren stays."
			if scene_t>=54:
				lark.set_process(false)
				wren.set_process(false)
				for r in crowd: r.set_process(false)
	canvas.queue_redraw()
func _gather() -> void:
	var configs: Array = [Cast.baker(),Cast.lamplighter(),Cast.twin(Color("3f7cc4"),Color("e8e2d6")),Cast.twin(Color("4aa36b"),Color("f0d36b")),Cast.hollis(),Cast.fen(),Cast.jory(),Cast.pip(),Cast.ilse(),Cast.abernathy()]
	for i in configs.size():
		var r:=_rig(configs[i],Vector2(180+i*97,570+(i%2)*40))
		r.scale=Vector2.ONE*0.8
		crowd.append(r)
func _draw_scene() -> void:
	var c:=canvas
	var size:=c.size
	if size.x<1: size=Vector2(1280,720)
	c.draw_rect(Rect2(Vector2.ZERO,size),Color("252d42"))
	if stage=="credits":
		c.draw_string(main.ui.f_title,Vector2(0,140),"HUSH",HORIZONTAL_ALIGNMENT_CENTER,size.x,90,Color("f3d99f"))
		var name_: String={"A":"The Quiet Town","B":"Not Yet","TRUE":"The Song Goes On"}[ending]
		var line: String={"A":"The town remembers the music. Wren remembers Lark.","B":"Some songs need time. This time, they have each other.","TRUE":"The ending was never a note. It was someone staying."}[ending]
		var rows: Array=[name_,line,"True ending: find all 12 song pages in one run (play Chapters 1 to 4 in order), then lower your bell." if ending!="TRUE" else "For Willowmere. For everyone who stayed.","Made for thatgamejam #02  ·  Anika","Made with AI assistance: Claude and OpenAI Codex","Code, procedural art, procedural sound effects and writing help","Fonts: Fraunces and Nunito — SIL Open Font License","Theme music by Jason Grace (thatgamejam #02) — unmodified","Press Space / Enter to return to the title"]
		for i in rows.size(): c.draw_string(main.ui.f_ui,Vector2(0,220+i*46),rows[i],HORIZONTAL_ALIGNMENT_CENTER,size.x,23 if i<3 else 19,Color("eee4d0"))
		return
	c.draw_circle(Vector2(1050,120),55,Color("e4d5b0"))
	c.draw_rect(Rect2(0,510,1280,210),Color("777b72"))
	if stage=="song" and scene_t>=22 and scene_t<41:
		var cols: Array=[Color("bd8471"),Color("d4b35f"),Color("778ca3"),Color("89859b")]
		var col: Color=cols[mini(3,int((scene_t-22)/4.75))]
		for i in 9:
			var x:=i*180-fmod(scene_t*110,180)
			c.draw_rect(Rect2(x,210+sin(i)*40,140,300),col)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x-10,210+sin(i)*40),Vector2(x+70,140+sin(i)*40),Vector2(x+150,210+sin(i)*40)]),col.darkened(0.25))
	else:
		c.draw_rect(Rect2(550,350,550,160),Color("9d7356"))
		for i in 7: c.draw_line(Vector2(550+i*80,350),Vector2(550+i*80,510),Color("3d2e32"),3)
	c.draw_string(main.ui.f_hand,Vector2(0,680),subtitle,HORIZONTAL_ALIGNMENT_CENTER,size.x,28,Color("f1dda9"))
