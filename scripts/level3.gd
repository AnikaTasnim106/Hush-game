class_name Level3
## Chapter 3: THE SUNKEN CONCERT HALL. Dark, flooded, full of sleeping Listeners.

const WIDTH := 9300.0
const ARENA_X0 := 7400.0
const ARENA_X1 := 8800.0
const ORGAN_X := 8100.0
const END_X := 9000.0
const PAGE_IDS := [6, 7, 8]
const THEME := "hall"
const DARKNESS := 0.62
const DARK_AFTER := 0.0
const AMBIENCE := [-26.0, -14.0, -80.0]
const CHAPTER_CARD := ["Chapter Three", "The Sunken Concert Hall"]
const ARENA_CAM_Y := -290.0
const END_CAM_Y := -150.0
const BOSS_NAME := "The Hollow Organ"
const BOSS_SUB := "the voice of the old hall, choked with silence"
const BOSS_HINT := "Find the GLOWING bell-stop and ring it 3 times! Dodge the falling silence."
const AFTER_BOSS_HINT := "Something is waiting backstage..."
const END_INFO := {
	"over": "END OF CHAPTER THREE", "title": "The Sunken Concert Hall",
	"line": "She looked for someone in the front row. They walked away.",
	"next": "Next: Chapter Four, The Silent Tower",
}

static func floor_(m: Main, x0: float, x1: float) -> void:
	m.add_solid(Rect2(x0, 0, x1 - x0, 900))
	m.add_decor("hall_floor", Vector2(x0, 0), {"w": x1 - x0}, m.geo)

static func block(m: Main, r: Rect2, kind := "seats") -> void:
	# a tier/step that is solid down to the floor
	m.add_solid(Rect2(r.position.x, r.position.y, r.size.x, -r.position.y + 900))
	m.add_decor(kind, r.position, {"w": r.size.x, "h": -r.position.y}, m.geo)

static func balcony(m: Main, x0: float, x1: float, y: float) -> void:
	m.add_solid(Rect2(x0, y, x1 - x0, 40))
	m.add_decor("balcony_slab", Vector2(x0, y), {"w": x1 - x0}, m.geo)

static func candle(m: Main, pos: Vector2, lit: bool) -> Prop:
	var c := m.add_decor("candles", pos, {}, m.decor_front)
	if lit:
		c.set_lit(true)
		c.lit_amount = 1.0
	m.add_light(c, 300.0, 0.95, Vector2(0, -90))
	m.lamps.append(c)
	return c

