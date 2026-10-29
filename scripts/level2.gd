class_name Level2
## Chapter Two: Windmill Fields. Coordinates use feet at y=0.
const WIDTH := 12300.0
const ARENA_X0 := 9900.0
const ARENA_X1 := 11200.0
const BOSS_X := 10550.0
const END_X := 11650.0
const PAGE_IDS := [3,4,5]
const THEME := "fields"
const DARKNESS := 0.0
const DARK_AFTER := 0.0
const AMBIENCE := [-14.0,-19.0,-80.0]
const CHAPTER_CARD := ["Chapter Two", "Windmill Fields"]
const ARENA_CAM_Y := -260.0
const END_CAM_Y := -150.0
const BOSS_NAME := "The Scarecrow Choir"
const BOSS_SUB := "three voices singing silence"
const BOSS_HINT := "Dodge the pale rings. Ring the glowing music-box when a singer slumps!"
const AFTER_BOSS_HINT := "Something yellow by the mill pond..."
const END_INFO := {"over":"END OF CHAPTER TWO", "title":"Windmill Fields", "line":"Some words come out wrong. Some are never said.", "next":"Next: Chapter Three, The Sunken Concert Hall"}
static func story_cards() -> Array:
	return ["Beyond the market, the windmills have stopped.", "Lark's chalk arrow points through the fields."]
static func on_rescue_line(_m: Main, _tf: Townsfolk, _idx: int) -> void:
	pass
static func on_rescued(_m: Main, _tf: Townsfolk) -> void:
	pass
static func mill(m: Main, x: float, h := 560.0, active := false) -> Windmill:
	var w := Windmill.new()
	w.position = Vector2(x,0)
	w.height = h
	w.active = active
	m.actors.add_child(w)
	return w
