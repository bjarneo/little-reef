class_name Game
extends Node
## Tank simulation, camera and the tool actions. A GDScript port of aquarium-engine-v2.js.

signal changed
signal toast(text: String, kind: String)
signal world_resized
signal algae_texture_created(tex: ImageTexture)

# World layout in tank pixels.
var W := 256
var H := 160
var TOP := 12
var SAND := 134
var AW := 32
var AH := 19

# Screen and camera. view_size and the insets are in UI pixels.
var view_size := Vector2(1280, 800)
var inset_top := 0.0
var inset_bottom := 0.0
var base_scale := 2.0
var fit_scale := 2.0
var max_scale := 3.5
var zoom_t := 0.0
var cam := Vector2.ZERO
var cam_scale := 2.0
var cam_moved_t := -10.0

var S := {}
var algae := PackedFloat32Array()
var algae_rate := PackedFloat32Array()
var algae_tex: ImageTexture
var algae_avg := 0.0
var _algae_dirty := true
var _alg_pending := 0.0
var _alg_t := 0.0

var T := 0.0
var tool := "look"
var sel := -1
var sel_decor := -1
var parents: Array[int] = [-1, -1]
var speed := 1.0
var ptr := {"x": -99.0, "y": -99.0, "down": false, "over": false}
var drag := {}
var bubbles: Array = []
var pops: Array = []
var events: Array = []
var synth: Synth

var keeper := {"state": "hidden", "t": 0.0, "x": 0.0, "next": 20.0, "rewarded": false, "stay": 26.0, "hinted": false,
	"smile": 0.0, "next_smile": 3.0, "blink": 0.0, "next_blink": 2.5}

var _pending_level := 0
var _emit_acc := 0.0
var _sec_acc := 0.0
var _save_acc := 0.0
var _last_wall := 0.0

const FACE_RISE := 1.8
## Clean tool reach in tank pixels: waste and rotten food, and algae on the glass.
const CLEAN_R := 14.0
const SCRUB_R := 17.0
const KEEPER_LINES := ["Looking good.", "Nice tank.", "Hmm. Not bad.", "Don't tap the glass.", "I like that one.", "Carry on.", "Good water today."]


# ---------- setup ----------

func start(view: Vector2, top_inset: float, bottom_inset: float) -> void:
	view_size = view
	inset_top = top_inset
	inset_bottom = bottom_inset
	_load_settings()
	var loaded := _load()
	_pending_level = int(loaded.up.cap) if not loaded.is_empty() else 0
	_layout(true)
	if not loaded.is_empty():
		S = loaded
		algae = loaded.algae
		S.erase("algae")
		_remap(S.lay, false)
		_recount_algae()
	else:
		S = _fresh_state()
	var now := Time.get_unix_time_from_system()
	if S.saved > 0 and now - S.saved > 5.0:
		_catch_up(now - S.saved)
	_last_wall = now
	for f in S.fish:
		_discover(f.g, true)
	_upload_algae()
	_emit()


func _level() -> int:
	return int(S.up.cap) if not S.is_empty() else _pending_level


func set_view(view: Vector2, top_inset: float, bottom_inset: float) -> void:
	if view.is_equal_approx(view_size) and absf(top_inset - inset_top) < 1.0 and absf(bottom_inset - inset_bottom) < 1.0:
		return
	view_size = view
	inset_top = top_inset
	inset_bottom = bottom_inset
	_layout()


func _layout(force := false, grow := false) -> void:
	var cw := maxf(view_size.x, 160.0)
	var ch := maxf(view_size.y, 160.0)
	var sc0 := maxf(2.0, roundf(minf(cw, ch) / 170.0))
	var f: float = D.TANK[_level()]
	var nW := maxi(120, ceili(cw / sc0 * f))
	var nH := maxi(120, ceili(ch / sc0 * f))
	var fs := maxf(cw / nW, ch / nH)
	var nTop := clampi(ceili(inset_top / fs) + 3, 12, maxi(12, nH / 2))
	var nSand := nH - maxi(20, ceili(inset_bottom / fs) + 14)
	nSand = clampi(nSand, mini(nTop + 48, nH - 8), nH - 8)
	base_scale = sc0
	fit_scale = fs
	max_scale = maxf(fs * 1.05, sc0 * 1.75)
	if not force and nW == W and nH == H and nSand == SAND and nTop == TOP:
		_apply_zoom()
		return
	var o := {"W": W, "H": H, "TOP": TOP, "SAND": SAND, "AW": AW, "AH": AH}
	var center := (cam + view_size / (2.0 * cam_scale)) / Vector2(W, H)
	W = nW
	H = nH
	TOP = nTop
	SAND = nSand
	AW = ceili(W / 8.0)
	AH = maxi(1, ceili((H - TOP) / 8.0))
	if not S.is_empty():
		_remap(o, grow)
	_build_algae_rate()
	_algae_dirty = true
	_apply_zoom()
	cam = center * Vector2(W, H) - view_size / (2.0 * cam_scale)
	if zoom_t <= 0.001:
		cam = Vector2.ZERO
	_clamp_cam()
	world_resized.emit()


func _remap(o: Dictionary, grow: bool) -> void:
	var fx: float = float(W) / o.W
	var off: float = (W - o.W) * 0.5
	var span: float = maxf(1.0, o.SAND - o.TOP)
	var mx := func(x: float) -> float: return x + off if grow else x * fx
	var my := func(y: float) -> float: return TOP + (y - o.TOP) / span * (SAND - TOP)
	for f in S.fish:
		f.x = clampf(mx.call(f.x), 8, W - 8)
		f.y = clampf(my.call(f.y), TOP + 7, SAND - 2)
		f.tx = f.x
		f.ty = f.y
	for d in S.decor:
		d.x = clampf(mx.call(d.x), 10, W - 10)
	for w in S.waste:
		w.x = mx.call(w.x)
		w.y = sand_y(w.x) - 1 if w.rest else my.call(w.y)
	for p in S.food:
		p.x = mx.call(p.x)
		p.y = sand_y(p.x) - 1 if p.rest else my.call(p.y)
	for e in S.eggs:
		e.x = D.jr(mx.call(e.x))
		e.y = sand_y(e.x) - 2
	bubbles.clear()
	var oaw: int = o.AW
	var oah: int = o.AH
	if oaw != AW or oah != AH or algae.size() != AW * AH:
		var old := algae
		var n := PackedFloat32Array()
		n.resize(AW * AH)
		for y in AH:
			for x in AW:
				var ox := mini(oaw - 1, floori(float(x) * oaw / AW))
				var oy := mini(oah - 1, floori(float(y) * oah / AH))
				var i := oy * oaw + ox
				n[y * AW + x] = old[i] if i < old.size() else 0.0
		algae = n
	S.lay = {"W": W, "H": H, "TOP": TOP, "SAND": SAND, "AW": AW, "AH": AH}
	_recount_algae()


func _build_algae_rate() -> void:
	algae_rate.resize(AW * AH)
	for i in AW * AH:
		var cx := i % AW
		var cy := i / AW
		var edge := 1.6 if (cx < 3 or cx > AW - 4 or cy > AH - 5) else 1.0
		algae_rate[i] = (0.4 + D.hash2(cx, cy, 9) * 1.2) * edge


