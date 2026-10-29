class_name GameUI
extends CanvasLayer
## HUD, dialogue, cards, page popup, journal, pause menu, fades.

signal dialogue_line(idx, speaker)
signal pause_choice(choice)

var menus: HushMenus
var f_title: Font
var f_ui: Font
var f_ui_bold: Font
var f_hand: Font

var hud: Control
var hint_label: Label
var dlg_panel: PanelContainer
var dlg_name: Label
var dlg_text: RichTextLabel
var dlg_arrow: Label
var bars_top: ColorRect
var bars_bot: ColorRect
var card: Control
var card_title: Label
var card_sub: Label
var fade: ColorRect
var overlay: Control       # page / journal / pause container
var overlay_open := ""
var prompt_label: Label
var boss_bar: Control
var boss_hp := 0.0
var boss_name := ""

var _hint_t := 0.0
var _dlg_busy := false
var _typing := false
var _advance := false

const INK := Color("1d1a22")
const PAPER := Color("f3ead6")

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	f_title = _font("res://fonts/Fraunces.ttf", 650)
	f_ui = _font("res://fonts/Nunito.ttf", 600)
	f_ui_bold = _font("res://fonts/Nunito.ttf", 850)
	f_hand = _font("res://fonts/Fraunces.ttf", 400, true)
	_build()
	GameState.hearts_changed.connect(func(_n): hud.queue_redraw())
	GameState.notes_changed.connect(func(_n): hud.queue_redraw())
	GameState.pages_changed.connect(func(_n): hud.queue_redraw())

func _font(path: String, weight: int, italic := false) -> Font:
	var base: FontFile = load(path)
	var fv := FontVariation.new()
	fv.base_font = base
	var vo := {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	if path.ends_with("Fraunces.ttf"):
		vo[TextServerManager.get_primary_interface().name_to_tag("opsz")] = 72
		vo[TextServerManager.get_primary_interface().name_to_tag("SOFT")] = 100
	fv.variation_opentype = vo
	if italic:
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return fv

func _label(txt: String, font: Font, size: int, col := Color.WHITE, outline := 0) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	return l

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# letterbox
	bars_top = ColorRect.new(); bars_top.color = Color.BLACK
	bars_top.set_anchors_preset(Control.PRESET_TOP_WIDE); bars_top.size.y = 0
	bars_bot = ColorRect.new(); bars_bot.color = Color.BLACK
	bars_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.add_child(bars_top); root.add_child(bars_bot)
	bars_top.custom_minimum_size = Vector2(0, 0)
	bars_bot.custom_minimum_size = Vector2(0, 0)

	# HUD
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	root.add_child(hud)

	# boss bar
	boss_bar = Control.new()
	boss_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.draw.connect(_draw_boss)
	boss_bar.visible = false
	root.add_child(boss_bar)

	# hint
	hint_label = _label("", f_ui_bold, 24, Color(1, 0.97, 0.9), 10)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.position = Vector2(-500, -120)
	hint_label.size = Vector2(1000, 40)
	hint_label.modulate.a = 0.0
	root.add_child(hint_label)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.offset_left = -520; hint_label.offset_right = 520
	hint_label.offset_top = -130; hint_label.offset_bottom = -90

	# interact prompt
	prompt_label = _label("", f_ui_bold, 20, Color(1, 0.95, 0.8), 8)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.visible = false
	root.add_child(prompt_label)

	# dialogue
	dlg_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.11, 0.92)
	sb.border_color = Color(0.95, 0.85, 0.6, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 30; sb.content_margin_right = 30
	sb.content_margin_top = 18; sb.content_margin_bottom = 18
	dlg_panel.add_theme_stylebox_override("panel", sb)
	dlg_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dlg_panel.offset_left = -470; dlg_panel.offset_right = 470
	dlg_panel.offset_top = -200; dlg_panel.offset_bottom = -40
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	dlg_panel.add_child(vb)
	dlg_name = _label("", f_ui_bold, 22, Color(1.0, 0.82, 0.45))
	vb.add_child(dlg_name)
	dlg_text = RichTextLabel.new()
	dlg_text.bbcode_enabled = true
	dlg_text.fit_content = true
	dlg_text.scroll_active = false
	dlg_text.add_theme_font_override("normal_font", f_ui)
	dlg_text.add_theme_font_override("italics_font", f_hand)
	dlg_text.add_theme_font_size_override("normal_font_size", 25)
	dlg_text.add_theme_font_size_override("italics_font_size", 25)
	dlg_text.add_theme_color_override("default_color", Color(0.97, 0.95, 0.9))
	dlg_text.custom_minimum_size = Vector2(860, 70)
	vb.add_child(dlg_text)
	dlg_arrow = _label("▸", f_ui_bold, 22, Color(1.0, 0.82, 0.45))
	dlg_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(dlg_arrow)
	dlg_panel.visible = false
	root.add_child(dlg_panel)

	# center card
	card = Control.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_title = _label("", f_title, 72, Color(1, 0.97, 0.92), 14)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card_title.offset_left = -600; card_title.offset_right = 600
	card_title.offset_top = -90; card_title.offset_bottom = 10
	card_sub = _label("", f_ui_bold, 24, Color(1.0, 0.85, 0.55), 8)
	card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card_sub.offset_left = -600; card_sub.offset_right = 600
	card_sub.offset_top = 14; card_sub.offset_bottom = 54
	card.add_child(card_title); card.add_child(card_sub)
	card.modulate.a = 0.0
	root.add_child(card)

	# overlays
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.draw.connect(_draw_overlay)
	root.add_child(overlay)

	# fade
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	menus=HushMenus.new()
	menus.ui=self
	root.add_child(menus)

func _process(delta: float) -> void:
	if _hint_t > 0.0:
		_hint_t -= delta
		hint_label.modulate.a = move_toward(hint_label.modulate.a, 1.0, delta * 4.0)
	else:
		hint_label.modulate.a = move_toward(hint_label.modulate.a, 0.0, delta * 3.0)
	if dlg_panel.visible:
		dlg_arrow.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0) if not _typing else 0.0
	if boss_bar.visible:
		boss_bar.queue_redraw()

