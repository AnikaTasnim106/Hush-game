extends Node
## --autoplay: a bot that plays Chapter 1 through the player's real input channel.
## It walks right, auto-jumps walls and gaps, rings shells and Hush in front of it,
## and fights the boss (dodges waves, rings the clapper while the bell is dazed).

var main: Main
var p: Player
var t := 0.0
var strike_cd := 0.0
var jump_hold := 0.0
var deaths := 0
var last_x := 0.0
var stuck_t := 0.0
var log_t := 0.0
var goal_x := 0.0
var dir := 1.0
var detour := 0.0

func _ready() -> void:
	main = get_parent()
	await get_tree().process_frame
	p = main.player
	p.use_bot = true
	goal_x = main.L.END_X + 30.0
	p.died.connect(func(): deaths += 1; print("BOT: fainted at x=%d" % int(p.global_position.x)))
	print("BOT: start")

func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(from, to, 1 | 2)
	q.exclude = [p.get_rid()]
	return get_viewport().get_world_2d().direct_space_state.intersect_ray(q)

func _physics_process(delta: float) -> void:
	if p == null:
		return
	t += delta
	strike_cd -= delta
	log_t += delta
	var b := p.bot
	b["x"] = 0.0
	if p.control_locked or main.cutscene:
		b["jump"] = false
		return
	if t > 900.0:
		print("BOT: TIMEOUT at x=%d" % int(p.global_position.x))
		get_tree().quit(1)
		return
	var pos := p.global_position
	if GameState.chapter == 4 and not main.boss_started:
		_tower(b,pos,delta)
		return
	if log_t > 5.0:
		log_t = 0.0
		print("BOT: t=%d x=%d y=%d hearts=%d rescued=%d boss=%s vx=%d bx=%.1f wall=%s lock=%s st=%s" % [int(t), int(pos.x), int(pos.y), GameState.hearts, GameState.rescued.size(), main.boss.state, int(p.velocity.x), b["x"], p.is_on_wall(), p.control_locked, p.rig.state])

	# ---------------- boss behaviour
	if main.boss_started and not main.boss_done:
		if main.boss is BossChoir: _choir(b,pos)
		elif main.boss is HushHeart: _heart(b,pos)
		else: _boss(b,pos)
		return

	# ---------------- travel
	var target := goal_x
	if GameState.rescued.size() < 3 and main.gate and is_instance_valid(main.gate):
		target = minf(target, main.gate.global_position.x - 60.0)
	dir = signf(target - pos.x)
	if absf(target - pos.x) < 12.0:
		dir = 0.0
	if detour > 0.0:
		detour -= delta
		dir = -1.0
	b["x"] = dir

	# strike anything hittable in front
	for h in get_tree().get_nodes_in_group("hittable"):
		if h is BossBell or h is OrganFinale or h is BossChoir or h is HushHeart:
			continue
		var r: Rect2 = h.hurt_rect()
		if r.size == Vector2.ZERO:
			continue
		var sr := p._strike_rect().grow(18.0)
		var front := Rect2(pos + Vector2(-20 if p.facing > 0 else -120, -70), Vector2(140, 130))
		var real := p._strike_rect()
		if r.intersects(real) or (h is Hush and (r.intersects(sr) or r.intersects(front))):
			if h is Hush or h is Townsfolk or h is LevelObjects.Breakable or h is Windmill or h is FestivalEcho:
				b["x"] = 0.0 if h is Townsfolk or h is LevelObjects.Breakable or h is Windmill or h is FestivalEcho else b["x"]
				if strike_cd <= 0.0:
					p.facing = signf(r.get_center().x - pos.x) if absf(r.get_center().x - pos.x) > 4.0 else p.facing
					b["strike_p"] = true
					strike_cd = 0.2
				break

	# jumping
	var on_floor := p.is_on_floor()
	if jump_hold > 0.0:
		jump_hold -= delta
		b["jump"] = true
	else:
		b["jump"] = false
	if on_floor and dir != 0.0:
		var wall := p.is_on_wall() or not _ray(pos + Vector2(0, 30), pos + Vector2(dir * 40.0, 30)).is_empty()
		var ahead := _ray(pos + Vector2(dir * 46.0, 0), pos + Vector2(dir * 46.0, 900))
		var drop: float = 900.0 if ahead.is_empty() else (ahead.position.y - (pos.y + 48.0))
		if wall:
			b["jump_p"] = true
			b["jump"] = true
			jump_hold = 0.45
		elif drop > 110.0:
			# is there something to land on within jump reach?
			var feet := pos.y + 48.0
			var landing := false
			for dx in [110.0, 150.0, 190.0, 230.0]:
				var hit := _ray(Vector2(pos.x + dir * dx, feet - 165.0), Vector2(pos.x + dir * dx, feet + 260.0))
				if not hit.is_empty():
					landing = true
					break
			var movers_ahead := false
			for mv in get_tree().get_nodes_in_group("mover"):
				var mc: Vector2 = mv.centre()
				if signf(mc.x - pos.x) == dir and absf(mc.x - pos.x) < 520.0 and absf(mc.y - feet) < 260.0:
					movers_ahead = true
			if landing or not movers_ahead:
				b["jump_p"] = true
				b["jump"] = true
				jump_hold = 0.45
			else:
				b["x"] = 0.0   # wait for the platform to swing/drift closer
	# stuck detection: back off and retry
	if absf(pos.x - last_x) < 1.0 and dir != 0.0 and on_floor and b["x"] != 0.0:
		stuck_t += delta
		if stuck_t > 2.5:
			stuck_t = 0.0
			detour = 0.35
	else:
		stuck_t = 0.0
	last_x = pos.x
	if GameState.chapter == 2: _field_travel(b,pos)