func sand_y(x: float) -> int:
	return SAND + D.jr(sin(x * 0.06) * 1.5 + sin(x * 0.17 + 2.0) * 0.8)


func decor_base(d: Dictionary) -> int:
	return sand_y(d.x) + 2 + D.jr(d.d * 10.0)


# ---------- camera ----------

func _apply_zoom() -> void:
	zoom_t = clampf(zoom_t, 0.0, 1.0)
	var old := cam_scale
	var ns := fit_scale * pow(max_scale / fit_scale, zoom_t) if max_scale > fit_scale else fit_scale
	var mid := cam + view_size / (2.0 * old)
	cam_scale = ns
	cam = mid - view_size / (2.0 * cam_scale)
	_clamp_cam()


func zoom_at(screen_pos: Vector2, factor: float) -> void:
	var world := screen_to_world(screen_pos)
	cam_scale = clampf(cam_scale * factor, fit_scale, max_scale)
	zoom_t = log(cam_scale / fit_scale) / log(max_scale / fit_scale) if max_scale > fit_scale else 0.0
	cam = world - screen_pos / cam_scale
	_clamp_cam()
	cam_moved_t = T


func zoom_step(dir: int) -> void:
	zoom_at(view_size * 0.5, 1.25 if dir > 0 else 0.8)


func set_zoom_scale(s: float, focus_world: Vector2, focus_screen: Vector2) -> void:
	cam_scale = clampf(s, fit_scale, max_scale)
	zoom_t = log(cam_scale / fit_scale) / log(max_scale / fit_scale) if max_scale > fit_scale else 0.0
	cam = focus_world - focus_screen / cam_scale
	_clamp_cam()
	cam_moved_t = T


func pan(screen_delta: Vector2) -> void:
	cam -= screen_delta / cam_scale
	_clamp_cam()
	cam_moved_t = T


func _clamp_cam() -> void:
	var v := view_size / cam_scale
	cam.x = clampf(cam.x, 0.0, maxf(0.0, W - v.x))
	cam.y = clampf(cam.y, 0.0, maxf(0.0, H - v.y))


func screen_to_world(p: Vector2) -> Vector2:
	return cam + p / cam_scale


## Camera position snapped to whole screen pixels so the pixel grid stays stable.
func cam_snapped() -> Vector2:
	return (cam * cam_scale).round() / cam_scale


func can_pan() -> bool:
	var v := view_size / cam_scale
	return v.x < W - 0.5 or v.y < H - 0.5


# ---------- state ----------

func _fresh_state() -> Dictionary:
	S = {"v": 1, "coins": 60, "total": 0, "day": 1, "t": 0.06, "water": 92.0, "fish": [], "decor": [], "waste": [], "food": [], "eggs": [],
		"up": {"cap": 0, "filter": 0, "pump": 0, "feeder": 0}, "book": {}, "ach": {},
		"stats": {"bought": 0, "feeds": 0, "hatched": 0, "raised": 0, "deaths": 0, "scrubs": 0.0, "keeper": 0},
		"nextId": 1, "autoFed": -1, "wcAt": -999.0, "simT": 0.0, "saved": Time.get_unix_time_from_system(), "filterAcc": 0.0}
	algae = PackedFloat32Array()
	algae.resize(AW * AH)
	algae.fill(0.0)
	algae_avg = 0.0
	var mid := TOP + (SAND - TOP) * 0.5
	_add_fish({"b": "pebble", "c1": "tangerine", "c2": "lemon", "p": "solid"}, 1, W * 0.35, mid)
	_add_fish({"b": "dart", "c1": "cobalt", "c2": "coral", "p": "striped"}, 1, W * 0.62, mid + 12)
	for it in [["grass", 0.17, 0.25, 11], ["kelp", 0.27, 0.1, 4], ["rock", 0.77, 0.55, 7], ["grass", 0.84, 0.2, 23], ["shell", 0.5, 0.9, 1], ["kelp", 0.92, 0.05, 9]]:
		S.decor.append({"id": _next_id(), "type": it[0], "x": float(D.jr(W * it[1])), "d": it[2], "seed": it[3], "flip": false})
	S.lay = {"W": W, "H": H, "TOP": TOP, "SAND": SAND, "AW": AW, "AH": AH}
	return S


func _next_id() -> int:
	var id: int = S.nextId
	S.nextId = id + 1
	return id


func _pick_name() -> String:
	var used := {}
	for f in S.fish:
		used[f.name] = true
	var free: Array = D.NAMES.filter(func(n): return not used.has(n))
	return free.pick_random() if not free.is_empty() else D.NAMES.pick_random()


func _add_fish(g: Dictionary, stage: int, x: float, y: float, bred := false) -> Dictionary:
	var f := {"id": _next_id(), "name": _pick_name(), "g": g, "x": x, "y": y, "vx": 0.0, "vy": 0.0, "face": 1 if randf() < 0.5 else -1,
		"tx": x, "ty": y, "wt": 0.0, "hunger": 75.0, "health": 100.0, "happy": 60.0, "growth": [0.0, 0.6, 1.6][stage], "age": [0.0, 0.6, 1.6][stage],
		"stage": stage, "alive": true, "deadT": 0.0, "coinAcc": 0.0, "poopAcc": randf_range(0, 25), "cd": 0.0, "phase": randf() * 6.0,
		"anim": randf() * 4.0, "bred": bred, "emo": "", "emoT": 0.0}
	S.fish.append(f)
	return f


func _alive() -> Array:
	return S.fish.filter(func(f): return f.alive)


func _plant_count() -> int:
	var n := 0
	for d in S.decor:
		if D.DECOR[d.type].has("plant"):
			n += 1
	return n


func fish_by_id(id: int):
	for f in S.fish:
		if f.id == id:
			return f
	return null


func decor_by_id(id: int):
	for d in S.decor:
		if d.id == id:
			return d
	return null


# ---------- save ----------

func save() -> void:
	if S.is_empty():
		return
	S.saved = Time.get_unix_time_from_system()
	var o := S.duplicate()
	var alg := []
	for v in algae:
		alg.append(roundi(v * 100.0))
	o.algae = alg
	o.waste = S.waste.map(func(w): return [roundi(w.x), roundi(w.y)])
	o.food = []
	o.fish = S.fish.map(func(f): return {"id": f.id, "name": f.name, "g": f.g, "x": roundi(f.x), "y": roundi(f.y), "face": f.face, "hunger": f.hunger,
		"health": f.health, "happy": f.happy, "growth": f.growth, "age": f.age, "stage": f.stage, "alive": f.alive, "deadT": f.deadT,
		"coinAcc": f.coinAcc, "poopAcc": f.poopAcc, "cd": f.cd, "phase": f.phase, "bred": f.bred})
	var file := FileAccess.open(D.SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(o))
		file.close()