static func build(m: Main) -> void:
	var font: Font = m.ui.f_ui_bold
	m.player.kill_y = 420.0
	m.add_solid(Rect2(-760, -1400, 60, 1400))
	m.add_solid(Rect2(WIDTH + 300, -1400, 60, 1400))

	# ---------------------------------------------------------------- floors and water
	floor_(m, -700.0, 1900.0)
	m.add_decor("water", Vector2(1900, 0), {"w": 340.0}, m.decor_front)
	floor_(m, 2240.0, 2700.0)
	m.add_decor("water", Vector2(2700, 0), {"w": 450.0}, m.decor_front)
	floor_(m, 3150.0, 4100.0)
	m.add_decor("water", Vector2(4100, 0), {"w": 2200.0}, m.decor_front)
	floor_(m, 6300.0, WIDTH + 400.0)

	# ---------------------------------------------------------------- A. Foyer
	m.add_checkpoint(Vector2(60, 0), true)
	m.add_decor("booth", Vector2(260, 0), {"font": font}, m.decor_back)
	m.add_decor("poster", Vector2(520, -260), {"font": font}, m.decor_back)
	m.add_decor("fallen_chandelier", Vector2(860, 0), {}, m.decor_front)
	candle(m, Vector2(150, 0), true)
	candle(m, Vector2(700, 0), true)
	candle(m, Vector2(1450, 0), false)
	m.note_row(Vector2(330, -40), 5, 44.0)
	m.add_hint(Rect2(560, -900, 520, 1000), "Listeners are asleep. Your bell wakes everything nearby. Sneak past, or ring and fight.")
	m.spawn_hush("listener", Vector2(1150, -70), 40.0)
	m.spawn_hush("listener", Vector2(1290, -120), 40.0)
	m.note_arc(Vector2(1100, -200), 5, 40.0)

	# ---------------------------------------------------------------- B. Flooded stalls
	m.add_hint(Rect2(1700, -900, 220, 1000), "Ride the drifting raft across the water.")
	m.add_moving("raft", Vector2(1960, -14), 120.0, Vector2(1, 0), 60.0, 1.1)
	m.add_checkpoint(Vector2(2300, 0))
	var pip := m.add_townsfolk("pip", "Pip", Cast.pip(), Cast.pose_ears_covered(), Vector2(2520, 0), -1.0, "")
	pip.clue = "Lark's very first concert was in this hall. Only nine people came, and she remembered every one of them."
	pip.lines = [
		["Pip", "Is it over? Did it stop?", "scared"],
		["Wren", "Pip? It's me, Wren. You're safe now.", "worried"],
		["Pip", "I had my hands over my ears. When it went quiet I couldn't stand it. The quiet was so loud.", "sad"],
		["Pip", "Lark used to practise in here when it rained. She said the old hall still remembered her first show.", "neutral"],
		["Pip", "Nine people came. She told me about every single one of them.", "happy"],
	]
	pip.repeat_line = [["Pip", "Mind the Listeners. They hear everything.", "worried"]]
	candle(m, Vector2(2640, 0), false)
	m.add_moving("raft", Vector2(2760, -14), 150.0, Vector2(0, 1), 8.0, 2.0)
	m.add_moving("raft", Vector2(2950, -14), 155.0, Vector2(0, 1), 8.0, 2.0, 1.6)
	m.add_oneway(Rect2(2890, -160, 70, 12), "balcony")
	m.spawn_page(6, Vector2(2925, -210))
	m.spawn_hush("listener", Vector2(3015, -170), 30.0)
	m.note_row(Vector2(2790, -70), 6, 50.0)

	# ---------------------------------------------------------------- stalls -> balcony stairs
	m.add_checkpoint(Vector2(3200, 0))
	block(m, Rect2(3300, -50, 170, 0))
	block(m, Rect2(3470, -100, 170, 0))
	block(m, Rect2(3700, -160, 140, 0))
	block(m, Rect2(3840, -240, 140, 0))
	block(m, Rect2(3980, -320, 120, 0))
	m.spawn_hush("listener", Vector2(3420, -150), 30.0)
	m.spawn_hush("listener", Vector2(3600, -200), 30.0)
	candle(m, Vector2(3250, 0), false)

	# ---------------------------------------------------------------- C. Balcony + chandeliers
	balcony(m, 4100.0, 4750.0, -320.0)
	m.add_checkpoint(Vector2(4200, -320))
	candle(m, Vector2(4150, -320), true)
	m.spawn_hush("listener", Vector2(4450, -400), 30.0)
	m.spawn_hush("wing", Vector2(4450, -620), 80.0)
	m.add_hint(Rect2(4550, -900, 220, 1000), "Time your jumps between the swinging chandeliers.")
	m.add_moving("chandelier", Vector2(4790, -322), 140.0, Vector2(1, 0), 60.0, 0.8)
	m.add_moving("chandelier", Vector2(5040, -322), 140.0, Vector2(1, 0), 60.0, 0.8, PI)
	m.add_oneway(Rect2(5060, -470, 80, 12), "balcony")
	m.spawn_page(7, Vector2(5100, -520))
	balcony(m, 5250.0, 6300.0, -320.0)
	m.add_checkpoint(Vector2(5360, -320))
	candle(m, Vector2(5420, -320), false)
	m.spawn_hush("listener", Vector2(5620, -400), 30.0)
	m.spawn_hush("listener", Vector2(5730, -380), 30.0)
	m.spawn_hush("wing", Vector2(5820, -620), 120.0)
	m.note_row(Vector2(5450, -380), 6, 46.0)
	var ilse := m.add_townsfolk("ilse", "Madame Ilse", Cast.ilse(), Cast.pose_baton_raised(), Vector2(6020, -320), -1.0, "")
	ilse.clue = "Lark wrote the song for the whole town and called it 'For Willowmere'. It never had an ending."
	ilse.lines = [
		["Madame Ilse", "...and, the downbeat... Oh. Oh my. How long have I been standing like this?", "surprised"],
		["Wren", "Three days, Madame Ilse. Please, I'm looking for Lark.", "worried"],
		["Madame Ilse", "Lark came to me in the spring with half a song. She wanted it to be for the whole town.", "neutral"],
		["Madame Ilse", "'For Willowmere', she called it. For everyone who ever stopped in the square to listen to her.", "happy"],
		["Madame Ilse", "We never found the ending together. She said she'd know it when she heard it.", "sad"],
		["Madame Ilse", "On festival night I had my baton raised, ready to bring the choir in for the last part. The cue never came.", "sad"],
	]
	ilse.repeat_line = [["Madame Ilse", "A song is a door, child. Someone has to hold it open.", "neutral"]]

	# ---------------------------------------------------------------- stairs down to the stage
	block(m, Rect2(6300, -240, 100, 0), "steps_block")
	block(m, Rect2(6400, -160, 100, 0), "steps_block")
	block(m, Rect2(6500, -80, 100, 0), "steps_block")

	# ---------------------------------------------------------------- D. Stage, piano, gate
	m.add_solid(Rect2(6680, -90, 200, 90))
	m.add_decor("piano", Vector2(6680, 0), {"w": 200.0}, m.geo)
	m.add_oneway(Rect2(6700, -245, 90, 12), "balcony")
	m.spawn_page(8, Vector2(6745, -295))
	candle(m, Vector2(6640, 0), false)
	var ab := m.add_townsfolk("abernathy", "Mr. Abernathy", Cast.abernathy(), Cast.pose_peering(), Vector2(6960, 0), -1.0, "")
	ab.clue = "When Lark froze, she searched the front row for someone. That person turned and walked away."
	ab.lines = [
		["Mr. Abernathy", "A-ha. Middle C. Still a touch flat... Where am I?", "surprised"],
		["Wren", "The concert hall, Mr. Abernathy. Did you see what happened to Lark on festival night?", "worried"],
		["Mr. Abernathy", "I tuned her guitar that very afternoon. Perfect pitch. Her hands were not so steady.", "neutral"],
		["Mr. Abernathy", "When she stopped, she didn't look at the crowd. She looked at the front row. Searching for someone.", "worried"],
		["Mr. Abernathy", "And whoever she was looking for... turned around and walked away.", "sad"],
		["Wren", "...", "sad"],
	]
	ab.repeat_line = [["Mr. Abernathy", "Some notes take a long time to come back into tune.", "sad"]]
	m.add_gate(Vector2(7150, 0))
	m.add_checkpoint(Vector2(7270, 0))
	candle(m, Vector2(7320, 0), true)

	# ---------------------------------------------------------------- E. The organ loft
	m.boss_wall_left = m.add_solid(Rect2(ARENA_X0 - 60, -1400, 40, 1400), false)
	m.boss_wall_right = m.add_solid(Rect2(ARENA_X1, -1400, 60, 1400))
	m.add_oneway(Rect2(7800, -110, 100, 12), "balcony")
	m.add_oneway(Rect2(7930, -200, 140, 12), "balcony")
	m.add_oneway(Rect2(8280, -120, 100, 12), "balcony")
	m.add_oneway(Rect2(8400, -230, 80, 12), "balcony")
	m.add_oneway(Rect2(8480, -330, 140, 12), "balcony")
	m.add_organ(Vector2(ORGAN_X, 0), ARENA_X0, ARENA_X1, [Vector2(7600, 0), Vector2(8000, -200), Vector2(8550, -330)])
	candle(m, Vector2(7480, 0), true)
	candle(m, Vector2(8720, 0), true)

	# ---------------------------------------------------------------- backstage
	m.add_decor("curtain", Vector2(8830, 0), {"h": 700.0}, m.decor_back)
	m.add_decor("music_stand", Vector2(9060, 0), {}, m.decor_front)
	m.add_decor("chalk", Vector2(9180, -60), {"font": font}, m.decor_front)
	candle(m, Vector2(8960, 0), true)