var _last_hearts := 3
var _last_state := ""
var _route_i := 0
var _route_phase := -1
func _organ(b: Dictionary, pos: Vector2) -> void:
	var o: OrganFinale = main.boss
	var feet := pos.y + 48.0
	if GameState.hearts != _last_hearts:
		var near := ""
		for hz in get_tree().get_nodes_in_group("hazard"):
			if hz.has_method("hazard_rect") and hz.hazard_rect().size != Vector2.ZERO and absf(hz.global_position.x - pos.x) < 200:
				near += "%s@%d,%d " % ["col" if hz is OrganFinale.Column else "hush", int(hz.global_position.x), int(hz.global_position.y)]
		print("BOT: organ hurt phase=%d route_i=%d px=%d py=%d near=%s" % [o.phase, _route_i, int(pos.x), int(pos.y), near])
		_last_hearts = GameState.hearts
	var on_floor := p.is_on_floor()
	if jump_hold > 0.0:
		jump_hold -= get_physics_process_delta_time()
		b["jump"] = true
	else:
		b["jump"] = false
	var routes := [[Vector2(7600, 0)], [Vector2(7850, -110), Vector2(8000, -200)], [Vector2(8330, -120), Vector2(8440, -230), Vector2(8550, -330)]]
	if o.phase != _route_phase:
		_route_phase = o.phase
		_route_i = 0
	var route: Array = routes[clampi(o.phase, 0, 2)]
	# if we fell below the current waypoint's level, restart the route
	if _route_i > 0 and on_floor and feet > (route[_route_i - 1] as Vector2).y + 40.0:
		_route_i = 0
	var wp: Vector2 = route[mini(_route_i, route.size() - 1)]
	var dx := wp.x - pos.x
	b["x"] = clampf(dx / 30.0, -1.0, 1.0) if absf(dx) > 10.0 else 0.0
	if on_floor and absf(dx) < 135.0 and wp.y < feet - 30.0:
		b["jump_p"] = true
		b["jump"] = true
		jump_hold = 0.45
		b["x"] = signf(dx) * 0.8
	if on_floor and absf(dx) < 40.0 and absf(feet - wp.y) < 20.0 and _route_i < route.size() - 1:
		_route_i += 1
	var at_stop := _route_i == route.size() - 1 and absf(dx) < 70.0 and absf(feet - wp.y) < 20.0
	# dodge columns
	for c in get_tree().get_nodes_in_group("boss_wave"):
		if c is OrganFinale.Column and c.t < 1.2 and absf(c.global_position.x - pos.x) < 80.0 and not at_stop:
			b["x"] = signf(dx) if absf(dx) > 1.0 else 1.0
	if at_stop and o.state == "fight":
		b["x"] = 0.0
		p.facing = signf(wp.x - pos.x + 0.001) if absf(wp.x - pos.x) > 6.0 else p.facing
		for c in get_tree().get_nodes_in_group("boss_wave"):
			if c is OrganFinale.Column and c.t < 1.15 and absf(c.global_position.x - pos.x) < 70.0:
				b["x"] = -1.0 if c.global_position.x >= pos.x else 1.0
		if strike_cd <= 0.0:
			b["strike_p"] = true
			strike_cd = 0.22
	for h in get_tree().get_nodes_in_group("hush"):
		if h.global_position.distance_to(pos) < 110.0 and strike_cd <= 0.0:
			p.facing = signf(h.global_position.x - pos.x)
			b["strike_p"] = true
			strike_cd = 0.2