func _unhandled_input(e: InputEvent) -> void:
	if _dlg_busy and e.is_action_pressed("advance"):
		_advance = true
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- HUD
func set_hud_visible(v: bool) -> void:
	hud.visible = v

func _draw_hud() -> void:
	var c := hud
	# hearts
	for i in GameState.MAX_HEARTS:
		var p := Vector2(44 + i * 46, 44)
		_heart(c, p, i < GameState.hearts)
	# notes
	var nx := 40.0
	var ny := 96.0
	c.draw_circle(Vector2(nx + 6, ny), 18, Color(0, 0, 0, 0.35))
	Fx.note_shape(c, Vector2(nx + 6, ny), 1.3, Color(1.0, 0.82, 0.35))
	c.draw_string_outline(f_ui_bold, Vector2(nx + 34, ny + 10), str(GameState.notes), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 8, Color(0, 0, 0, 0.7))
	c.draw_string(f_ui_bold, Vector2(nx + 34, ny + 10), str(GameState.notes), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.95, 0.85))
	# pages & rescued (top right)
	var w := c.size.x - 135.0
	var txt := "Song pages  %d / %d" % [GameState.pages_in_chapter(), GameState.page_ids.size()]
	c.draw_string_outline(f_ui_bold, Vector2(w - 330, 44), txt, HORIZONTAL_ALIGNMENT_RIGHT, 300, 22, 8, Color(0, 0, 0, 0.7))
	c.draw_string(f_ui_bold, Vector2(w - 330, 44), txt, HORIZONTAL_ALIGNMENT_RIGHT, 300, 22, Color(1.0, 0.92, 0.75))
	var txt2 := "Voices freed  %d / 3" % GameState.rescued.size()
	c.draw_string_outline(f_ui_bold, Vector2(w - 330, 76), txt2, HORIZONTAL_ALIGNMENT_RIGHT, 300, 22, 8, Color(0, 0, 0, 0.7))
	c.draw_string(f_ui_bold, Vector2(w - 330, 76), txt2, HORIZONTAL_ALIGNMENT_RIGHT, 300, 22, Color(0.85, 0.92, 1.0))
	var txt3 := "Tab  Journal"
	c.draw_string_outline(f_ui, Vector2(w - 330, 106), txt3, HORIZONTAL_ALIGNMENT_RIGHT, 300, 16, 6, Color(0, 0, 0, 0.6))
	c.draw_string(f_ui, Vector2(w - 330, 106), txt3, HORIZONTAL_ALIGNMENT_RIGHT, 300, 16, Color(1, 1, 1, 0.7))

