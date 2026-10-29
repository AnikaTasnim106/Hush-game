class_name HushMenus
extends Control
var ui: GameUI
var menu: Button
var mute: Button
var panel: PanelContainer
var chapters: HBoxContainer
var previous := ""
var chapter_request := 0
var first_button: Button
var mute_btn: Button
var _was_open := false
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	menu=_button("",Vector2(1216,18),Vector2(46,42),_toggle_menu)
	menu.draw.connect(func():
		for y in [13,21,29]: menu.draw_line(Vector2(12,y),Vector2(34,y),Color("f7e6bf"),3,true))
	menu.tooltip_text="Menu / settings (Esc)"
	mute=_button("",Vector2(1160,18),Vector2(46,42),func(): GameState.toggle_mute())
	mute.tooltip_text="Mute / unmute (M)"
	mute.draw.connect(_speaker)
	panel=PanelContainer.new()
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size=Vector2(540,460)
	panel.offset_left=-270; panel.offset_right=270; panel.offset_top=-230; panel.offset_bottom=230
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("252b3c")
	style.border_color=Color("cfb788")
	style.set_border_width_all(3)
	style.content_margin_left=32; style.content_margin_right=32; style.content_margin_top=24; style.content_margin_bottom=24
	panel.add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",14)
	panel.add_child(box)
	var label:=Label.new();label.text="HUSH · Settings";label.add_theme_font_override("font",ui.f_title);label.add_theme_font_size_override("font_size",32);box.add_child(label)
	for pair in [["Master",GameState.volume],["Music / ambience",GameState.music_volume],["Sound effects",GameState.sfx_volume]]:
		var row:=HBoxContainer.new();box.add_child(row)
		var lab:=Label.new();lab.text=pair[0];lab.custom_minimum_size.x=190;row.add_child(lab)
		var slider:=HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=0.01;slider.value=pair[1];slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
		var key: String=pair[0]
		slider.value_changed.connect(func(v):
			if key=="Master": GameState.volume=v
			elif key=="Music / ambience": GameState.music_volume=v
			else: GameState.sfx_volume=v
			GameState.apply_sound();GameState._save_settings())
	for pair in [["Resume",func(): _resume()],["Mute / unmute",func(): GameState.toggle_mute()],["How to Play",func(): ui._pause_howto=true; ui.overlay.queue_redraw()],["Restart from Lantern",func(): _resume();ui.pause_choice.emit("Restart from Lantern")],["Quit to Title",func(): _resume();ui.pause_choice.emit("Quit to Title")]]:
		var b:=Button.new();b.text=pair[0];b.pressed.connect(pair[1]);box.add_child(b)
		if pair[0]=="Mute / unmute": mute_btn=b
		if first_button==null: first_button=b
	panel.hide()
	chapters=HBoxContainer.new();chapters.position=Vector2(210,425);chapters.add_theme_constant_override("separation",16);add_child(chapters)
	var names: Array=["Lantern Market","Windmill Fields","Sunken Concert Hall","Silent Tower"]
	for i in 4:
		var b:=Button.new();b.focus_mode=Control.FOCUS_NONE;b.text="%d\n%s"%[i+1,names[i]];b.custom_minimum_size=Vector2(203,74);b.add_theme_font_override("font",ui.f_ui_bold);b.add_theme_font_size_override("font_size",18);chapters.add_child(b)
		var chapter:=i+1
		b.pressed.connect(func(): chapter_request=chapter)
func _button(txt: String,pos: Vector2,sz: Vector2,call: Callable) -> Button:
	var b:=Button.new();b.text=txt;b.position=pos;b.size=sz;b.pressed.connect(call)
	b.focus_mode=Control.FOCUS_NONE   # never steal Space/Enter from gameplay
	b.anchor_left=1.0; b.anchor_right=1.0
	b.offset_left=pos.x-1280.0; b.offset_right=pos.x-1280.0+sz.x; b.offset_top=pos.y; b.offset_bottom=pos.y+sz.y
	add_child(b);return b
func _speaker() -> void:
	mute.draw_colored_polygon(PackedVector2Array([Vector2(10,17),Vector2(18,17),Vector2(26,10),Vector2(26,32),Vector2(18,25),Vector2(10,25)]),Color("f7e6bf"))
	if GameState.muted: mute.draw_line(Vector2(9,9),Vector2(36,34),Color("f49d87"),3,true)
	else: mute.draw_arc(Vector2(22,21),13,-0.8,0.8,16,Color("f7e6bf"),2,true)
func _toggle_menu() -> void:
	if ui.overlay_open=="pause": _resume()
	else:
		previous=ui.overlay_open
		ui.open_overlay("pause")
func _resume() -> void:
	ui.close_overlay()
	if previous=="title": ui.show_title()
	previous=""
func _process(_d: float) -> void:
	panel.visible=ui.overlay_open=="pause" and not ui._pause_howto
	chapters.visible=ui.overlay_open=="title"
	menu.visible=ui.overlay_open in ["","title","pause","journal"]
	mute.visible=menu.visible
	mute.queue_redraw()
	if mute_btn: mute_btn.text = "Sound: OFF (click to unmute)" if GameState.muted else "Sound: ON (click to mute)"
	if panel.visible: panel.move_to_front()
	# when the menu opens, select Resume so arrow keys + Enter work right away
	if panel.visible and not _was_open and first_button:
		first_button.grab_focus()
	if not panel.visible and _was_open:
		var f := get_viewport().gui_get_focus_owner()
		if f: f.release_focus()
	_was_open = panel.visible
