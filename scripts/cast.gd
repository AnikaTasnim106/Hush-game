class_name Cast
## Character designs (rig configs) and frozen poses.

static func wren() -> Dictionary:
	return {
		"scale": 1.0, "hair": Color("3b2418"), "hair_style": "bob",
		"coat": Color("2f5d7c"), "coat_dark": Color("23465e"), "pants": Color("3a3346"),
		"shoes": Color("6b3f2a"), "accent": Color("d8433a"), "skin": Color("f0c39d"),
		"scarf": true, "bell": true, "w_shoulder": 21.0, "w_hip": 19.0, "skirt": 9.0,
	}

static func lark() -> Dictionary:
	return {
		"scale": 1.08, "hair": Color("2a1c17"), "hair_style": "long",
		"coat": Color("e2b23c"), "coat_dark": Color("b8892a"), "pants": Color("3c3648"),
		"shoes": Color("4a3428"), "accent": Color("e2b23c"), "skin": Color("e9b892"),
		"scarf": false, "bell": false, "skirt": 18.0, "w_hip": 22.0, "thigh": 27.0, "shin": 27.0,
	}

static func baker() -> Dictionary:
	return {
		"scale": 1.12, "hair": Color("6a5a50"), "hair_style": "short", "hat": "baker",
		"coat": Color("c98a52"), "coat_dark": Color("9e6a3c"), "pants": Color("4a3d3a"),
		"shoes": Color("3b2a22"), "accent": Color("c98a52"), "skin": Color("e7b08a"),
		"scarf": false, "bell": false, "apron": true, "mustache": true, "belly": 7.0,
		"w_shoulder": 26.0, "w_hip": 26.0, "torso": 36.0, "thigh": 22.0, "shin": 22.0, "leg_w": 11.0, "arm_w": 8.5,
	}

static func lamplighter() -> Dictionary:
	return {
		"scale": 1.12, "hair": Color("b9b4ad"), "hair_style": "short", "hat": "flat",
		"coat": Color("4f6b4a"), "coat_dark": Color("3a5236"), "pants": Color("34303a"),
		"shoes": Color("2e2622"), "accent": Color("5b4a3a"), "skin": Color("dcab88"),
		"scarf": false, "bell": false, "beard": true, "skirt": 22.0,
		"thigh": 31.0, "shin": 31.0, "torso": 40.0, "w_shoulder": 20.0, "w_hip": 18.0, "leg_w": 8.0, "arm_w": 6.5,
	}

static func twin(cap: Color, shirt: Color) -> Dictionary:
	return {
		"scale": 0.72, "hair": Color("7a4a2a"), "hair_style": "short", "hat": "cap",
		"coat": shirt, "coat_dark": shirt.darkened(0.25), "pants": Color("3d4a5c"),
		"shoes": Color("5a3b2a"), "accent": cap, "skin": Color("f3caa8"),
		"scarf": false, "bell": false, "head_r": 19.0, "eye_size": 1.15, "skirt": 4.0,
	}

# Frozen poses: the moment each person was caught in (festival night).
static func pose_checking_watch() -> Dictionary:
	# baker: looking down at a pocket watch, the other arm holding a tray
	return {"lean": 0.08, "head": 0.45, "hf": Vector2(14, 6), "hb": Vector2(10, 14),
		"ff": Vector2(8, 0), "fb": Vector2(-9, 0), "hip": 2.0, "sq": 1.0}

static func pose_turning_away() -> Dictionary:
	# lamplighter: body turned, shoulders hunched, hand raised to hat brim
	return {"lean": -0.12, "head": 0.35, "hf": Vector2(14, -26), "hb": Vector2(-4, 30),
		"ff": Vector2(-4, 0), "fb": Vector2(-16, 0), "hip": 3.0, "sq": 0.98}

static func pose_whisper_a() -> Dictionary:
	# twin leaning in, hand cupped at mouth
	return {"lean": 0.28, "head": 0.1, "hf": Vector2(16, -26), "hb": Vector2(-8, 24),
		"ff": Vector2(12, 0), "fb": Vector2(-8, -4), "hip": 2.0, "sq": 1.0}

static func pose_pointing() -> Dictionary:
	# twin pointing toward the stage
	return {"lean": 0.05, "head": -0.15, "hf": Vector2(34, -18), "hb": Vector2(-6, 26),
		"ff": Vector2(9, 0), "fb": Vector2(-8, 0), "hip": 1.0, "sq": 1.0}