# ---------------------------------------------------------------- story beats
static func story_cards() -> Array:
	return [
		"The trail of chalk arrows led across the water.",
		"To the old concert hall, where Lark played her very first show.",
		"It has been flooded and dark for years.",
	]

static func intro_lines() -> Array:
	return [
		["Wren", "Lark's first concert was here. Nine people came. I clapped loud enough for ten.", "happy"],
		["Wren", "It's so dark now... I'll stay close to the light.", "worried"],
	]

static func gate_lines() -> Array:
	return [["Wren", "The stage doors are open. Something huge is breathing in there...", "scared"]]

static func boss_lines() -> Array:
	return [["Wren", "The great organ... it's full of Hush. If I ring its stops, maybe it'll remember how to sing!", "determined"]]

static func victory_lines() -> Array:
	return [["Wren", "Listen... the whole hall is singing again.", "happy"]]

static func ending_lines() -> Array:
	return [
		["Wren", "Her music stand... and the last page of her song. 'For Willowmere.'", "surprised"],
		["Wren", "The ending is just... blank. She left it blank.", "sad"],
		["Wren", "Another chalk arrow. It points across the town... to the Silent Tower.", "worried"],
		["Wren", "Hold on, Lark. I'm nearly there.", "determined"],
	]

static func on_rescue_line(_m: Main, _tf: Townsfolk, _idx: int) -> void:
	pass

static func on_rescued(m: Main, tf: Townsfolk) -> void:
	# light the nearest unlit candles and push the dark back a little
	for c in m.lamps:
		if not c.lit and c.global_position.distance_to(tf.global_position) < 1300.0:
			c.set_lit(true)
	var tw := m.create_tween()
	tw.tween_property(m, "darkness", maxf(0.25, m.darkness - 0.12), 2.0)
