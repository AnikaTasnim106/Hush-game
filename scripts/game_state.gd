extends Node
## Global run state + input map. Autoloaded as GameState.

signal notes_changed(n)
signal hearts_changed(n)
signal pages_changed(n)
signal clue_added(text)

const MAX_HEARTS := 3

var notes := 0
var hearts := MAX_HEARTS
var pages: Array[int] = []          # ids of song pages found
var clue_chapters: Array[int] = []
var clues: Array[String] = []       # clue lines for the journal
var rescued: Array[String] = []
var flags := {}
var chapter := 1
var continuing := false   # keep run state across a scene reload (next chapter)
var jump_in := false      # skip title, go to chapter intro
var page_ids: Array = [0, 1, 2]

# command-line modes
var autoplay := false   # bot playthrough
var shot_mode := false  # render stills
var demo_mode := false  # scripted preview
var skip_intro := false

const PAGE_TEXT := {
	0: "Practice #29.\nStill can't get past the middle.\nWhy does my hand stop right there?",
	1: "Wren says it's already perfect.\nWren is a terrible liar.\n(I love her for it.)",
	2: "If I can play it for everyone, just once,\nmaybe they'll hear it the way I do.",
	3: "I keep writing 'for Willowmere' at the top.\nLike the town will read it.\nLike anyone reads the top of a page.",
	4: "Fen says I play best when I forget people are there.\nBut they're the whole reason I play.",
	5: "The ending is the part where you let go.\nI don't know how to let go of anything.",
	6: "Nine people came to my first concert here.\nNine. I counted them twice.\nWren was all nine of them, clapping.",
	7: "Madame Ilse says a song is a door.\nYou write it, then you have to walk through it\nin front of everyone.",
	9: "The clock keeps the moment I stopped.\nI wish it would keep a kinder one.",
	10: "I looked for your red scarf.\nThen there was an empty chair.",
	11: "I can try the ending again.\nWill you be in the front row\nthis time?",
	8: "If I freeze, I'll look for her in the front row.\nShe'll be there. She's always there.",
}

func pages_in_chapter() -> int:
	var n := 0
	for i in page_ids:
		if i in pages:
			n += 1
	return n

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	autoplay = "--autoplay" in args
	shot_mode = "--shot" in args
	demo_mode = "--demo" in args
	skip_intro = autoplay or shot_mode or ("--skip-intro" in args)
	var ci := args.find("--chapter")
	if ci >= 0 and ci + 1 < args.size():
		chapter = int(args[ci + 1])
	_setup_inputs()
	_load_settings()

func reset_run() -> void:
	notes = 0
	hearts = MAX_HEARTS
	pages.clear()
	clues.clear()
	clue_chapters.clear()
	rescued.clear()
	flags.clear()

func add_notes(n: int) -> void:
	notes += n
	notes_changed.emit(notes)

func damage(n := 1) -> void:
	hearts = max(0, hearts - n)
	hearts_changed.emit(hearts)

func heal_full() -> void:
	hearts = MAX_HEARTS
	hearts_changed.emit(hearts)

func add_page(id: int) -> void:
	if id in pages:
		return
	pages.append(id)
	pages_changed.emit(pages.size())

func add_clue(text: String) -> void:
	if text in clues:
		return
	clues.append(text)
	clue_chapters.append(chapter)
	clue_added.emit(text)

# ---------------------------------------------------------------- input
func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func _joy_btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e

func _joy_axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	return e

func _mouse(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	return e

func _add(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for e in events:
		InputMap.action_add_event(action, e)
		# browsers sometimes report only the logical key, so also match by keycode
		if e is InputEventKey and e.physical_keycode != KEY_NONE:
			var e2 := InputEventKey.new()
			e2.keycode = e.physical_keycode
			InputMap.action_add_event(action, e2)

func _setup_inputs() -> void:
	_add("left", [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0), _joy_btn(JOY_BUTTON_DPAD_LEFT)])
	_add("right", [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0), _joy_btn(JOY_BUTTON_DPAD_RIGHT)])
	_add("down", [_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0), _joy_btn(JOY_BUTTON_DPAD_DOWN)])
	_add("up", [_key(KEY_W), _key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0), _joy_btn(JOY_BUTTON_DPAD_UP)])
	_add("jump", [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _joy_btn(JOY_BUTTON_A)])
	_add("strike", [_key(KEY_J), _joy_btn(JOY_BUTTON_X)])
	_add("stomp", [_key(KEY_K), _joy_btn(JOY_BUTTON_B)])
	_add("interact", [_key(KEY_E), _key(KEY_ENTER), _joy_btn(JOY_BUTTON_Y)])
	_add("advance", [_key(KEY_SPACE), _key(KEY_E), _key(KEY_ENTER), _key(KEY_J), _joy_btn(JOY_BUTTON_A)])
	_add("journal", [_key(KEY_TAB), _joy_btn(JOY_BUTTON_BACK)])
	_add("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy_btn(JOY_BUTTON_START)])


# ---------------------------------------------------------------- sound settings
var music_volume := 0.8
var sfx_volume := 0.8
var volume := 0.8
var muted := false
const SETTINGS := "user://settings.cfg"

func apply_sound() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	AudioServer.set_bus_mute(0, muted or volume <= 0.001)
	for pair in [["Music",music_volume],["SFX",sfx_volume]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx>=0: AudioServer.set_bus_volume_db(idx,linear_to_db(maxf(pair[1],0.001)))

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	apply_sound()
	_save_settings()

func toggle_mute() -> void:
	muted = not muted
	apply_sound()
	_save_settings()

func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS) == OK:
		volume = cf.get_value("sound", "volume", 0.8)
		music_volume = cf.get_value("sound","music",0.8)
		sfx_volume = cf.get_value("sound","sfx",0.8)
		muted = cf.get_value("sound", "muted", false)
	apply_sound()

func _save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("sound","music",music_volume)
	cf.set_value("sound","sfx",sfx_volume)
	cf.set_value("sound", "volume", volume)
	cf.set_value("sound", "muted", muted)
	cf.save(SETTINGS)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e.physical_keycode == KEY_M or e.keycode == KEY_M):
		toggle_mute()