func _load() -> Dictionary:
	if not FileAccess.file_exists(D.SAVE_PATH):
		return {}
	var text := FileAccess.get_file_as_string(D.SAVE_PATH)
	var s = JSON.parse_string(text)
	if typeof(s) != TYPE_DICTIONARY or int(s.get("v", 0)) != 1:
		return {}
	for k in ["coins", "total", "day", "nextId", "autoFed"]:
		s[k] = int(s.get(k, 0))
	for k in ["cap", "filter", "pump", "feeder"]:
		s.up[k] = int(s.up.get(k, 0))
	var stats: Dictionary = s.get("stats", {})
	for k in ["bought", "feeds", "hatched", "raised", "deaths", "keeper"]:
		stats[k] = int(stats.get(k, 0))
	stats["scrubs"] = float(stats.get("scrubs", 0.0))
	s.stats = stats
	s.filterAcc = float(s.get("filterAcc", 0.0))
	for f in s.fish:
		f.id = int(f.id)
		f.stage = int(f.stage)
		f.face = 1 if float(f.face) >= 0 else -1
		f.x = float(f.x)
		f.y = float(f.y)
		f.merge({"vx": 0.0, "vy": 0.0, "tx": f.x, "ty": f.y, "wt": 0.0, "anim": randf() * 4.0, "emo": "", "emoT": 0.0}, true)
	for d in s.decor:
		d.id = int(d.id)
		d.seed = int(d.seed)
		d.erase("bt")
	for e in s.eggs:
		e.x = int(e.x)
		e.y = int(e.y)
	s.food = []
	s.waste = s.waste.map(func(w): return {"x": float(w[0]), "y": float(w[1]), "rest": true})
	var alg := PackedFloat32Array()
	for v in s.get("algae", []):
		alg.append(float(v) / 100.0)
	s.algae = alg
	if typeof(s.get("lay")) != TYPE_DICTIONARY:
		s.lay = {"W": 256, "H": 160, "TOP": 14, "SAND": 134, "AW": 32, "AH": 18}
	for k in ["W", "H", "TOP", "SAND", "AW", "AH"]:
		s.lay[k] = int(s.lay[k])
	return s


func _load_settings() -> void:
	if not FileAccess.file_exists(D.SETTINGS_PATH):
		return
	var s = JSON.parse_string(FileAccess.get_file_as_string(D.SETTINGS_PATH))
	if typeof(s) == TYPE_DICTIONARY and synth:
		synth.set_on(bool(s.get("sound", true)))


func _save_settings() -> void:
	var file := FileAccess.open(D.SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"sound": synth.on}))
		file.close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		save()


# ---------- simulation ----------

func _earn(n: int, x: float, y: float, off: bool) -> void:
	S.coins += n
	S.total += n
	if not off:
		pops.append({"x": x, "y": y, "txt": "+" + str(n), "t": 0.0})
		synth.coin()


func _discover(g: Dictionary, quiet: bool) -> bool:
	var k: String = g.b + ":" + g.c1
	if S.book.has(k):
		return false
	S.book[k] = {"c2": g.c2, "p": g.p}
	if not quiet:
		toast.emit("New in your book: " + D.COLORS[g.c1].name + " " + D.BODIES[g.b].name, "new")
	return true


func _child(a: Dictionary, b: Dictionary) -> Dictionary:
	var ga: Dictionary = a.g
	var gb: Dictionary = b.g
	var body: String
	if ga.b == gb.b:
		body = ga.b
	elif ga.b in D.SPECIAL_BODIES or gb.b in D.SPECIAL_BODIES:
		var sp: String = ga.b if ga.b in D.SPECIAL_BODIES else gb.b
		var other: String = gb.b if sp == ga.b else ga.b
		body = sp if randf() < 0.5 else other
	else:
		var r := randf()
		body = "puff" if r < 0.12 else ("lantern" if r < 0.19 else [ga.b, gb.b].pick_random())
	var pool := [ga.c1, gb.c1, ga.c1, gb.c1, ga.c2, gb.c2]
	var c1: String = D.weighted_color() if randf() < 0.15 else pool.pick_random()
	var c2: String = D.weighted_color() if randf() < 0.15 else pool.pick_random()
	if c2 == c1 and randf() < 0.6:
		var alt := pool.filter(func(c): return c != c1)
		alt.append(D.COMMON.pick_random())
		c2 = alt.pick_random()
	var p: String = D.PATTERN_KEYS.pick_random() if randf() < 0.12 else [ga.p, gb.p].pick_random()
	return {"b": body, "c1": c1, "c2": c2, "p": p}


func _step(dt: float, off: bool) -> void:
	S.simT += dt
	S.t += dt / D.DAY
	if S.t >= 1.0:
		S.t -= 1.0
		S.day += 1
		S.autoFed = -1
	var sky := D.sky_at(S.t)
	var night: bool = sky.light < 0.6
	var alive := _alive()
	var cap: int = D.CAP[S.up.cap]
	var plants := _plant_count()
	var others: int = S.decor.size() - plants
	var crowd_n := maxi(0, alive.size() - cap)
	var env := {"night": night, "off": off, "pump": S.up.pump > 0, "decor": minf(22.0, plants * 3 + others * 2.5), "alg": algae_avg,
		"crowd": crowd_n * 6.0, "crowd_n": crowd_n}
	for f in S.fish:
		_update_fish(f, dt, env)
	for i in range(S.food.size() - 1, -1, -1):
		var p: Dictionary = S.food[i]
		if not p.rest:
			p.y += 7.0 * dt
			p.x += sin(T * 3.0 + p.ph) * 0.08
			var sy := sand_y(p.x) - 1
			if p.y >= sy:
				p.y = float(sy)
				p.rest = true
		else:
			p.age += dt
			if p.age > 30.0:
				p.rot = true
			if p.age > 75.0:
				S.food.remove_at(i)
				S.waste.append({"x": p.x, "y": p.y, "rest": true})
	for w in S.waste:
		if not w.rest:
			w.y += 5.0 * dt
			var sy := sand_y(w.x) - 1 + int(fmod(w.x, 3.0))
			if w.y >= sy:
				w.y = float(sy)
				w.rest = true
	if S.waste.size() > 90:
		S.waste = S.waste.slice(S.waste.size() - 90)
	if S.up.filter > 0 and not S.waste.is_empty():
		S.filterAcc += dt
		if S.filterAcc > 30.0 / S.up.filter:
			S.filterAcc = 0.0
			S.waste.pop_front()
	for i in range(S.eggs.size() - 1, -1, -1):
		var e: Dictionary = S.eggs[i]
		e.t -= dt
		if e.t <= 0.0:
			S.eggs.remove_at(i)
			_hatch(e, off)
	var bio := 0.0
	for f in alive:
		bio += D.STAGES[f.stage].size
	var rot := 0
	for p in S.food:
		if p.rot:
			rot += 1
	var rest := 0
	for w in S.waste:
		if w.rest:
			rest += 1
	var dead: int = S.fish.size() - alive.size()
	var decay: float = (0.012 * bio + 0.008 * rest + 0.03 * rot + 0.25 * dead + 0.02 * crowd_n) * D.FILTER[S.up.filter]
	var regen := plants * 0.006 + (0.004 if S.up.pump > 0 else 0.0)
	S.water = clampf(S.water + (regen - decay) * dt, 0.0, 100.0)
	_alg_pending += 0.0011 * sky.light * (2.2 if S.water < 60.0 else 1.0) * dt
	_alg_t += dt
	if _alg_t >= (30.0 if off else 0.25):
		_apply_algae()
	if S.up.feeder > 0:
		var slots := [0.08, 0.33, 0.58]
		for i in 3:
			if S.t >= slots[i] and S.t < slots[i] + 0.04 and i > S.autoFed:
				S.autoFed = i
				var n := mini(12, maxi(3, alive.size() * 2))
				for k in n:
					S.food.append({"x": randf_range(30, W - 30), "y": TOP + 1.0, "rest": false, "age": 0.0, "rot": false, "ph": randf() * 6.0})
				break
	if off:
		return
	if S.up.pump > 0 and randf() < dt * 7.0:
		bubbles.append({"x": W - 18 + randf_range(-1, 1), "y": sand_y(W - 18) - 2.0, "vy": -randf_range(16, 24), "r": 2 if randf() < 0.3 else 1, "ph": randf() * 6.0})
	for d in S.decor:
		if d.type == "chest":
			d.bt = d.get("bt", randf_range(2, 8)) - dt
			if d.bt <= 0:
				d.bt = randf_range(6, 11)
				var b := decor_base(d)
				for k in 6:
					bubbles.append({"x": d.x + randf_range(-4, 4), "y": b - 6.0 - k * 3, "vy": -randf_range(14, 22), "r": 2 if k % 2 == 1 else 1, "ph": randf() * 6.0})
				synth.bubble()
		elif d.type == "diver":
			d.bt = d.get("bt", randf_range(1, 5)) - dt
			if d.bt <= 0:
				d.bt = randf_range(4, 8)
				var top := decor_base(d) - Sprites.decor_img("diver", d.seed).get_height() + 1
				for k in 4:
					bubbles.append({"x": d.x + randf_range(-1, 1), "y": top - 1.0 - k * 3, "vy": -randf_range(12, 18), "r": 2 if k % 2 == 0 else 1, "ph": randf() * 6.0})
				synth.bubble()
	for i in range(bubbles.size() - 1, -1, -1):
		var b: Dictionary = bubbles[i]
		b.y += b.vy * dt
		b.x += sin(T * 4.0 + b.ph) * 0.12
		if b.y <= TOP + 1:
			bubbles.remove_at(i)
			if randf() < 0.08:
				synth.bubble()
	for i in range(pops.size() - 1, -1, -1):
		var p: Dictionary = pops[i]
		p.t += dt
		p.y -= 6.0 * dt
		if p.t > 1.4:
			pops.remove_at(i)


