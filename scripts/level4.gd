class_name Level4
const WIDTH := 1500.0
const ARENA_X0 := 0.0
const ARENA_X1 := 1400.0
const END_X := 1200.0
const TOP := -4800.0
const PAGE_IDS := [9,10,11]
const THEME := "tower"
const DARKNESS := 0.4
const DARK_AFTER := 0.0
const AMBIENCE := [-28.0,-16.0,-80.0]
const CHAPTER_CARD := ["Chapter Four","The Silent Tower"]
const ARENA_CAM_Y := TOP-220.0
const END_CAM_Y := TOP-150.0
const BOSS_NAME := "The Hush Heart"
const BOSS_SUB := "a song held too tightly"
const BOSS_HINT := "Ring the glowing heart after each wave. Watch for the moment it stops fighting."
const AFTER_BOSS_HINT := "Listen."
const END_INFO := {"over":"HUSH","title":"The Silent Tower","line":"Some songs need someone to stay.","next":""}
static func route() -> Array[Vector2]:
	var a: Array[Vector2] = [Vector2(170,0)]
	for i in range(1,49):
		var k := i % 16
		var x := 170.0 + (k if k<=8 else 16-k)*130.0
		a.append(Vector2(x,-i*100.0))
	return a
static func build(m: Main) -> void:
	m.cam.min_x = 680
	m.cam.max_x = 700
	m.add_solid(Rect2(-100,-5600,100,6500))
	m.add_solid(Rect2(1400,-5600,100,6500))
	m.add_ground(0,1400)
	var wall := TowerWall.new()
	m.decor_back.add_child(wall)
	var points := route()
	for i in range(1,49):
		var q: Vector2 = points[i]
		m.add_oneway(Rect2(q.x-65,q.y,130,16),"balcony")
		if i%8 == 0:
			m.add_checkpoint(q)
			m.spawn_heart(q+Vector2(0,-65))
		if i in [10,24,38]:
			var e := FestivalEcho.new()
			e.index = [10,24,38].find(i)
			e.position = q
			m.actors.add_child(e)
			m.add_hint(Rect2(q+Vector2(-150,-180),Vector2(300,230)),"An echo of festival night. Step into the gold circle to remember.")
		if i in [6,20,34]:
			m.add_oneway(Rect2(q.x+170,q.y-60,100,14),"balcony")
			m.spawn_page(9+[6,20,34].find(i),q+Vector2(220,-115))
		if i in [15,29,43]: m.spawn_hush("listener",q+Vector2(25,-75),25)
		if i in [12,27,41]: m.spawn_hush("wing",q+Vector2(-100,-210),90)
		if i in [7,23,39]:
			m.add_moving("chandelier",q+Vector2(-160,35),110,Vector2(0,1),30,1.1)
		m.note_row(q+Vector2(-30,-55),3,28)
	m.add_checkpoint(Vector2(170,0),true)
	m.add_hint(Rect2(0,-220,850,300),"Climb the clock stairs. Hold Space to glide. Lanterns mark each new floor.")
	m.add_oneway(Rect2(0,TOP,1400,25),"balcony")
	m.add_gate(Vector2(330,TOP))
	m.add_hint(Rect2(0,TOP-500,700,560),"This gate opens with all 3 echoes of festival night. Go back down and step into the gold circles you missed.","gate4")
	m.add_checkpoint(Vector2(210,TOP))
	m.boss_wall_left = m.add_solid(Rect2(340,TOP-1000,35,1000),false)
	m.boss_wall_right = m.add_solid(Rect2(1360,TOP-1000,35,1000))
	var heart := HushHeart.new()
	heart.position = Vector2(850,TOP)
	m.actors.add_child(heart)
	m.boss = heart
	heart.damaged.connect(func(frac): m.ui.set_boss_hp(frac))
	heart.resolved.connect(m.finish_game)
static func story_cards() -> Array:
	return ["Above Willowmere, the clock keeps one moment.","The moment a song stopped."]
static func intro_lines() -> Array:
	return [["Wren","You're up there. I know you are.","worried"],["Wren","This time, I'm staying.","determined"]]
static func gate_lines() -> Array: return []
static func boss_lines() -> Array:
	return [["Wren","Lark? Can you hear me in there?","worried"]]
static func victory_lines() -> Array: return []
static func ending_lines() -> Array: return []
static func on_rescue_line(_m: Main,_tf: Townsfolk,_idx: int) -> void: pass
static func on_rescued(_m: Main,_tf: Townsfolk) -> void: pass

class TowerWall extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,-5400,1400,5700),Color("303545"))
		for y in range(-5400,200,100):
			for x in range(0,1400,140):
				draw_rect(Rect2(x+(70 if y%200==0 else 0),y,137,97),Color("434757"),false,2)
		for y in range(-5200,0,650):
			draw_rect(Rect2(600,y,150,260),Color("141f35"))
			draw_circle(Vector2(675,y),75,Color("141f35"))
			draw_line(Vector2(675,y-70),Vector2(675,y+260),Color("77839c"),5)
			for gx in [220,1160]:
				draw_arc(Vector2(gx,y+200),100,0,TAU,40,Color("9a835d"),16,true)
				for k in 12:
					var v := Vector2.from_angle(k*TAU/12)
					draw_line(Vector2(gx,y+200)+v*20,Vector2(gx,y+200)+v*110,Color("9a835d"),9,true)
		draw_circle(Vector2(700,-5050),190,Color("c7b793"))
		draw_circle(Vector2(700,-5050),178,Color("242d42"))
		draw_line(Vector2(700,-5050),Vector2(700,-5180),Color("e2c384"),7)
		draw_line(Vector2(700,-5050),Vector2(800,-5050),Color("e2c384"),7)