# ---------------------------------------------------------------- Chapter 3
static func pip() -> Dictionary:
	return {
		"scale": 0.86, "hair": Color("c27a3a"), "hair_style": "short", "hat": "cap",
		"coat": Color("6c7f9a"), "coat_dark": Color("53657e"), "pants": Color("4a5468"),
		"shoes": Color("3b2a22"), "accent": Color("b0503a"), "skin": Color("f1c19c"),
		"scarf": false, "bell": false, "skirt": 4.0, "head_r": 18.0, "eye_size": 1.1,
	}

static func ilse() -> Dictionary:
	return {
		"scale": 1.14, "hair": Color("c9c4c0"), "hair_style": "bun",
		"coat": Color("5b3a5e"), "coat_dark": Color("432a46"), "pants": Color("2e2a36"),
		"shoes": Color("2a2026"), "accent": Color("8a6a9a"), "skin": Color("e5b89a"),
		"scarf": false, "bell": false, "skirt": 30.0, "w_hip": 24.0,
		"thigh": 28.0, "shin": 28.0, "torso": 38.0, "w_shoulder": 20.0, "leg_w": 8.0, "arm_w": 6.5,
	}

static func abernathy() -> Dictionary:
	return {
		"scale": 0.96, "hair": Color("8a8580"), "hair_style": "bald", "mustache": true, "glasses": true,
		"coat": Color("7a5a3a"), "coat_dark": Color("5a4028"), "pants": Color("3a3430"),
		"shoes": Color("2a2220"), "accent": Color("7a5a3a"), "skin": Color("edc0a0"),
		"scarf": false, "bell": false, "belly": 8.0, "w_shoulder": 24.0, "w_hip": 25.0,
		"thigh": 21.0, "shin": 21.0, "leg_w": 10.0, "arm_w": 8.0,
	}

static func pose_ears_covered() -> Dictionary:
	return {"lean": 0.2, "head": 0.25, "hf": Vector2(8, -30), "hb": Vector2(-2, -32),
		"ff": Vector2(6, 0), "fb": Vector2(-8, 0), "hip": 6.0, "sq": 0.96}

static func pose_baton_raised() -> Dictionary:
	return {"lean": -0.08, "head": -0.2, "hf": Vector2(18, -36), "hb": Vector2(-14, -4),
		"ff": Vector2(10, 0), "fb": Vector2(-10, 0), "hip": 0.0, "sq": 1.02}

static func pose_peering() -> Dictionary:
	return {"lean": 0.25, "head": 0.05, "hf": Vector2(14, -24), "hb": Vector2(-10, 18),
		"ff": Vector2(12, 0), "fb": Vector2(-10, 0), "hip": 3.0, "sq": 1.0}

static func hollis() -> Dictionary:
	var c := baker()
	c["hat"] = "flat"
	c["coat"] = Color("b6a48d")
	c["coat_dark"] = Color("827461")
	return c
static func fen() -> Dictionary:
	var c := lark()
	c["hair_style"] = "braid"
	c["coat"] = Color("709564")
	c["coat_dark"] = Color("496746")
	c["accent"] = Color("afbe80")
	c["shawl"] = true
	return c
static func jory() -> Dictionary:
	var c := wren()
	c["scale"] = 1.13
	c["hair_style"] = "short"
	c["coat"] = Color("ad7959")
	c["coat_dark"] = Color("76523f")
	c["thigh"] = 33.0
	c["shin"] = 33.0
	c["w_shoulder"] = 17.0
	c["scarf"] = false
	c["bell"] = false
	return c
static func pose_folded() -> Dictionary:
	return {"lean":0.08,"hip":2.0,"sq":0.97,"head":0.4,"hf":Vector2(-12,10),"hb":Vector2(17,10),"ff":Vector2(10,0),"fb":Vector2(-10,0)}
static func pose_mouth() -> Dictionary:
	return {"lean":-0.05,"hip":0.0,"sq":1.0,"head":0.12,"hf":Vector2(9,-27),"hb":Vector2(-20,18),"ff":Vector2(9,0),"fb":Vector2(-9,0)}
static func pose_laugh() -> Dictionary:
	return {"lean":-0.15,"hip":0.0,"sq":1.02,"head":-0.4,"hf":Vector2(3,24),"hb":Vector2(-18,20),"ff":Vector2(12,0),"fb":Vector2(-12,0)}
