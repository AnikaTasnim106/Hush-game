class_name Level1
## Chapter 1: THE LANTERN MARKET. Layout data + story beats. Built by Main.

const WIDTH := 9800.0
const ARENA_X0 := 7600.0
const ARENA_X1 := 8900.0
const BOSS_X := 8250.0
const END_X := 9150.0

const PAGE_IDS := [0, 1, 2]
const THEME := "town"
const DARKNESS := 0.0
const DARK_AFTER := 0.0
const AMBIENCE := [-14.0, -18.0, -80.0]
const CHAPTER_CARD := ["Chapter One", "The Lantern Market"]
const ARENA_CAM_Y := -260.0
const END_CAM_Y := -150.0
const BOSS_NAME := "The Mute Bell"
const BOSS_SUB := "the great bell of Willowmere, smothered by the Hush"
const BOSS_HINT := "Dodge the slam and jump the waves. When the bell is dazed, ring its glowing clapper!"
const AFTER_BOSS_HINT := "Something glints by the tower door..."
const END_INFO := {
	"over": "END OF CHAPTER ONE", "title": "The Lantern Market",
	"line": "Someone laughed. Someone looked away. Someone wasn't listening.",
	"next": "Next: Chapter Two, Windmill Fields",
}

static func story_cards() -> Array:
	return [
		"Three nights ago, at the Willowmere festival,\nLark played her song for the whole town.",
		"Halfway through, she stopped.",
		"The next morning, the Hush came.",
	]

static func on_rescue_line(m: Main, tf: Townsfolk, idx: int) -> void:
	if tf.id == "lamplighter" and idx == 5:
		m._light_lamps()

static func on_rescued(m: Main, tf: Townsfolk) -> void:
	if tf.id == "twins" and m.fountain:
		m.fountain.p["flowing"] = true
		m.fountain.set_lit(true)

const HOUSE_COLS := [Color("d9a066"), Color("c96f5d"), Color("7fa7b0"), Color("e3c9a0"), Color("9b7fb0"), Color("8fae7c"), Color("d98f7a")]
const TRIMS := [Color("6b4b3e"), Color("4b5a6b"), Color("6b3e4b"), Color("4e6b4a")]