func _heart(c: CanvasItem, p: Vector2, full: bool) -> void:
	var pts: PackedVector2Array = []
	for i in 30:
		var a := TAU * i / 30.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(p + Vector2(x, y) * 1.05)
	c.draw_colored_polygon(pts, Color(0.92, 0.33, 0.36) if full else Color(0.25, 0.22, 0.27, 0.8))
	var cl := pts.duplicate(); cl.append(pts[0])
	c.draw_polyline(cl, Color(0.1, 0.05, 0.07), 3.0, true)
	if full:
		c.draw_circle(p + Vector2(-6, -6), 3.5, Color(1, 1, 1, 0.6))

func show_boss(name: String) -> void:
	boss_name = name
	boss_bar.visible = true

func set_boss_hp(v: float) -> void:
	boss_hp = v

func hide_boss() -> void:
	boss_bar.visible = false

func _draw_boss() -> void:
	var c := boss_bar
	var w := 520.0
	var x := c.size.x * 0.5 - w * 0.5
	var y := c.size.y - 70.0
	c.draw_string_outline(f_title, Vector2(x, y - 12), boss_name, HORIZONTAL_ALIGNMENT_CENTER, w, 28, 8, Color(0, 0, 0, 0.7))
	c.draw_string(f_title, Vector2(x, y - 12), boss_name, HORIZONTAL_ALIGNMENT_CENTER, w, 28, Color(0.93, 0.95, 1.0))
	c.draw_rect(Rect2(x - 4, y - 4, w + 8, 22), Color(0, 0, 0, 0.6))
	c.draw_rect(Rect2(x, y, w * boss_hp, 14), Color(0.88, 0.92, 1.0))
	for i in range(1, 9):
		c.draw_line(Vector2(x + w * i / 9.0, y), Vector2(x + w * i / 9.0, y + 14), Color(0, 0, 0, 0.5), 2.0)

# ---------------------------------------------------------------- hints & prompts
func hint(txt: String, dur := 4.0) -> void:
	hint_label.text = txt
	_hint_t = dur

func show_prompt(world_screen_pos: Vector2, txt: String) -> void:
	prompt_label.visible = true
	prompt_label.text = txt
	prompt_label.size = Vector2(400, 30)
	prompt_label.position = world_screen_pos - Vector2(200, 0)

func hide_prompt() -> void:
	prompt_label.visible = false

# ---------------------------------------------------------------- letterbox / fade / card
func letterbox(on: bool, dur := 0.5) -> void:
	var h := 70.0 if on else 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(bars_top, "custom_minimum_size:y", h, dur)
	tw.tween_property(bars_top, "size:y", h, dur)
	tw.tween_property(bars_bot, "custom_minimum_size:y", h, dur)
	tw.tween_property(bars_bot, "offset_top", -h, dur)
	hud.modulate.a = 1.0
	var tw2 := create_tween()
	tw2.tween_property(hud, "modulate:a", 0.0 if on else 1.0, dur)