func _apply_algae() -> void:
	var g := _alg_pending
	_alg_pending = 0.0
	_alg_t = 0.0
	var sum := 0.0
	for i in algae.size():
		var v := minf(1.0, algae[i] + g * algae_rate[i])
		algae[i] = v
		sum += v
	algae_avg = sum / maxi(1, algae.size()) * 100.0
	_algae_dirty = true


func _recount_algae() -> void:
	var sum := 0.0
	for v in algae:
		sum += v
	algae_avg = sum / maxi(1, algae.size()) * 100.0
	_algae_dirty = true


func _update_fish(f: Dictionary, dt: float, env: Dictionary) -> void:
	if not f.alive:
		f.deadT += dt
		if not env.off:
			f.y = maxf(TOP + 5, f.y - 4.0 * dt)
			f.x += sin(T * 0.6 + f.phase) * 0.04
		return
	var P: Dictionary = D.BODIES[f.g.b]
	var sz: float = D.STAGES[f.stage].size
	var w: float = S.water
	f.hunger = clampf(f.hunger - dt * 0.2 * (0.55 + sz * 0.6) * (0.6 if env.night else 1.0), 0.0, 100.0)
	var dmg := 0.0
	if f.hunger < 10.0:
		dmg += 0.45
	if w < 30.0:
		dmg += (30.0 - w) / 30.0 * 0.6
	if env.crowd_n > 0:
		dmg += 0.03 * env.crowd_n
	if dmg > 0.0:
		f.health -= dmg * dt
	elif f.hunger > 35.0 and w > 45.0:
		f.health = minf(100.0, f.health + dt * 0.35 * (1.3 if env.pump else 1.0))
	if env.off:
		f.health = maxf(f.health, 12.0)
	if f.health <= 0.0:
		f.health = 0.0
		f.alive = false
		f.deadT = 0.0
		S.stats.deaths += 1
		events.append(["death", f])
		return
	var hp: float = 45.0 + (w - 50.0) * 0.5 + (10.0 if f.hunger > 50.0 else (-20.0 if f.hunger < 25.0 else 0.0)) + env.decor + (5.0 if env.pump else 0.0) - env.alg * 0.2 - env.crowd
	if f.health < 50.0:
		hp -= 15.0
	f.happy = clampf(hp, 0.0, 100.0)
	var prev: int = f.stage
	f.age += dt / D.DAY
	f.growth += dt / D.DAY * (1.0 if f.hunger > 30.0 else 0.25)
	f.stage = 0 if f.growth < 0.5 else (1 if f.growth < 1.5 else 2)
	if f.stage != prev and f.stage == 2:
		if f.bred:
			S.stats.raised += 1
		if not env.off:
			toast.emit(f.name + " is all grown up", "info")
	if f.cd > 0.0:
		f.cd = maxf(0.0, f.cd - dt / D.DAY)
	if f.stage == 2:
		f.coinAcc += D.income_of(f, env.night) / 60.0 * dt
		if f.coinAcc >= 1.0:
			var n := floori(f.coinAcc)
			f.coinAcc -= n
			_earn(n, f.x, f.y - 8.0, env.off)
	f.poopAcc += dt * sz * (f.hunger / 100.0)
	if f.poopAcc > 50.0:
		f.poopAcc = 0.0
		S.waste.append({"x": clampf(f.x - f.face * 4, 2, W - 2), "y": f.y + 1.0, "rest": false})
	if env.off:
		return
	if f.emoT > 0.0:
		f.emoT -= dt
		if f.emoT <= 0.0:
			f.emo = ""
	var sc: float = D.STAGES[f.stage].scale
	var spd: float = P.speed * (0.65 + sc * 0.35) * (0.4 if env.night else 1.0) * (0.6 if f.health < 35.0 else 1.0)
	var food: Dictionary = {}
	if (f.hunger < 90.0 and not env.night) or f.hunger < 50.0:
		var bd := 1e9
		for p in S.food:
			if p.rot:
				continue
			var d2: float = (p.x - f.x) * (p.x - f.x) + (p.y - f.y) * (p.y - f.y)
			if d2 < bd:
				bd = d2
				food = p
	if not food.is_empty():
		f.tx = food.x
		f.ty = minf(food.y, SAND - 2)
		spd *= 1.6
		if absf(food.x - f.x) < maxf(3.0, P.rx * sc * 0.8) and absf(food.y - f.y) < 3.0 + P.ry * sc * 0.6:
			S.food.erase(food)
			if f.hunger < 30.0:
				f.emo = "heart"
				f.emoT = 1.5
			f.hunger = minf(100.0, f.hunger + 16.0)
			synth.eat()
	else:
		f.wt -= dt
		if f.wt <= 0.0 or Vector2(f.tx - f.x, f.ty - f.y).length() < 4.0:
			f.wt = randf_range(3, 9)
			f.tx = randf_range(14, W - 14)
			if env.night:
				f.ty = randf_range(SAND - 34, SAND - 6)
			elif P.get("bottom", false):
				f.ty = randf_range(SAND - 26, SAND - 4)
			else:
				f.ty = randf_range(TOP + 12, SAND - 10)
	var dx: float = f.tx - f.x
	var dy: float = f.ty - f.y
	var d := sqrt(dx * dx + dy * dy)
	if d == 0.0:
		d = 1.0
	var slow := 1.0 if not food.is_empty() else minf(1.0, d / 14.0)
	var k := minf(1.0, dt * 1.6)
	f.vx += (dx / d * spd * slow - f.vx) * k
	f.vy += (dy / d * spd * 0.6 * slow - f.vy) * k
	f.x = clampf(f.x + f.vx * dt, 8, W - 8)
	f.y = clampf(f.y + f.vy * dt, TOP + 7, SAND - 2)
	if absf(f.vx) > 0.8:
		f.face = 1 if f.vx > 0 else -1
	f.anim += dt * (1.6 + absf(f.vx) * 0.35)
	if randf() < dt * 0.04:
		bubbles.append({"x": f.x + f.face * 4, "y": f.y - 1.0, "vy": -randf_range(12, 18), "r": 1, "ph": randf() * 6.0})