func _boss(b: Dictionary, pos: Vector2) -> void:
	if main.boss is OrganFinale:
		_organ(b, pos)
		return
	var bell := main.boss
	if GameState.hearts != _last_hearts:
		var near := ""
		for hz in get_tree().get_nodes_in_group("hazard"):
			if hz.has_method("hazard_rect") and hz.hazard_rect().size != Vector2.ZERO and hz.global_position.distance_to(pos) < 200:
				near += "%s@%d " % [hz.get_class() if not (hz is Hush) else "hush", int(hz.global_position.x)]
		print("BOT: hurt in boss. state=%s bellx=%d px=%d near=%s" % [bell.state, int(bell.x), int(pos.x), near])
		_last_hearts = GameState.hearts
	if bell.state != _last_state:
		print("BOT:   boss -> %s phase=%d hits=%d bellx=%d px=%d" % [bell.state, bell.phase, bell.hits, int(bell.x), int(pos.x)])
		_last_state = bell.state
	b["jump"] = false
	var on_floor := p.is_on_floor()
	# dodge waves
	for w in get_tree().get_nodes_in_group("boss_wave"):
		if w.delay > 0.0:
			continue
		var dx: float = w.global_position.x - pos.x
		if signf(dx) == -w.dir and absf(dx) < 150.0 and on_floor:
			b["jump_p"] = true
			b["jump"] = true
			jump_hold = 0.4
	if jump_hold > 0.0:
		jump_hold -= get_physics_process_delta_time()
		b["jump"] = true
	match bell.state:
		"dazed":
			var cx: float = bell.x
			var want := cx - 70.0 if pos.x < cx else cx + 70.0
			b["x"] = clampf((want - pos.x) / 30.0, -1.0, 1.0)
			if absf(pos.x - want) < 40.0:
				p.facing = signf(cx - pos.x)
				if strike_cd <= 0.0:
					b["strike_p"] = true
					strike_cd = 0.18
		"windup", "slam":
			var away := signf(pos.x - bell.x)
			if away == 0.0:
				away = 1.0
			if (away < 0 and pos.x < main.L.ARENA_X0 + 80) or (away > 0 and pos.x > main.L.ARENA_X1 - 80):
				away = -away
			if absf(pos.x - bell.x) < 260.0:
				b["x"] = away
		_:
			# keep a safe distance from the bell's x
			var cx: float = bell.x
			var want := cx - 300.0 if pos.x < cx else cx + 300.0
			if want < main.L.ARENA_X0 + 60.0:
				want = cx + 300.0
			if want > main.L.ARENA_X1 - 60.0:
				want = cx - 300.0
			b["x"] = clampf((want - pos.x) / 40.0, -1.0, 1.0)
			# clear lings
			for h in get_tree().get_nodes_in_group("hush"):
				if h.global_position.distance_to(pos) < 120.0 and strike_cd <= 0.0:
					p.facing = signf(h.global_position.x - pos.x)
					b["strike_p"] = true
					strike_cd = 0.2