func fade_to(a: float, dur := 0.6) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, dur)
	await tw.finished

func show_card(title: String, sub := "", hold := 2.2) -> void:
	card_title.text = title
	card_sub.text = sub
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.6)
	tw.tween_interval(hold)
	tw.tween_property(card, "modulate:a", 0.0, 0.8)
	await tw.finished

# ---------------------------------------------------------------- dialogue
## lines: [[speaker, text], ...]. Emits dialogue_line before each line so the caller can direct.
func dialogue(lines: Array, auto := false) -> void:
	_dlg_busy = true
	dlg_panel.visible = true
	dlg_panel.modulate.a = 0.0
	create_tween().tween_property(dlg_panel, "modulate:a", 1.0, 0.25)
	for i in lines.size():
		var ln: Array = lines[i]
		var speaker: String = ln[0]
		dialogue_line.emit(i, speaker)
		dlg_name.text = speaker
		dlg_name.visible = speaker != ""
		dlg_text.text = ln[1]
		dlg_text.visible_characters = 0
		_typing = true
		_advance = false
		var total := dlg_text.get_total_character_count()
		var shown := 0.0
		while shown < total:
			await get_tree().process_frame
			shown += get_process_delta_time() * 48.0
			dlg_text.visible_characters = int(shown)
			if int(shown) % 3 == 0:
				Sfx.play("talk_blip", -20.0, randf_range(0.9, 1.2))
			if _advance:
				_advance = false
				break
		dlg_text.visible_characters = -1
		_typing = false
		if auto or GameState.autoplay:
			await get_tree().create_timer(0.35 if GameState.autoplay else 1.6).timeout
		else:
			while not _advance:
				await get_tree().process_frame
			_advance = false
		Sfx.play("ui_tick", -14.0)
	var tw := create_tween()
	tw.tween_property(dlg_panel, "modulate:a", 0.0, 0.2)
	await tw.finished
	dlg_panel.visible = false
	_dlg_busy = false

# ---------------------------------------------------------------- title / story cards / end
var _title_t := 0.0

func show_title() -> void:
	overlay_open = "title"
	overlay.visible = true
	set_process(true)

func hide_title() -> void:
	overlay_open = ""
	overlay.visible = false

func story_cards(cards: Array) -> void:
	for txt in cards:
		card_title.text = ""
		card_sub.text = ""
		var l := _label(txt, f_title, 40, Color(0.95, 0.93, 0.88))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.modulate.a = 0.0
		add_child(l)
		var tw := create_tween()
		tw.tween_property(l, "modulate:a", 1.0, 1.0)
		tw.tween_interval(0.4 if GameState.autoplay else 2.4)
		tw.tween_property(l, "modulate:a", 0.0, 0.9)
		await tw.finished
		l.queue_free()

var end_info := {}

func show_end(info := {}) -> void:
	end_info = info
	overlay_open = "end"
	overlay.visible = true
	overlay.queue_redraw()

# ---------------------------------------------------------------- overlays: page, journal, pause
var journal_chapter := 1
var _page_id := 0
var _pause_items := ["Resume", "Volume", "Mute", "How to Play", "Restart from Lantern", "Quit to Title"]
var _pause_sel := 0
var _pause_howto := false

func open_overlay(kind: String, page_id := 0) -> void:
	overlay_open = kind
	_page_id = page_id
	journal_chapter = GameState.chapter
	_pause_sel = 0
	_pause_howto = false
	overlay.visible = true
	overlay.queue_redraw()
	Sfx.play("ui_open", -8.0)
	get_tree().paused = true

func close_overlay() -> void:
	overlay_open = ""
	overlay.visible = false
	get_tree().paused = false