static func build(m: Main) -> void:
	var font: Font = m.ui.f_ui_bold
	# ---------------------------------------------------------------- street facades (decor)
	var x := -700.0
	var i := 0
	while x < 3050.0:
		var w: float = [300.0, 360.0, 280.0, 340.0][i % 4]
		var h: float = [330.0, 400.0, 360.0, 300.0][i % 4]
		var p := {"w": w, "h": h, "col": HOUSE_COLS[i % HOUSE_COLS.size()], "trim": TRIMS[i % TRIMS.size()], "door": i % 2 == 0, "door_at": 0.3 + (i % 3) * 0.2, "lit_ratio": 0.4}
		if absf(x - 2350.0) < 200.0:
			p = {"w": 400.0, "h": 360.0, "col": Color("e3c9a0"), "trim": Color("6b4b3e"), "door": true, "door_at": 0.7, "label": "BRAMBLE BAKERY", "font": font, "lit_ratio": 0.6}
			w = 400.0
		if i == 2:
			p["label"] = "WREN'S"
			p["font"] = font
		m.add_decor("house", Vector2(x, -h), p, m.decor_back)
		x += w + 6.0
		i += 1
	# square backdrop
	x = 5380.0
	i = 3
	while x < 7300.0:
		var w: float = [340.0, 300.0, 380.0][i % 3]
		var h: float = [420.0, 380.0, 460.0][i % 3]
		m.add_decor("house", Vector2(x, -h), {"w": w, "h": h, "col": HOUSE_COLS[i % HOUSE_COLS.size()], "trim": TRIMS[i % TRIMS.size()], "door": i % 2 == 1, "lit_ratio": 0.3}, m.decor_back)
		x += w + 6.0
		i += 1
	# tower backdrop
	m.add_decor("backhouse", Vector2(7300, -520), {"w": 300.0, "h": 520.0, "col": Color("9d93a0"), "roof": "flat"}, m.decor_back)
	m.add_decor("tower_base", Vector2(8900, 0), {"w": 520.0, "h": 1100.0}, m.decor_back)
	m.add_decor("beam", Vector2(ARENA_X0 - 40, -594), {"w": ARENA_X1 - ARENA_X0 + 80}, m.decor_back)

	# ---------------------------------------------------------------- ground + canal
	m.add_ground(-700.0, 5150.0)
	m.add_ground(5330.0, WIDTH + 400.0)
	m.add_decor("water", Vector2(5150, 0), {"w": 180.0}, m.decor_front)
	m.add_solid(Rect2(-760, -1400, 60, 1400))           # left world edge
	m.add_solid(Rect2(WIDTH + 300, -1400, 60, 1400))     # right world edge
	m.player.kill_y = 400.0

	# ---------------------------------------------------------------- A. Wren's street
	m.add_checkpoint(Vector2(60, 0), true)
	m.add_decor("lamp", Vector2(420, 0), {"h": 220.0}, m.decor_front, true)
	m.add_decor("barrel", Vector2(880, -62), {}, m.decor_front)
	m.add_crate(Vector2(560, -60), 60.0)
	m.add_crate(Vector2(620, -60), 60.0)
	m.add_crate(Vector2(620, -120), 60.0)
	m.note_row(Vector2(260, -40), 5, 44.0)
	m.note_arc(Vector2(560, -170), 5, 40.0)
	m.add_hint(Rect2(-200, -600, 500, 700), "A / D  to move     ·     Space  to jump (hold for higher)")
	m.add_hint(Rect2(760, -600, 420, 700), "Press J to ring your bell. Sound breaks the Hush.")
	m.spawn_hush("ling", Vector2(1060, -72), 70.0)
	m.add_decor("lamp", Vector2(1260, 0), {"h": 220.0}, m.decor_front, true)

	# ---------------------------------------------------------------- B. Market
	m.add_stall(1450.0, 220.0, "fruit", Color("d8433a"))
	m.add_stall(1850.0, 220.0, "bread", Color("4f8fbf"))
	m.add_oneway(Rect2(1900, -400, 160, 14), "sign", {"text": "MARKET", "font": font})
	m.spawn_page(0, Vector2(1980, -455))
	m.note_row(Vector2(1480, -240), 4, 46.0)
	m.note_row(Vector2(1880, -240), 4, 46.0)
	m.spawn_hush("ling", Vector2(1760, -86), 60.0)
	m.spawn_hush("ling", Vector2(2230, -80), 90.0)
	m.add_decor("flowerbox", Vector2(2280, 0), {"w": 90.0}, m.decor_front)
	m.add_decor("bench", Vector2(2700, 0), {}, m.decor_front)
	m.add_decor("lamp", Vector2(2900, 0), {"h": 220.0}, m.decor_front, true)
	var baker := m.add_townsfolk("baker", "Mr. Bramble", Cast.baker(), Cast.pose_checking_watch(), Vector2(2560, 0), -1.0, "tray")
	baker.clue = "Lark practised her song on the bakery step every morning for a month, but never once played past the middle."
	baker.lines = [
		["Mr. Bramble", "...the bread. I was holding the bread. Wren? What happened to me?", "surprised"],
		["Wren", "The Hush. It's everywhere, Mr. Bramble. Have you seen Lark?", "worried"],
		["Mr. Bramble", "Lark... Every morning for a month she sat on my step and played that song. The same one, over and over.", "neutral"],
		["Mr. Bramble", "Never past the middle, mind you. She'd reach a certain spot, stop, and start again from the top.", "neutral"],
		["Mr. Bramble", "Festival night I was checking my watch while she played. Thinking about closing up. ...I wasn't really listening.", "sad"],
	]
	baker.repeat_line = [["Mr. Bramble", "Go on, find her. And Wren... tell her I'm sorry I wasn't listening.", "sad"]]
	m.add_hint(Rect2(2300, -600, 400, 700), "Ring the shell of silence to free the people trapped inside.", "rescue_baker")

	# ---------------------------------------------------------------- C. Rooftops
	m.add_crate(Vector2(2990, -60), 60.0)
	m.add_oneway(Rect2(3080, -150, 120, 12), "balcony")
	m.add_house(Rect2(3200, -240, 360, 0), 0)
	m.add_checkpoint(Vector2(3290, -240))
	# alley 1 escape: crate -> balcony -> roof
	m.add_crate(Vector2(3600, -60), 60.0)
	m.add_oneway(Rect2(3640, -170, 80, 12), "balcony")
	m.add_house(Rect2(3720, -270, 360, 0), 1)
	m.add_chimney(Rect2(3880, -335, 45, 65))
	m.add_breakable(Vector2(3990, -330), 60.0, "notes:6")
	m.add_oneway(Rect2(4090, -262, 200, 10), "line")
	# alley 2 escape
	m.add_crate(Vector2(4120, -60), 60.0)
	m.add_crate(Vector2(4180, -60), 60.0)
	m.add_crate(Vector2(4180, -120), 60.0)
	m.add_oneway(Rect2(4220, -210, 80, 12), "balcony")
	m.add_house(Rect2(4300, -300, 420, 0), 2)
	m.add_chimney(Rect2(4400, -385, 45, 85))
	m.add_oneway(Rect2(4470, -520, 110, 12), "balcony")
	m.add_decor("flowerbox", Vector2(4480, -532), {"w": 90.0}, m.decor_front)
	m.spawn_page(1, Vector2(4525, -575))
	m.note_arc(Vector2(3600, -360), 4, 40.0)
	m.note_arc(Vector2(4110, -380), 5, 42.0)
	m.spawn_hush("wing", Vector2(3820, -560), 120.0)
	m.spawn_hush("wing", Vector2(4420, -660), 100.0)
	m.add_decor("lamp", Vector2(4690, -300), {"h": 200.0}, m.decor_front, true)
	var tam := m.add_townsfolk("lamplighter", "Old Tam", Cast.lamplighter(), Cast.pose_turning_away(), Vector2(4610, -300), -1.0, "lamp_pole")
	tam.clue = "Lark was terrified of performing. She asked for every lamp on the square to be lit so she wouldn't feel alone."
	tam.lines = [
		["Old Tam", "The lamps... the lamps have gone out. Fifty years and I've never once let them go out.", "surprised"],
		["Wren", "Old Tam! Did you see Lark on festival night?", "worried"],
		["Old Tam", "Saw her before she went on. Hands shaking like leaves. She asked me to light every lamp on the square.", "neutral"],
		["Old Tam", "Said the dark made her feel like she was playing all alone.", "sad"],
		["Old Tam", "When she stopped, I turned away. Didn't want her to see me looking. I thought that was a kindness.", "sad"],
		["Old Tam", "There. Let's give this street some light again.", "happy"],
	]
	tam.repeat_line = [["Old Tam", "Keep to the light, lass. It's harder for the Hush to hold on there.", "neutral"]]
	m.add_house(Rect2(4720, -210, 430, 0), 3)
	m.add_checkpoint(Vector2(4800, -210))
	m.spawn_hush("ling", Vector2(5020, -290), 60.0)
	m.add_hint(Rect2(4950, -700, 220, 700), "Run and jump. Hold Space to clear the canal.")

	# ---------------------------------------------------------------- D. Festival square
	m.add_checkpoint(Vector2(5470, 0))
	m.add_decor("bunting", Vector2(5450, -430), {"w": 860.0, "sag": 70.0, "torn": 2}, m.decor_back)
	m.add_decor("bunting", Vector2(6330, -470), {"w": 540.0, "sag": 50.0, "torn": 4}, m.decor_back)
	m.add_decor("poster", Vector2(5560, -300), {"font": font}, m.decor_back)
	m.add_decor("poster", Vector2(6980, -280), {"font": font}, m.decor_back)
	m.add_solid_prop(Rect2(5800, -60, 170, 60), "fountain", {"w": 170.0})
	m.spawn_heart(Vector2(5885, -250))
	m.add_decor("hanging_lantern", Vector2(5700, -430), {}, m.decor_back, true)
	m.add_decor("hanging_lantern", Vector2(6150, -440), {}, m.decor_back, true)
	m.add_decor("hanging_lantern", Vector2(6500, -470), {}, m.decor_back, true)
	m.add_decor("hanging_lantern", Vector2(6780, -470), {}, m.decor_back, true)
	m.add_stage(6350.0, 500.0, 90.0, 6770.0)
	m.add_oneway(Rect2(6290, -45, 60, 10), "steps")
	m.add_decor("music_stand", Vector2(6600, -90), {}, m.decor_front)
	m.note_row(Vector2(6420, -150), 6, 50.0)
	var twins := m.add_townsfolk("twins", "Pim & Posy", Cast.twin(Color("3f7cc4"), Color("e8e2d6")), Cast.pose_whisper_a(), Vector2(6150, 0), 1.0, "")
	twins.extra = [[Cast.twin(Color("4aa36b"), Color("f0d36b")), Cast.pose_pointing(), Vector2(42, 0), 1.0]]
	twins.clue = "When Lark stopped playing, someone near the back of the crowd laughed."
	twins.lines = [
		["Pim", "Posy? Posy, you're all grey!", "surprised"],
		["Posy", "No, YOU'RE all grey!", "surprised"],
		["Wren", "You're both fine now. Pim, Posy... festival night. What happened to Lark?", "worried"],
		["Pim", "We weren't being mean!", "worried"],
		["Posy", "We were only whispering that her hands were shaking.", "sad"],
		["Pim", "And then she stopped. Right in the middle.", "sad"],
		["Posy", "And then... somebody laughed.", "scared"],
		["Pim", "Not us!", "worried"],
		["Posy", "Not us. It was someone near the back.", "sad"],
		["Wren", "Someone laughed...", "sad"],
	]
	twins.repeat_line = [["Posy", "Look! The tower gate's glowing since you freed us!", "happy"]]
	m.spawn_hush("ling", Vector2(5990, -86), 80.0)
	m.spawn_hush("ling", Vector2(6600, -176), 120.0)
	m.spawn_hush("wing", Vector2(6260, -520), 140.0)

	# ---------------------------------------------------------------- E. Bell tower
	m.add_gate(Vector2(7240, 0))
	m.add_checkpoint(Vector2(7390, 0))
	m.note_row(Vector2(7440, -40), 4, 40.0)
	m.boss_wall_left = m.add_solid(Rect2(ARENA_X0 - 60, -1400, 40, 1400), false)
	m.boss_wall_right = m.add_solid(Rect2(ARENA_X1, -1400, 60, 1400))
	m.add_decor("door", Vector2(9080, 0), {"open": 0.0}, m.decor_back)
	m.add_decor("steps", Vector2(9040, 0), {"w": 60.0, "n": 2}, m.decor_front)
	m.add_decor("chalk", Vector2(9230, -40), {"font": font}, m.decor_front)
	m.add_boss(Vector2(BOSS_X, 0), ARENA_X0, ARENA_X1)

# ---------------------------------------------------------------- story beats
static func intro_lines() -> Array:
	return [
		["Wren", "Three days. Not a single sound in Willowmere.", "sad"],
		["Wren", "Hold on, Lark. I'm coming to find you.", "determined"],
	]

static func gate_lines() -> Array:
	return [["Wren", "The tower gate... it's open. The great bell hasn't rung since festival night.", "worried"]]

static func boss_lines() -> Array:
	return [["Wren", "The great bell... the Hush has it too. Hang on, I'll make you ring again!", "determined"]]

static func victory_lines() -> Array:
	return [
		["Wren", "It's ringing. Willowmere, can you hear it?", "happy"],
	]

static func ending_lines() -> Array:
	return [
		["Wren", "This is Lark's guitar pick... She was here.", "surprised"],
		["Wren", "And a chalk mark. An arrow with an 'L'... pointing toward the windmills.", "worried"],
		["Wren", "She's leaving me a trail. I'm coming, Lark.", "determined"],
	]