func _hatch(e: Dictionary, off: bool) -> void:
	var born := 0
	for g in e.kids:
		var f := _add_fish(g, 0, clampf(e.x + randf_range(-5, 5), 10, W - 10), e.y - 5.0, true)
		f.hunger = 70.0
		born += 1
		_discover(g, off)
	S.stats.hatched += born
	if not off:
		synth.hatch()
		toast.emit(str(born) + " fry hatched!", "good")


func _catch_up(gap: float) -> void:
	var sec := mini(1800, floori(gap))
	if sec < 5:
		return
	var c0: int = S.coins
	for i in int(sec * speed):
		_step(1.0, true)
	_apply_algae()
	var got: int = S.coins - c0
	events.clear()
	toast.emit("While you were away" + (": +%d coins" % got if got > 0 else "") + (" · the water needs attention" if S.water < 40.0 else ""), "info")


func _check_ach() -> void:
	for a in D.ACH:
		if S.ach.has(a.id):
			continue
		if _ach_met(a.id):
			S.ach[a.id] = 1
			S.coins += a.r
			S.total += a.r
			synth.ach()
			toast.emit("Achievement: %s · +%d coins" % [a.name, a.r], "ach")


func _ach_met(id: String) -> bool:
	match id:
		"first":
			return S.stats.bought >= 1
		"snack":
			return S.stats.feeds >= 25
		"keeper":
			return S.stats.keeper >= 1
		"clear":
			return S.water >= 99.5
		"green":
			return _plant_count() >= 5
		"designer":
			return S.decor.size() >= 8
		"parent":
			return S.stats.hatched >= 1
		"grown":
			return S.stats.raised >= 1
		"rare":
			for k in S.book:
				if k.split(":")[1] in D.RARE:
					return true
			return false
		"variety":
			var kinds := {}
			for f in _alive():
				kinds[f.g.b] = true
			return kinds.size() >= 6
		"puff", "lantern":
			for k in S.book:
				if k.begins_with(id + ":"):
					return true
			return false
		"collector":
			return S.book.size() >= 15
		"curator":
			return S.book.size() >= 40
		"house":
			return _alive().size() >= 12
		"tycoon":
			return S.total >= 1000
		"elder":
			for f in S.fish:
				if f.alive and f.age >= 10.0:
					return true
			return false
	return false


# ---------- frame loop ----------

func _process(delta: float) -> void:
	if S.is_empty():
		return
	var now := Time.get_unix_time_from_system()
	if _last_wall > 0.0 and now - _last_wall > 5.0:
		_catch_up(now - _last_wall)
	_last_wall = now
	var dt := minf(0.1, delta)
	T += dt
	_step(dt * speed, false)
	while not events.is_empty():
		var ev: Array = events.pop_front()
		if ev[0] == "death":
			synth.death()
			toast.emit(ev[1].name + " has died. Scoop them out before the water fouls.", "bad")
	_sec_acc += dt
	if _sec_acc > 1.0:
		_sec_acc = 0.0
		_check_ach()
	_save_acc += dt
	if _save_acc > 5.0:
		_save_acc = 0.0
		save()
	synth.music(T, D.sky_at(S.t).light)
	_keeper_update(dt)
	if _algae_dirty:
		_upload_algae()
	_emit_acc += dt
	if _emit_acc > 0.25:
		_emit_acc = 0.0
		_emit()


func _upload_algae() -> void:
	_algae_dirty = false
	var bytes := PackedByteArray()
	bytes.resize(AW * AH)
	for i in mini(algae.size(), AW * AH):
		bytes[i] = clampi(int(algae[i] * 255.0 + 0.5), 0, 255)
	var img := Image.create_from_data(AW, AH, false, Image.FORMAT_R8, bytes)
	if algae_tex and algae_tex.get_width() == AW and algae_tex.get_height() == AH:
		algae_tex.update(img)
	else:
		algae_tex = ImageTexture.create_from_image(img)
		algae_texture_created.emit(algae_tex)


func _emit() -> void:
	changed.emit()


# ---------- keeper ----------
# The keeper's face rises from behind the sand, looks in through the back glass,
# smiles now and then, and sinks back down.

func face_scale() -> int:
	return maxi(1, roundi((SAND - TOP) * 0.8 / Sprites.FACE_H))


func _keeper_update(dt: float) -> void:
	var k := keeper
	match k.state:
		"hidden":
			k.next -= dt
			if k.next <= 0.0:
				k.state = "rise"
				k.t = 0.0
				k.rewarded = false
				k.stay = 26.0
				k.smile = 0.0
				k.next_smile = randf_range(2.5, 5.0)
				var v := view_size / cam_scale
				var half := Sprites.FACE_W * face_scale() * 0.5
				k.x = clampf(cam.x + v.x * randf_range(0.3, 0.7), half, maxf(half, W - half))
				if not k.hinted and S.stats.keeper == 0:
					k.hinted = true
					toast.emit("The keeper is looking in from behind the tank. Tap the face to say hello.", "keeper")
		"rise":
			k.t += dt
			if k.t >= FACE_RISE:
				k.state = "stay"
				k.t = 0.0
		"stay":
			k.t += dt
			if k.smile > 0.0:
				k.smile -= dt
			else:
				k.next_smile -= dt
				if k.next_smile <= 0.0:
					k.smile = randf_range(1.6, 2.6)
					k.next_smile = randf_range(4.0, 9.0)
			if k.t >= k.stay:
				k.state = "sink"
				k.t = 0.0
				k.smile = 0.0
		"sink":
			k.t += dt
			if k.t >= FACE_RISE:
				k.state = "hidden"
				k.next = randf_range(70, 150)
	if k.state != "hidden":
		if k.blink > 0.0:
			k.blink -= dt
		else:
			k.next_blink -= dt
			if k.next_blink <= 0.0:
				k.blink = 0.14
				k.next_blink = randf_range(2.5, 5.0)


## How far the face has risen, from 0 (behind the sand) to 1.
func keeper_peek() -> float:
	match keeper.state:
		"rise":
			return keeper.t / FACE_RISE
		"stay":
			return 1.0
		"sink":
			return 1.0 - keeper.t / FACE_RISE
	return 0.0


func keeper_frame() -> String:
	if keeper.smile > 0.0:
		return "smile"
	if keeper.blink > 0.0:
		return "blink"
	return "face"