func _input(e: InputEvent) -> void:
	if overlay_open=="journal" and (e.is_action_pressed("left") or e.is_action_pressed("right")):
		journal_chapter=clampi(journal_chapter+(-1 if e.is_action_pressed("left") else 1),1,4)
		overlay.queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if overlay_open == "" or overlay_open == "title" or overlay_open == "end":
		return
	if overlay_open == "pause" and not _pause_howto:
		if e.is_action_pressed("pause"):
			menus._resume()
			get_viewport().set_input_as_handled()
		return
	if overlay_open == "pause":
		if _pause_howto:
			if e.is_action_pressed("advance") or e.is_action_pressed("pause") or (e is InputEventMouseButton and e.pressed):
				_pause_howto = false
				overlay.queue_redraw()
				get_viewport().set_input_as_handled()
			return
		if (e.is_action_pressed("left") or e.is_action_pressed("right")) and _pause_items[_pause_sel] == "Volume":
			GameState.set_volume(GameState.volume + (0.1 if e.is_action_pressed("right") else -0.1))
			Sfx.play("ui_tick", -6.0)
			overlay.queue_redraw()
		elif e.is_action_pressed("up"):
			_pause_sel = (_pause_sel + _pause_items.size() - 1) % _pause_items.size()
			Sfx.play("ui_tick", -10.0)
			overlay.queue_redraw()
		elif e.is_action_pressed("down"):
			_pause_sel = (_pause_sel + 1) % _pause_items.size()
			Sfx.play("ui_tick", -10.0)
			overlay.queue_redraw()
		elif e.is_action_pressed("pause"):
			close_overlay()
		elif e is InputEventKey and e.pressed and (e.physical_keycode == KEY_ENTER or e.physical_keycode == KEY_SPACE or e.physical_keycode == KEY_E):
			var choice: String = _pause_items[_pause_sel]
			if choice == "Mute":
				GameState.toggle_mute()
				overlay.queue_redraw()
			elif choice == "Volume":
				pass
			elif choice == "How to Play":
				_pause_howto = true
				overlay.queue_redraw()
			else:
				close_overlay()
				pause_choice.emit(choice)
		get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("advance") or e.is_action_pressed("journal") or e.is_action_pressed("pause"):
		close_overlay()
		get_viewport().set_input_as_handled()

func _paper(c: Control, r: Rect2) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0, 0, 0, 0.6))
	c.draw_rect(Rect2(r.position + Vector2(8, 10), r.size), Color(0, 0, 0, 0.35))
	c.draw_rect(r, PAPER)
	c.draw_rect(r, INK, false, 3.0)
	c.draw_rect(r.grow(-10), Color(INK, 0.15), false, 1.5)