static func build(m: Main) -> void:
	m.add_ground(-700,7200)
	m.add_ground(7980,WIDTH+400)
	m.add_solid(Rect2(-760,-1400,60,1400))
	m.add_solid(Rect2(WIDTH+300,-1400,60,1400))
	m.player.kill_y = 360
	m.add_checkpoint(Vector2(60,0),true)
	for x in range(-400,12300,360):
		if x>7000 and x<8100: continue
		m.add_decor("wheat",Vector2(x,0),{"w":300.0},m.decor_back)
	for x in [350,1900,3100,6500,8700,9400]:
		m.add_decor("fence",Vector2(x,0),{"w":180.0},m.decor_back)
	m.add_decor("signpost",Vector2(260,0),{"text":"WINDMILL FIELDS", "font":m.ui.f_ui_bold},m.decor_back)
	m.add_hint(Rect2(-100,-700,650,800),"Glide unlocked: hold Space while falling. Ring a mill hub three times to wake its wind.")
	mill(m,850)
	m.add_hint(Rect2(580,-700,620,800),"Ring the round hub. Then hold Space in the swirling wind to rise.")
	m.add_oneway(Rect2(1020,-340,220,14),"balcony")
	m.spawn_page(3,Vector2(1130,-395))
	m.note_row(Vector2(650,-45),3,44)
	m.note_arc(Vector2(910,-370),5,45)
	m.add_decor("barn",Vector2(1450,0),{"w":360.0,"h":230.0},m.decor_back)
	var h := m.add_townsfolk("hollis","Miller Hollis",Cast.hollis(),Cast.pose_folded(),Vector2(1710,0),-1,"")
	h.clue = "Lark ran past the mill the night of the festival, crying, heading toward the old concert hall by the water."
	h.lines = [["Miller Hollis","The sails... I thought the wind had stopped.","surprised"],["Wren","Hollis. Did Lark come this way?","worried"],["Miller Hollis","Festival night. She ran past the mill, crying. I called her name.","sad"],["Miller Hollis","She kept going. Toward the old concert hall, down by the water.","sad"],["Wren","Then that's where I'll go.","determined"]]
	h.repeat_line = [["Miller Hollis","The mills used to sing all the way to the water. Wake them up, Wren.","neutral"]]
	m.spawn_hush("ling",Vector2(2200,-80),80)
	m.add_solid_prop(Rect2(2440,-75,140,75),"haystack",{"w":140.0,"h":75.0})
	m.add_solid_prop(Rect2(2640,-110,140,110),"haystack",{"w":140.0,"h":110.0})
	m.add_decor("stream",Vector2(2860,0),{"w":180.0},m.decor_back)
	m.add_oneway(Rect2(2830,-25,260,12),"balcony")
	var f := m.add_townsfolk("fen","Fen",Cast.fen(),Cast.pose_mouth(),Vector2(3300,0),-1,"crook")
	f.clue = "Lark told Fen she'd write the ending of her song 'when I'm brave enough'."
	f.lines = [["Fen","I couldn't move my hand. I couldn't even call out.","scared"],["Wren","You can now. I'm here.","worried"],["Fen","Lark played for the sheep sometimes. They never minded if she stopped.","sad"],["Fen","I asked about the ending once. She said, 'When I'm brave enough.'","sad"],["Wren","She never told me that.","hurt"],["Fen","She wanted you to hear it finished.","sad"]]
	f.repeat_line = [["Fen","If you find her... tell her the sheep are still waiting.","happy"]]
	m.add_checkpoint(Vector2(3820,0))
	m.add_hint(Rect2(3550,-700,350,800),"Beyond the barn: keep moving. The singing mill is your shelter.")
	var chase := FieldChase.new()
	chase.main = m
	for x in [4210,4930,5310]:
		m.add_solid(Rect2(x,-65,35,65))
		m.add_decor("fence",Vector2(x,0),{"w":35.0},m.geo)
	m.add_decor("barn",Vector2(4510,0),{"w":280.0,"h":110.0},m.decor_back)
	chase.roof = m.add_oneway(Rect2(4500,-110,300,12),"awning")
	chase.roof_prop = m.add_decor("roof_planks",Vector2(4500,-110),{"w":300.0},m.decor_front)
	m.add_solid_prop(Rect2(4450,-55,60,55),"haystack",{"w":60.0,"h":55.0})
	m.add_solid_prop(Rect2(5540,-65,100,65),"haystack",{"w":100.0,"h":65.0})
	chase.shelter = mill(m,5870,620,true)
	m.add_oneway(Rect2(6060,-240,230,12),"balcony")
	m.add_solid(Rect2(6060,-210,35,210))
	m.hero.add_child(chase)
	m.add_checkpoint(Vector2(6370,0))
	m.spawn_heart(Vector2(6410,-70))
	mill(m,7010,690)
	m.add_decor("pond",Vector2(7200,15),{"w":780.0},m.decor_back)
	m.add_hint(Rect2(6640,-800,550,900),"The mill pond is wide. Rise to the top of the wind, then hold Space and glide right.")
	m.add_oneway(Rect2(7490,-410,150,12),"balcony")
	m.spawn_page(4,Vector2(7565,-465))
	m.note_row(Vector2(7270,-460),7,90)
	m.add_checkpoint(Vector2(8110,0))
	m.add_decor("barn",Vector2(8270,0),{"w":280.0,"h":260.0},m.decor_back)
	mill(m,8250,540)
	m.add_oneway(Rect2(8350,-280,210,14),"balcony")
	m.add_breakable(Vector2(8420,-340),60,"page:5")
	m.add_hint(Rect2(8070,-600,550,650),"A loose crate above the barn. Rise, then press S or K in the air to stomp.")
	m.spawn_hush("wing",Vector2(8750,-320),100)
	var j := m.add_townsfolk("jory","Jory",Cast.jory(),Cast.pose_laugh(),Vector2(9070,0),-1,"")
	j.rig.expression = "laugh"
	j.clue = "Jory laughed. It was nerves, not cruelty, but Lark saw him."
	j.lines = [["Jory","Wren... I need to tell you something.","worried"],["Wren","You were at the festival.","sad"],["Jory","The laugh. That was me.","sad"],["Wren","Oh.","hurt"],["Jory","I wanted to cheer her on. I got nervous and it just... came out wrong.","worried"],["Jory","She looked straight at me. I've felt sick about it ever since.","sad"],["Wren","She thought you meant it.","hurt"],["Jory","I know. If you find her, will you tell her I'm sorry?","sad"],["Wren","I'll tell her.","sad"]]
	j.repeat_line = [["Jory","I should have said something then.","sad"]]
	m.add_gate(Vector2(9510,0))
	m.add_checkpoint(Vector2(9760,0))
	m.boss_wall_left = m.add_solid(Rect2(ARENA_X0-60,-1400,40,1400),false)
	m.boss_wall_right = m.add_solid(Rect2(ARENA_X1,-1400,60,1400))
	var boss := BossChoir.new()
	boss.position = Vector2(BOSS_X,0)
	boss.arena_x0 = ARENA_X0
	boss.arena_x1 = ARENA_X1
	m.actors.add_child(boss)
	m.boss = boss
	boss.defeated.connect(m._on_boss_defeated)
	boss.damaged.connect(func(frac): m.ui.set_boss_hp(frac))
	m.add_decor("pond",Vector2(11400,40),{"w":1000.0},m.decor_back)
	m.add_decor("ribbon_clue",Vector2(END_X,-35),{},m.decor_front)
	m.add_decor("chalk",Vector2(END_X+100,-40),{"font":m.ui.f_ui_bold},m.decor_front)
static func intro_lines() -> Array:
	return [["Wren","The fields. Even the wind sounds far away.","worried"],["Wren","My scarf catches it... maybe it can carry me.","surprised"],["Wren","Hold on, Lark.","determined"]]
static func gate_lines() -> Array:
	return [["Wren","That sound beyond the fence... three voices, and no song.","worried"]]
static func boss_lines() -> Array:
	return [["Wren","Only one is singing. When it stops... I can reach the music-box.","determined"]]
static func victory_lines() -> Array:
	return [["Wren","There. That's what the fields used to sound like.","happy"]]
static func ending_lines() -> Array:
	return [["Wren","Lark's ribbon. She tied it to her guitar so she wouldn't lose her pick.","sad"],["Wren","Another arrow. Across the water.","worried"],["Wren","The concert hall... where she played her first ever show.","sad"],["Wren","I'm still following, Lark.","determined"]]