## The face's rectangle in tank pixels. It moves in steps of one sprite pixel.
func keeper_rect() -> Rect2:
	var s := face_scale()
	var w := Sprites.FACE_W * s
	var h := Sprites.FACE_H * s
	var e := clampf(keeper_peek(), 0.0, 1.0)
	e = e * e * (3.0 - 2.0 * e)
	var top := lerpf(SAND + 6.0, SAND + 5.0 - h, e)
	top = floorf(top / s) * s
	return Rect2(roundf(keeper.x - w / 2.0), top, w, h)


func keeper_hit(p: Vector2) -> bool:
	if keeper.state == "hidden" or p.y >= sand_y(p.x):
		return false
	var r := keeper_rect()
	if not r.has_point(p):
		return false
	var s := face_scale()
	var img := Sprites.face_img("face")
	var px := clampi(int((p.x - r.position.x) / s), 0, img.get_width() - 1)
	var py := clampi(int((p.y - r.position.y) / s), 0, img.get_height() - 1)
	return img.get_pixel(px, py).a > 0.0


func keeper_tap() -> void:
	if keeper.state != "stay" and keeper.state != "rise":
		return
	var alive := _alive()
	var hungry := alive.filter(func(f): return f.hunger < 25.0).size()
	var line: String
	if S.fish.size() > alive.size():
		line = "Somebody needs scooping out."
	elif S.water < 40.0:
		line = "That water looks rough. Time for a change."
	elif hungry > 0:
		line = "They look hungry to me."
	elif algae_avg > 50.0:
		line = "That glass needs a scrub."
	elif alive.is_empty():
		line = "An empty tank. Go buy some fish."
	elif S.decor.is_empty():
		line = "Bit bare in there."
	else:
		line = KEEPER_LINES.pick_random()
	if not keeper.rewarded:
		keeper.rewarded = true
		S.coins += 5
		S.total += 5
		S.stats.keeper += 1
		line += " +5 coins"
	synth.keeper()
	keeper.smile = 2.6
	keeper.stay = maxf(keeper.stay, keeper.t + 4.0)
	toast.emit(line, "keeper")
	_emit()


# ---------- hit tests ----------

func fish_box(f: Dictionary) -> Rect2:
	var m := Sprites.mask(f.g.b, f.stage)
	var x0: float = f.x - m.bx + 1.0
	var x1: float = f.x + (m.w - m.bx) - 1.0
	var y0: float = f.y - m.by + 1.0
	var y1: float = f.y + m.by - 1.0
	return Rect2(x0, y0, x1 - x0, y1 - y0)


func decor_box(d: Dictionary) -> Rect2:
	var b := decor_base(d)
	if d.type == "grass":
		return Rect2(d.x - 8, b - 22, 16, 23)
	if d.type == "anemone":
		return Rect2(d.x - 10, b - 16, 20, 17)
	if d.type == "kelp":
		var hh := 0
		for s in Sprites.plant_data("kelp", d.seed):
			hh = maxi(hh, s.h)
		var y0 := maxi(TOP + 6, b - hh)
		return Rect2(d.x - 8, y0, 16, b + 1 - y0)
	var im := Sprites.decor_img(d.type, d.seed)
	return Rect2(d.x - im.get_width() / 2.0, b - im.get_height() + 1, im.get_width(), im.get_height())


func _hit_fish(p: Vector2):
	var best = null
	var bd := 1e9
	for f in S.fish:
		if fish_box(f).grow(4.0).has_point(p):
			var d := p.distance_squared_to(Vector2(f.x, f.y))
			if d < bd:
				bd = d
				best = f
	return best


func hit_decor(p: Vector2):
	var s: Array = S.decor.duplicate()
	s.sort_custom(func(a, b): return a.d > b.d)
	for d in s:
		if decor_box(d).grow(2.0).has_point(p):
			return d
	return null


# ---------- tool input (world coordinates) ----------

func press(p: Vector2) -> void:
	ptr.x = p.x
	ptr.y = p.y
	ptr.down = true
	ptr.over = true
	match tool:
		"feed":
			_feed_at(p.x)
		"clean":
			_clean_at(p)
		"arrange":
			var d = hit_decor(p)
			sel_decor = d.id if d != null else -1
			sel = -1
			if d != null:
				drag = {"id": d.id, "ox": d.x - p.x, "sy": p.y, "sd": d.d}
				synth.click()
			_emit()


func hover(p: Vector2) -> void:
	ptr.x = p.x
	ptr.y = p.y
	ptr.over = true
	if not ptr.down:
		return
	if tool == "clean":
		_clean_at(p)
	if not drag.is_empty():
		var d = decor_by_id(drag.id)
		if d != null:
			d.x = clampf(p.x + drag.ox, 10, W - 10)
			d.d = clampf(drag.sd + (p.y - drag.sy) / 30.0, 0.0, 1.0)


func release(p: Vector2, tap: bool) -> void:
	if tool == "look" and tap and ptr.down:
		var f = _hit_fish(p)
		if f == null and keeper_hit(p):
			ptr.down = false
			keeper_tap()
			return
		sel = f.id if f != null else -1
		sel_decor = -1
		if f != null:
			synth.click()
		_emit()
	ptr.down = false
	if not drag.is_empty():
		drag = {}
		save()


func cancel_press() -> void:
	ptr.down = false
	if not drag.is_empty():
		drag = {}
		save()


func leave() -> void:
	ptr.over = false


func _feed_at(x: float) -> void:
	if S.food.size() >= 40:
		toast.emit("That's plenty of food for now", "info")
		return
	x = clampf(x, 6, W - 6)
	for i in 3:
		S.food.append({"x": x + randf_range(-3, 3), "y": TOP + 1.0 + randf_range(0, 2), "rest": false, "age": 0.0, "rot": false, "ph": randf() * 6.0})
	S.stats.feeds += 1
	synth.plop()


func _clean_at(p: Vector2) -> void:
	var n := 0
	for i in range(S.waste.size() - 1, -1, -1):
		var w: Dictionary = S.waste[i]
		if (w.x - p.x) * (w.x - p.x) + (w.y - p.y) * (w.y - p.y) < CLEAN_R * CLEAN_R:
			S.waste.remove_at(i)
			n += 1
	for i in range(S.food.size() - 1, -1, -1):
		var f: Dictionary = S.food[i]
		if f.rot and (f.x - p.x) * (f.x - p.x) + (f.y - p.y) * (f.y - p.y) < CLEAN_R * CLEAN_R:
			S.food.remove_at(i)
			n += 1
	if n > 0:
		S.water = minf(100.0, S.water + n * 0.6)
		synth.suck()
	var sc := 0.0
	var reach := SCRUB_R + 4.0
	var gx0 := maxi(0, floori((p.x - reach) / 8.0))
	var gx1 := mini(AW - 1, ceili((p.x + reach) / 8.0))
	var gy0 := maxi(0, floori((p.y - TOP - reach) / 8.0))
	var gy1 := mini(AH - 1, ceili((p.y - TOP + reach) / 8.0))
	for cy in range(gy0, gy1 + 1):
		for cx in range(gx0, gx1 + 1):
			var i := cy * AW + cx
			var px := cx * 8 + 4.0
			var py := TOP + cy * 8 + 4.0
			if (px - p.x) * (px - p.x) + (py - p.y) * (py - p.y) < SCRUB_R * SCRUB_R and algae[i] > 0.0:
				var before := algae[i]
				algae[i] = maxf(0.0, before - 0.35)
				sc += before - algae[i]
	if sc > 0.01:
		algae_avg = maxf(0.0, algae_avg - sc / algae.size() * 100.0)
		_algae_dirty = true
		S.stats.scrubs += sc
		synth.scrub()