func _draw_overlay() -> void:
	var c := overlay
	var cx := c.size.x * 0.5
	match overlay_open:
		"title":
			var tt := Time.get_ticks_msec() / 1000.0
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.04, 0.04, 0.06, 0.25))
			c.draw_string_outline(f_title, Vector2(0, c.size.y * 0.42), "HUSH", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 170, 18, Color(0, 0, 0, 0.55))
			c.draw_string(f_title, Vector2(0, c.size.y * 0.42), "HUSH", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 170, Color(0.97, 0.95, 0.9))
			c.draw_string(f_hand, Vector2(0, c.size.y * 0.42 + 64), "a town fell silent when one girl stopped playing", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 28, Color(1.0, 0.86, 0.6))
			var a := 0.55 + 0.45 * sin(tt * 2.5)
			c.draw_string_outline(f_ui_bold, Vector2(0, c.size.y * 0.78), "Press Space to begin", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 26, 8, Color(0, 0, 0, 0.6 * a))
			c.draw_string(f_ui_bold, Vector2(0, c.size.y * 0.78), "Press Space to begin", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 26, Color(1, 1, 1, a))
			var chs := "Chapters:  "
			for n in [1, 2, 3, 4]:
				if ResourceLoader.exists("res://scripts/level%d.gd" % n):
					chs += "[%d]  " % n
			c.draw_string(f_ui, Vector2(0, c.size.y * 0.78 + 40), chs + "  (press a number to start there)", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 18, Color(1, 1, 1, 0.55))
			c.draw_string(f_ui, Vector2(0, c.size.y - 30), "A / D move  ·  Space jump  ·  J ring the bell  ·  S stomp  ·  Tab journal  ·  Esc pause", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 17, Color(1, 1, 1, 0.65))
			c.queue_redraw()
		"end":
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.03, 0.03, 0.05, 1.0))
			c.draw_string(f_ui_bold, Vector2(0, 170), end_info.get("over", "END OF CHAPTER"), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 22, Color(1.0, 0.82, 0.45))
			c.draw_string(f_title, Vector2(0, 250), end_info.get("title", ""), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 64, Color(0.97, 0.95, 0.9))
			var rows := [
				"Voices freed     %d / 3" % GameState.rescued.size(),
				"Song pages       %d / %d" % [GameState.pages_in_chapter(), GameState.page_ids.size()],
				"Notes collected  %d" % GameState.notes,
			]
			var y := 340.0
			for r in rows:
				c.draw_string(f_ui_bold, Vector2(0, y), r, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 26, Color(0.9, 0.92, 1.0))
				y += 44
			c.draw_string(f_hand, Vector2(0, y + 40), end_info.get("line", ""), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 24, Color(1, 1, 1, 0.75))
			c.draw_string(f_ui, Vector2(0, y + 110), end_info.get("next", ""), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 20, Color(1, 1, 1, 0.6))
			c.draw_string(f_ui, Vector2(0, c.size.y - 40), end_info.get("press", "Press Space to return to the title"), HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 18, Color(1, 1, 1, 0.5))
		"page":
			var r := Rect2(cx - 300, 110, 600, 470)
			_paper(c, r)
			c.draw_string(f_title, Vector2(r.position.x, r.position.y + 70), "A page of Lark's song", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 34, INK)
			# staff lines
			for s in 2:
				for i in 5:
					var y := r.position.y + 110 + s * 60 + i * 8
					c.draw_line(Vector2(r.position.x + 50, y), Vector2(r.end.x - 50, y), Color(INK, 0.45), 1.2)
				for k in 9:
					Fx.note_shape(c, Vector2(r.position.x + 80 + k * 54, r.position.y + 118 + s * 60 + ((k * 7 + s * 3 + _page_id * 5) % 5) * 5), 0.8, INK)
			var txt: String = GameState.PAGE_TEXT.get(_page_id, "")
			var y0 := r.position.y + 280
			for line in txt.split("\n"):
				c.draw_string(f_hand, Vector2(r.position.x + 40, y0), line, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 80, 26, Color("3a2a24"))
				y0 += 38
			c.draw_string(f_ui, Vector2(r.position.x, r.end.y - 22), "%d of %d found in this chapter   ·   press any key" % [GameState.pages_in_chapter(), GameState.page_ids.size()], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color(INK, 0.6))
		"journal":
			var r := Rect2(cx - 460, 70, 920, 580)
			_paper(c, r)
			c.draw_string(f_title, Vector2(r.position.x, r.position.y + 62), "Wren's Journal · Chapter %d" % journal_chapter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 38, INK)
			c.draw_string(f_ui_bold, Vector2(r.position.x + 50, r.position.y + 112), "What I know about the festival night", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("9e2f3a"))
			var y := r.position.y + 150
			if GameState.clues.is_empty():
				c.draw_string(f_hand, Vector2(r.position.x + 50, y), "Nothing yet. Someone must have seen something.", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(INK, 0.6))
				y += 40
			for ci in GameState.clues.size():
				if GameState.clue_chapters[ci]!=journal_chapter: continue
				var cl: String=GameState.clues[ci]
				c.draw_string(f_ui, Vector2(r.position.x + 50, y), "•", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
				var lines := _wrap(cl, 76)
				for ln in lines:
					c.draw_string(f_ui, Vector2(r.position.x + 74, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK)
					y += 30
				y += 8
			y = maxf(y + 10, r.position.y + 380)
			c.draw_string(f_ui_bold, Vector2(r.position.x + 50, y), "Lark's song pages", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("9e2f3a"))
			for k in GameState.page_ids.size():
				var i: int = GameState.page_ids[k]
				var bx := r.position.x + 50 + k * 280
				var br := Rect2(bx, y + 18, 250, 140)
				c.draw_rect(br, Color("efe3c8") if i in GameState.pages else Color(0, 0, 0, 0.06))
				c.draw_rect(br, Color(INK, 0.5), false, 2.0)
				if i in GameState.pages:
					var yy := br.position.y + 32
					for ln in _wrap((GameState.PAGE_TEXT[i] as String).replace("\n"," "),30):
						c.draw_string(f_hand, Vector2(bx + 12, yy), ln, HORIZONTAL_ALIGNMENT_LEFT, 230, 15, Color("3a2a24"))
						yy += 19
				else:
					c.draw_string(f_title, br.position + Vector2(0, 86), "?", HORIZONTAL_ALIGNMENT_CENTER, 250, 40, Color(INK, 0.3))
			c.draw_string(f_ui, Vector2(r.position.x, r.end.y - 20), "Left / Right: chapter   ·   Tab / Esc: close", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color(INK, 0.6))
		"pause":
			c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0, 0, 0, 0.62))
			if _pause_howto:
				var r := Rect2(cx - 380, 110, 760, 500)
				_paper(c, r)
				c.draw_string(f_title, Vector2(r.position.x, r.position.y + 64), "How to Play", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 36, INK)
				var rows := [
					["A / D  or  ← →", "Move"],
					["Space / W", "Jump (hold for higher). Press again in the air and hold to glide"],
					["J", "Ring the bell  (tap 3× for a combo)"],
					["S / K  in the air", "Drum stomp: slam down"],
					["S + Space", "Drop through a ledge"],
					["E", "Talk"],
					["Tab", "Journal: clues and song pages"],
					["Esc", "Pause (volume, mute)"],
					["M", "Mute / unmute"],
				]
				var y := r.position.y + 120
				for row in rows:
					c.draw_string(f_ui_bold, Vector2(r.position.x + 60, y), row[0], HORIZONTAL_ALIGNMENT_LEFT, 300, 22, Color("9e2f3a"))
					c.draw_string(f_ui, Vector2(r.position.x + 360, y), row[1], HORIZONTAL_ALIGNMENT_LEFT, 360, 22, INK)
					y += 42
				c.draw_string(f_ui, Vector2(r.position.x, r.end.y - 22), "Click, Space or Esc to go back.", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, Color(INK, 0.7))
			else:
				return
				c.draw_string_outline(f_title, Vector2(0, 230), "Paused", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 64, 10, Color(0, 0, 0, 0.6))
				c.draw_string(f_title, Vector2(0, 230), "Paused", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 64, Color(1, 0.97, 0.92))
				for i in _pause_items.size():
					var sel := i == _pause_sel
					var y := 300.0 + i * 54
					var label: String = _pause_items[i]
					if label == "Volume":
						label = "Volume   ◂  %d%%  ▸" % int(round(GameState.volume * 100.0))
					elif label == "Mute":
						label = "Sound   %s" % ("OFF (muted)" if GameState.muted else "ON")
					var txt: String = ("▸  " if sel else "") + label
					c.draw_string(f_ui_bold, Vector2(0, y), txt, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 30, Color(1.0, 0.82, 0.45) if sel else Color(1, 1, 1, 0.8))

func _wrap(s: String, n: int) -> Array:
	var out := []
	var cur := ""
	for w in s.split(" "):
		if (cur + " " + w).length() > n and cur != "":
			out.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		out.append(cur)
	return out