func _field_travel(b: Dictionary, pos: Vector2) -> void:
	if (pos.x > 5680 and pos.x < 6230) or (pos.x > 6840 and pos.x < 8000):
		b["jump"] = true
		for w in get_tree().get_nodes_in_group("windmill"):
			if not w.active: continue
			if absf(pos.x-w.global_position.x)<100 and pos.y > (-560.0 if pos.x>6800 else -390.0):
				b["x"] = clampf((w.global_position.x+15-pos.x)/30,-1,1)
				if p.is_on_floor(): b["jump_p"] = true

func _choir(b: Dictionary, pos: Vector2) -> void:
	var choir: BossChoir = main.boss
	for h in get_tree().get_nodes_in_group("hush"):
		if h.hurt_rect().intersects(p._strike_rect().grow(12)) and strike_cd <= 0:
			p.facing = signf(h.global_position.x-pos.x)
			b["strike_p"] = true
			strike_cd = 0.22
	var cx: float = choir.chest_x(choir.singer)
	var want := cx-65.0
	b["x"] = clampf((want-pos.x)/25.0,-1,1)
	b["jump"] = false
	for w in get_tree().get_nodes_in_group("boss_wave"):
		var dx: float = w.global_position.x-pos.x
		if signf(dx)==-w.dir and absf(dx)<145 and p.is_on_floor():
			b["jump_p"] = true
			b["jump"] = true
			jump_hold = 0.5
	if jump_hold>0:
		jump_hold -= get_physics_process_delta_time()
		b["jump"] = true
	if choir.state == "dazed" and absf(pos.x-want)<35 and pos.y > -160 and strike_cd<=0:
		p.facing = signf(cx-pos.x)
		b["strike_p"] = true
		strike_cd = 0.22

var tower_i := 1
func _tower(b: Dictionary,pos: Vector2,d: float) -> void:
	var route := Level4.route()
	var feet := pos.y+48
	if p.is_on_floor() and tower_i>1 and feet>route[tower_i-1].y+50:
		tower_i=maxi(1,int(-feet/100)+1)
	for e in get_tree().get_nodes_in_group("echo"):
		if not e.used and absf(e.position.y-feet)<30 and absf(e.position.x-pos.x)<115:
			b["x"]=0
			p.facing=signf(e.position.x-pos.x+0.01)
			if strike_cd<=0: b["strike_p"]=true;strike_cd=0.25
			return
	if tower_i>=route.size():
		b["x"]=1.0
		return
	var q: Vector2=route[tower_i]
	var dx:=q.x-pos.x
	b["x"]=clampf(dx/35,-1,1)
	if jump_hold>0: jump_hold-=d;b["jump"]=true
	else: b["jump"]=false
	if p.is_on_floor() and feet>q.y+25 and absf(dx)<160:
		b["jump_p"]=true;b["jump"]=true;jump_hold=0.5
	if feet<q.y+20 and feet>q.y-40 and absf(dx)<55 and p.is_on_floor(): tower_i+=1
	for h in get_tree().get_nodes_in_group("hush"):
		if h.hurt_rect().intersects(p._strike_rect().grow(20)) and strike_cd<=0:
			b["strike_p"]=true;strike_cd=0.22

func _heart(b: Dictionary,pos: Vector2) -> void:
	var h: HushHeart=main.boss
	var want:=h.weak_x()-65
	b["x"]=clampf((want-pos.x)/30,-1,1)
	b["jump"]=false
	b["down"]=false
	if h.state=="choice":
		if "--ending-a" in OS.get_cmdline_user_args():
			if strike_cd<=0: b["strike_p"]=true;strike_cd=0.3
		else: b["down"]=true
		return
	if h.state=="approach": b["x"]=1
	for w in get_tree().get_nodes_in_group("boss_wave"):
		if absf(w.global_position.x-pos.x)<145 and w.global_position.x>pos.x and p.is_on_floor():
			b["jump_p"]=true;jump_hold=0.45
	if jump_hold>0:
		jump_hold-=get_physics_process_delta_time()
		b["jump"]=true
	if h.state=="dazed" and absf(pos.x-want)<40 and pos.y>h.global_position.y-160 and strike_cd<=0:
		p.facing=1;b["strike_p"]=true;strike_cd=0.22