# ---------- snapshot for the HUD ----------

func _status_of(f: Dictionary, night: bool) -> Array:
	if not f.alive:
		return ["Dead", "dead"]
	if f.health < 35.0:
		return ["Sick", "bad"]
	if f.hunger < 25.0:
		return ["Hungry", "warn"]
	if night:
		return ["Sleeping", "muted"]
	if f.happy > 70.0:
		return ["Happy", "good"]
	return ["Content", "muted"]


func breed_check() -> String:
	var a = fish_by_id(parents[0])
	var b = fish_by_id(parents[1])
	if a == null or b == null:
		return "Pick two adult fish"
	if not a.alive or not b.alive:
		return "Both parents must be alive"
	if a.stage < 2 or b.stage < 2:
		return "Both parents must be adults"
	if a.cd > 0.0 or b.cd > 0.0:
		return "Resting · ready in %dm" % ceili(maxf(a.cd, b.cd) * D.DAY / 60.0 / speed)
	if a.hunger < 40.0 or b.hunger < 40.0:
		return "Parents are too hungry"
	if a.health < 50.0 or b.health < 50.0:
		return "Parents need better health"
	if _alive().size() >= D.CAP[S.up.cap]:
		return "The tank is full"
	if S.eggs.size() >= 2:
		return "Wait for the eggs to hatch"
	return ""


func fish_info(f: Dictionary, night: bool) -> Dictionary:
	var st := _status_of(f, night)
	return {"id": f.id, "name": f.name, "variety": D.variety_name(f.g), "fins": D.COLORS[f.g.c2].name,
		"tex": Sprites.fish_tex(f.g, f.stage, 0, "" if f.alive else "dead"), "stage": D.STAGES[f.stage].name, "stage_i": f.stage,
		"age": "%.1f" % f.age, "hunger": roundi(f.hunger), "health": roundi(f.health), "happy": roundi(f.happy),
		"income": "%.1f" % D.income_of(f, night), "value": D.fish_value(f), "alive": f.alive, "adult": f.alive and f.stage == 2,
		"status": st[0], "tone": st[1], "isA": parents[0] == f.id, "isB": parents[1] == f.id, "selected": sel == f.id}


func snapshot() -> Dictionary:
	var sky := D.sky_at(S.t)
	var night: bool = sky.light < 0.6
	var h := D.hours_of(S.t)
	var alive := _alive()
	var cap: int = D.CAP[S.up.cap]
	var fish := []
	for f in S.fish:
		fish.append(fish_info(f, night))
	var pa = fish_by_id(parents[0])
	var pb = fish_by_id(parents[1])
	var avg := func(k: String) -> int:
		if alive.is_empty():
			return 0
		var t := 0.0
		for f in alive:
			t += f[k]
		return roundi(t / alive.size())
	var income := 0.0
	for f in alive:
		income += D.income_of(f, night)
	var sel_info = null
	for fi in fish:
		if fi.id == sel:
			sel_info = fi
	var sd = decor_by_id(sel_decor)
	var shop_fish := []
	for b in D.BODY_KEYS:
		var P: Dictionary = D.BODIES[b]
		if P.get("breed_only", false):
			continue
		shop_fish.append({"key": b, "name": P.name, "price": P.price, "income": P.income, "can": S.coins >= P.price and alive.size() < cap,
			"tex": Sprites.fish_tex({"b": b, "c1": P.show, "c2": P.show2, "p": "solid"}, 2, 0)})
	var shop_decor := []
	for k in D.DECOR_KEYS:
		var dd: Dictionary = D.DECOR[k]
		shop_decor.append({"key": k, "name": dd.name, "price": dd.price, "desc": dd.desc, "can": S.coins >= dd.price and S.decor.size() < max_decor(), "tex": Sprites.decor_preview(k)})
	var upgrades := []
	for k in D.UPG_KEYS:
		var u: Dictionary = D.UPG[k]
		var l: int = S.up[k]
		var maxed: bool = l >= u.prices.size()
		upgrades.append({"key": k, "name": u.name, "desc": D.upgrade_desc(k, l), "level": l, "max": u.prices.size(), "maxed": maxed,
			"price": 0 if maxed else u.prices[l], "can": not maxed and S.coins >= u.prices[l]})
	var eggs := []
	for e in S.eggs:
		eggs.append({"t": ceili(e.t / speed), "n": e.kids.size()})
	return {"fed": avg.call("hunger"), "health": avg.call("health"), "mood": avg.call("happy"),
		"sick": alive.filter(func(f): return f.health < 35.0).size(), "hungry": alive.filter(func(f): return f.hunger < 25.0).size(),
		"dead": S.fish.size() - alive.size(), "income": "%.1f" % income, "coins": S.coins, "day": S.day,
		"clock": "%02d:%02d" % [floori(h), floori(fmod(h, 1.0) * 6.0) * 10], "phase": D.phase_of(S.t),
		"water": roundi(S.water), "algae": roundi(algae_avg), "alive": alive.size(), "cap": cap, "tool": tool, "sound": synth.on,
		"wcIn": maxi(0, ceili((S.wcAt + 45.0 - S.simT) / speed)), "sel": sel_info,
		"selDecor": {"id": sd.id, "name": D.DECOR[sd.type].name, "refund": int(D.DECOR[sd.type].price / 2)} if sd != null else null,
		"fish": fish, "eggs": eggs, "shopFish": shop_fish, "shopDecor": shop_decor, "upgrades": upgrades,
		"parentA": fish_info(pa, night) if pa != null else null, "parentB": fish_info(pb, night) if pb != null else null,
		"breedMsg": breed_check(), "bookFound": S.book.size(), "bookTotal": D.BODY_KEYS.size() * D.COLOR_KEYS.size(),
		"achDone": S.ach.size(), "achTotal": D.ACH.size(), "decorCount": S.decor.size(), "decorMax": max_decor(), "total": S.total}


func book_rows() -> Array:
	var rows := []
	for b in D.BODY_KEYS:
		var cells := []
		for c in D.COLOR_KEYS:
			var e = S.book.get(b + ":" + c)
			var found: bool = e != null
			var tex := Sprites.fish_tex({"b": b, "c1": c, "c2": e.c2, "p": "solid"}, 2, 0) if found else Sprites.fish_tex({"b": b, "c1": "pearl", "c2": "pearl", "p": "solid"}, 2, 0, "sil")
			cells.append({"found": found, "rare": D.COLORS[c].has("rare"), "label": (D.COLORS[c].name + " " + D.BODIES[b].name) if found else "Undiscovered", "tex": tex})
		rows.append({"name": D.BODIES[b].name, "cells": cells})
	return rows


func ach_rows() -> Array:
	return D.ACH.map(func(a): return {"name": a.name, "desc": a.desc, "reward": a.r, "done": S.ach.has(a.id)})


# ---------- actions ----------

func set_tool(t: String) -> void:
	tool = t
	if t != "arrange":
		sel_decor = -1
	_emit()


func select(id: int) -> void:
	sel = id
	sel_decor = -1
	_emit()


func deselect() -> void:
	sel = -1
	sel_decor = -1
	_emit()


func buy_fish(b: String) -> void:
	var P: Dictionary = D.BODIES[b]
	if _alive().size() >= D.CAP[S.up.cap]:
		toast.emit("The tank is full. Upgrade it or sell a fish.", "bad")
		return
	if S.coins < P.price:
		toast.emit("Not enough coins", "info")
		return
	S.coins -= P.price
	var r := randf()
	var g := {"b": b, "c1": D.COMMON.pick_random(), "c2": D.COMMON.pick_random(), "p": "solid" if r < 0.55 else ("striped" if r < 0.8 else "spotted")}
	var f := _add_fish(g, 1, randf_range(40, W - 40), TOP + 8.0)
	f.hunger = 70.0
	S.stats.bought += 1
	synth.buy()
	_discover(g, false)
	toast.emit(f.name + " the " + D.variety_name(g) + " joined the tank", "good")
	sel = f.id
	save()
	_emit()


func buy_decor(type: String) -> void:
	var dd: Dictionary = D.DECOR[type]
	if S.decor.size() >= max_decor():
		toast.emit("No room for more decorations", "info")
		return
	if S.coins < dd.price:
		toast.emit("Not enough coins", "info")
		return
	S.coins -= dd.price
	var d := {"id": _next_id(), "type": type, "x": float(D.jr(randf_range(W * 0.2, W * 0.8))), "d": 0.5, "seed": randi() % 9999, "flip": randf() < 0.5}
	S.decor.append(d)
	synth.buy()
	tool = "arrange"
	sel_decor = d.id
	sel = -1
	_focus_on(Vector2(d.x, decor_base(d) - 10.0))
	toast.emit(dd.name + " placed. Drag it where you like.", "good")
	save()
	_emit()


## Pans the camera so a world point is in view. It does nothing at full zoom-out.
func max_decor() -> int:
	return D.MAX_DECOR[S.up.cap]


func _focus_on(p: Vector2) -> void:
	var v := view_size / cam_scale
	if p.x < cam.x + 12 or p.x > cam.x + v.x - 12 or p.y < cam.y + 12 or p.y > cam.y + v.y - 12:
		cam = p - v * 0.5
		_clamp_cam()
		cam_moved_t = T


func buy_upgrade(k: String) -> void:
	var u: Dictionary = D.UPG[k]
	var l: int = S.up[k]
	if l >= u.prices.size():
		return
	if S.coins < u.prices[l]:
		toast.emit("Not enough coins", "info")
		return
	S.coins -= u.prices[l]
	S.up[k] = l + 1
	synth.buy()
	if k == "cap":
		zoom_t = 0.0
		_layout(true, true)
		cam_moved_t = T
		toast.emit("The tank is bigger now. Pinch or scroll to zoom, drag to look around.", "good")
	else:
		toast.emit(u.name + " installed", "good")
	save()
	_emit()


func sell_fish(id: int) -> void:
	var f = fish_by_id(id)
	if f == null or not f.alive:
		return
	var v := D.fish_value(f)
	S.coins += v
	S.fish.erase(f)
	_forget(id)
	synth.coin()
	toast.emit("Sold %s for %d coins" % [f.name, v], "info")
	save()
	_emit()


func scoop(id: int) -> void:
	var f = fish_by_id(id)
	if f == null:
		return
	S.fish.erase(f)
	_forget(id)
	synth.splash()
	toast.emit("Goodbye, " + f.name, "info")
	save()
	_emit()


func _forget(id: int) -> void:
	if sel == id:
		sel = -1
	for i in 2:
		if parents[i] == id:
			parents[i] = -1


func set_parent(slot: int, id: int) -> void:
	if parents[1 - slot] == id:
		parents[1 - slot] = -1
	parents[slot] = -1 if parents[slot] == id else id
	synth.click()
	_emit()


func breed() -> void:
	var msg := breed_check()
	if msg != "":
		toast.emit(msg, "info")
		return
	var a: Dictionary = fish_by_id(parents[0])
	var b: Dictionary = fish_by_id(parents[1])
	var mood: float = (a.happy + b.happy) / 2.0
	var n := 1 + (1 if mood > 50.0 else 0) + (1 if mood > 80.0 else 0) + (1 if randf() < 0.3 else 0)
	var kids := []
	for i in n:
		kids.append(_child(a, b))
	var plants: Array = S.decor.filter(func(d): return D.DECOR[d.type].has("plant"))
	var x: float = plants.pick_random().x + randf_range(-4, 4) if not plants.is_empty() else (a.x + b.x) / 2.0
	S.eggs.append({"x": D.jr(clampf(x, 10, W - 10)), "y": sand_y(x) - 2, "t": 40.0, "kids": kids})
	a.cd = 1.0
	b.cd = 1.0
	a.emo = "heart"
	b.emo = "heart"
	a.emoT = 3.0
	b.emoT = 3.0
	a.hunger -= 15.0
	b.hunger -= 15.0
	synth.hatch()
	toast.emit("Eggs laid! They hatch in about 40 seconds.", "good")
	save()
	_emit()


func water_change() -> void:
	if S.wcAt + 45.0 - S.simT > 0.0:
		toast.emit("Let the water settle first", "info")
		return
	if S.coins < 15:
		toast.emit("A water change costs 15 coins", "info")
		return
	S.coins -= 15
	S.water = minf(100.0, S.water + 35.0)
	S.wcAt = S.simT
	for i in algae.size():
		algae[i] *= 0.85
	_recount_algae()
	for k in 20:
		bubbles.append({"x": randf_range(20, W - 20), "y": randf_range(TOP + 20, SAND), "vy": -randf_range(20, 40), "r": 1 if k % 3 != 0 else 2, "ph": randf() * 6.0})
	synth.splash()
	save()
	_emit()


func flip_decor(id: int) -> void:
	var d = decor_by_id(id)
	if d != null:
		d.flip = not d.flip
		_emit()


func store_decor(id: int) -> void:
	var d = decor_by_id(id)
	if d == null:
		return
	var r := int(D.DECOR[d.type].price / 2)
	S.coins += r
	S.decor.erase(d)
	sel_decor = -1
	synth.coin()
	toast.emit("Removed %s · +%d coins" % [D.DECOR[d.type].name, r], "info")
	save()
	_emit()


func set_sound(v: bool) -> void:
	synth.set_on(v)
	_save_settings()
	_emit()


func set_speed(n: float) -> void:
	speed = maxf(0.25, n)
	_emit()


func cheat(n: int) -> void:
	S.coins += n
	synth.ach()
	toast.emit("+%d coins" % n, "ach")
	save()
	_emit()


func reset() -> void:
	_pending_level = 0
	S = {}
	zoom_t = 0.0
	_layout(true)
	S = _fresh_state()
	sel = -1
	sel_decor = -1
	parents = [-1, -1]
	bubbles.clear()
	pops.clear()
	_algae_dirty = true
	for f in S.fish:
		_discover(f.g, true)
	save()
	toast.emit("A fresh tank. Good luck!", "info")
	_emit()
