class_name Sprites
extends RefCounted
## Builds every pixel sprite at runtime and caches the results.

static var _masks := {}
static var _frames := {}
static var _decor := {}
static var _plants := {}
static var _previews := {}
static var _misc := {}

const SHELL := ["...ooo...", "..olplo..", ".olplplo.", "olplplplo", "olplplplo", ".ooooooo.", "...opo..."]
const SHELL_PAL := {"o": "#7a3e32", "p": "#f0a890", "l": "#ffe0cc"}
const CHEST := [".oooooooooooo.", "ohhhhhhhhhhhho", "obbbbbbbbbbbbo", "oggggggggggggo", "obbbbbgkgbbbbo", "obbbbbgggbbbbo", "obbbbbbbbbbbbo", "oddddddddddddo", "oooooooooooooo"]
const CHEST_PAL := {"o": "#2a160c", "h": "#b07a44", "b": "#8a5a30", "d": "#6a4222", "g": "#e8b830", "k": "#2a160c"}
## Decor drawn as pixel rows: one string per row and a palette per item.
const DECOR_ART := {
	"starfish": {"pal": {"o": "#7a2e18", "y": "#ee7c3e", "Y": "#ffb070", "d": "#c8562a"}, "rows": [
		"....o....",
		"...oyo...",
		"...oYo...",
		"oooyYyooo",
		"oyyYYYyyo",
		".oyYdYyo.",
		"..oyYyo..",
		".oyyoyyo.",
		".oyo.oyo.",
		".oo...oo.",
	]},
	"moss": {"pal": {"L": "#86c85a", "m": "#4f9a3a", "D": "#2e6a2a"}, "rows": [
		"..........",
		"..LLLLmm..",
		".LLLLmmmm.",
		".LLmmmLLD.",
		"LLmmLmmDDD",
		"mLmmmmDDmD",
		".mmmDmmDD.",
		".mLmDDDDD.",
		"...DDDD...",
	]},
	"amphora": {"pal": {"o": "#3a1a10", "c": "#c8683a", "L": "#e8925a", "d": "#8a3a20", "b": "#2a1610"}, "rows": [
		"......oooo......",
		"....ooLLLLoo....",
		"..ooLLccccLLoo..",
		".oLccccccccccoo.",
		"oocbbbbbbbbbbcoo",
		"oLcccccccccccc.o",
		"ocLcccccccccccLo",
		"occcdcdcdcdcdcco",
		"ooccccccccccccoo",
		".ooddddddddddoo.",
		"...oooooooooo...",
	]},
	"driftwood": {"pal": {"o": "#2a1c12", "L": "#b8936a", "w": "#8a6a48", "d": "#5e4430", "k": "#3e2c1e"}, "rows": [
		"...oo...................oo....",
		"..owLo.................owdo...",
		"...owLo...............owdo....",
		"...owLo...............owdo....",
		"....owLo.............owdo.....",
		"....owLo.............owdo.....",
		".....owLo..ooo......owdo...o..",
		"..o..owLoooLLLooooo.owdooooLo.",
		".oLoooLLLLLwwwLLLLLoooLLLLLwo.",
		".owLLLwwwwwwwwwwwwwLLLwwwwwwo.",
		".owwwwwwkwwwwkwwwwwkwwwwkwwwo.",
		".oddddddddddddddddddddddddddo.",
		"..oooooooooooooooooooooooooo..",
	]},
	"diver": {"pal": {"o": "#1e1a18", "H": "#f6d27a", "h": "#d39a3e", "g": "#24476a", "G": "#9ad0f0", "s": "#5d6e80", "S": "#7f92a6", "b": "#2c2c30"}, "rows": [
		".....oooo.....",
		"...ooHHHHoo...",
		"..oHhhhhhhho..",
		".oHhoooooohho.",
		".ohoggggGgoho.",
		".ohogGgggggoho",
		".ohoggggggoho.",
		".ohhoooooohho.",
		"..ohhhhhhhho..",
		"..ooHhhhhHoo..",
		".ossoooooosso.",
		"osssSsssssSsso",
		"osSssssssssSso",
		"ossossssssosso",
		".oooSssssSooo.",
		"...osssssso...",
		"...ossoosso...",
		"...ossoosso...",
		"..obbbooobbbo.",
		"..oooo..oooo..",
	]},
	"castle": {"pal": {"o": "#26221e", "m": "#a39a8a", "L": "#cbc3b2", "d": "#77705f", "k": "#2c2018", "w": "#1c2a44", "p": "#3a2e26", "r": "#e2483e"}, "rows": [
		"....ooo............ooo..",
		"...oprro..........oprro.",
		"...opro...........opro..",
		"...opo............opo...",
		".o.opo.o........o.opo.o.",
		"omompmomo......omompmomo",
		"oLmmdmLdo......oddmmdmdo",
		"oLdmmmddo......oLddmmmdo",
		"oLmmmmLdo......oLdmmmmdo",
		"oLmwdmLdo.o.o.ooddmwdmdo",
		"oLdwmmddmodomodoLddwmmdo",
		"oLmmmmLdmmmmmmmmLdmmmmdo",
		"oLmmdmLddmmmdmmmddmmdmdo",
		"oLdmmmddmmdmmmdmLddmmmdo",
		"oLmmmmLdmwmmmmwmLdmmmmdo",
		"oLmwdmLddwmmdmwmddmwdmdo",
		"oLdwmmddmmdmmmdmLddwmmdo",
		"oLmmmmLdmmmkkmmmLdmmmmdo",
		"oLmmdmLddmkkkkmmddmmdmdo",
		"oLdmmmddmmkkkkdmLddmmmdo",
		"oLmmmmLdmmkkkkmmLdmmmmdo",
		"oLmmdmLddmkkkkmmddmmdmdo",
		"oLdmmmddmmkkkkdmLddmmmdo",
		"oLmmmmLdmmkkkkmmLdmmmmdo",
		"oLmmdmLddmkkkkmmddmmdmdo",
		"oLdmmmddmmkkkkdmLddmmmdo",
	]},
}
const STONE := [".ooo.", "oggho", "ogggo", ".ooo."]
const STONE_PAL := {"o": "#283040", "g": "#7a8898", "h": "#a8b6c4"}

static func _img(w: int, h: int) -> Image:
	var img := Image.create_empty(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


# ---------- fish ----------

static func mask(b: String, st: int) -> Dictionary:
	var k := b + str(st)
	if not _masks.has(k):
		_masks[k] = _build_mask(b, st)
	return _masks[k]


static func _build_mask(b: String, st: int) -> Dictionary:
	var P: Dictionary = D.BODIES[b]
	var sc: float = D.STAGES[st].scale
	var rx: float = maxf(1.6, P.rx * sc)
	var ry: float = maxf(1.1, P.ry * sc)
	var tl: int = maxi(1, D.jr(P.tl * sc))
	var fin_min := 0 if st == 0 else 1
	var dorsal = P.dorsal
	var anal = P.anal
	var fd := maxi(fin_min, D.jr(maxf(dorsal[2], dorsal[3]) * sc)) if dorsal != null else 0
	var fa := maxi(fin_min, D.jr(maxf(anal[2], anal[3]) * sc)) if anal != null else 0
	var tail: String = P.tail
	var droop := tl * 0.45 if tail == "veil" else 0.0
	var tail_h: float = ry if tail == "point" else 0.6 + tl * P.spread + droop
	var lure_h := 4 if P.get("lure", false) and st > 0 else 0
	var streamer_h: float = 7.0 * sc if P.get("streamers", false) else 0.0
	var pad := 3
	var w := ceili(rx * 2.0 + tl + pad * 2 + 1)
	var spines := 2.0 if P.get("spines", false) else 0.0
	var half: float = maxf(ry + maxf(maxf(fd + lure_h, fa), streamer_h) + spines, tail_h) + pad
	var h := ceili(half * 2.0) + 1
	var bx: float = pad + tl + rx
	var by: float = h / 2.0
	var g := PackedByteArray()
	g.resize(w * h)
	g.fill(0)
	for y in h:
		for x in w:
			var dx := (x + 0.5 - bx) / rx
			var dy := (y + 0.5 - by) / ry
			if dx * dx + dy * dy <= 1.0:
				g[y * w + x] = 1
	var jx := floori(bx - rx)
	for i in tl:
		var x := jx - i
		var hh: float = ry * (1.0 - (i + 1.0) / (tl + 1.0)) + 0.3 if tail == "point" else 0.5 + (i + 1) * P.spread
		var cy := by + (i * 0.45 if tail == "veil" else 0.0)
		for y in h:
			var ad := absf(y + 0.5 - cy)
			if ad > hh:
				continue
			if tail == "fork" and i >= tl - 2 and tl > 2 and ad < hh * 0.5:
				continue
			_mset(g, w, h, x, y, 2)
	for spec_dir in [[dorsal, -1], [anal, 1]]:
		var spec = spec_dir[0]
		var dir: int = spec_dir[1]
		if spec == null:
			continue
		var sweep: float = spec[4] if spec.size() > 4 else 0.0
		var x0 := D.jr(bx + spec[0] * rx)
		var x1 := D.jr(bx + spec[1] * rx)
		for x in range(x0, x1 + 1):
			var t := 0.0 if x1 == x0 else float(x - x0) / (x1 - x0)
			var fh := maxi(fin_min, D.jr(lerpf(spec[2], spec[3], t) * sc))
			if fh <= 0 or x < 0 or x >= w:
				continue
			var e := _edge(g, w, h, x, dir)
			if e < 0:
				e = D.jr(by + dir * ry * 0.5)
			for k in range(1, fh + 1):
				_mset(g, w, h, x - floori(k * sweep), e + dir * k, 2)
	if P.get("spines", false) and st > 0:
		for a in 14:
			var an := a / 14.0 * TAU
			if cos(an) < -0.7:
				continue
			_mset(g, w, h, D.jr(bx + cos(an) * (rx + 2.0) - 0.5), D.jr(by + sin(an) * (ry + 2.0) - 0.5), 3)
	if P.get("streamers", false) and st > 0:
		var sx := D.jr(bx + 0.1 * rx)
		var e := _edge(g, w, h, sx, 1)
		for k in range(1, D.jr(7.0 * sc) + 1):
			_mset(g, w, h, sx - floori(k * 0.45), e + k, 2)
	var ex := floori(bx + rx * 0.5)
	var ey := floori(by - ry * 0.35)
	g[ey * w + ex] = 4
	if st == 2:
		g[ey * w + ex - 1] = 5
	var lx := -1
	var ly := -1
	if lure_h > 0:
		var sx := ex + 1
		var e := _edge(g, w, h, sx, -1)
		_mset(g, w, h, sx, e - 1, 8)
		_mset(g, w, h, sx, e - 2, 8)
		_mset(g, w, h, sx + 1, e - 3, 8)
		_mset(g, w, h, sx + 2, e - 3, 9)
		lx = sx + 2
		ly = e - 3
	var out := g.duplicate()
	for y in h:
		for x in w:
			var i := y * w + x
			if g[i] != 0:
				continue
			var nb := false
			var nf := false
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var X: int = x + o.x
				var Y: int = y + o.y
				if X < 0 or Y < 0 or X >= w or Y >= h:
					continue
				var v := g[Y * w + X]
				if v == 1 or v == 4 or v == 5:
					nb = true
				elif v == 2:
					nf = true
			if nb:
				out[i] = 6
			elif nf:
				out[i] = 7
	return {"w": w, "h": h, "g": out, "bx": bx, "by": by, "rx": rx, "ry": ry, "jx": jx, "tl": tl, "lx": lx, "ly": ly}


static func _mset(g: PackedByteArray, w: int, h: int, x: int, y: int, v: int) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	var i := y * w + x
	if v == 1 or g[i] == 0:
		g[i] = v


## Returns the top (dir < 0) or bottom (dir > 0) body pixel in a column, or -1.
static func _edge(g: PackedByteArray, w: int, h: int, x: int, dir: int) -> int:
	if x < 0 or x >= w:
		return -1
	if dir < 0:
		for y in h:
			if g[y * w + x] == 1:
				return y
	else:
		for y in range(h - 1, -1, -1):
			if g[y * w + x] == 1:
				return y
	return -1


static func fish_tex(g: Dictionary, st: int, fr: int, mode: String = "") -> ImageTexture:
	var k := "%s|%s|%s|%s|%d|%d|%s" % [g.b, g.c1, g.c2, g.p, st, fr, mode]
	if not _frames.has(k):
		_frames[k] = ImageTexture.create_from_image(_fish_image(g, st, fr, mode))
	return _frames[k]


static func _fish_image(g: Dictionary, st: int, fr: int, mode: String) -> Image:
	var m := mask(g.b, st)
	var P: Dictionary = D.BODIES[g.b]
	var C1: Dictionary = D.COLORS[g.c1]
	var C2: Dictionary = D.COLORS[g.c2]
	var w: int = m.w
	var h: int = m.h
	var bx: float = m.bx
	var by: float = m.by
	var rx: float = m.rx
	var ry: float = m.ry
	var jx: int = m.jx
	var grid: PackedByteArray = m.g
	var img := _img(w, h + 2)
	var ph := fr / 4.0 * TAU
	var left := floori(bx - rx)
	var wave: bool = P.get("wave", false)
	var eye := Color("#0b0b16")
	var shine := Color("#f5f7ff")
	var glint := Color("#fffbe6")
	var lure := Color("#fff4a0")
	var sil_body := Color("#34466f")
	var sil_eye := Color("#26355a")
	for pass_i in 2:
		for yy in h:
			for xx in w:
				var v := grid[yy * w + xx]
				if v == 0:
					continue
				var tail := xx < jx
				if (pass_i == 0) != tail:
					continue
				var col: Color
				if v == 1:
					var sec := false
					if st > 0:
						match g.p:
							"striped":
								sec = (xx - left) % 3 == 1 and xx < bx + rx * 0.55
							"spotted":
								sec = D.hash2(xx, yy, st) < 0.24
							"split":
								sec = xx + 0.5 < bx - rx * 0.15
					col = C2.m if sec else (C1.l if yy + 0.5 > by + ry * 0.3 else C1.m)
					if g.c1 == "gilt" and not sec:
						var s := ((xx + yy - fr * 4) % 12 + 12) % 12
						if s < 2:
							col = glint
				elif v == 2:
					col = C2.l if xx % 2 == 0 else C2.m
				elif v == 3 or v == 6 or v == 8:
					col = C1.d
				elif v == 7:
					col = C2.d
				elif v == 4:
					col = eye
				elif v == 9:
					col = lure
				else:
					col = shine
				if mode == "dead":
					col = D.grey(col)
				elif mode == "sil":
					col = sil_eye if (v == 4 or v == 5) else sil_body
				var dx := 0
				var dy := 0
				if wave:
					dy = D.jr(sin(ph + xx * 0.55) * 0.9)
				elif tail and fr % 2 == 1:
					dx = D.jr((jx - xx) * 0.3)
				_px(img, xx + dx, yy + 1 + dy, col)
	return img


# ---------- decor ----------

static func _sprite_from(rows: Array, pal: Dictionary) -> Image:
	var img := _img(rows[0].length(), rows.size())
	for y in rows.size():
		var r: String = rows[y]
		for i in r.length():
			var ch := r[i]
			if ch != ".":
				img.set_pixel(i, y, Color(pal[ch]))
	return img


static func _outline(g: Array, w: int, h: int, img: Image, col: Color) -> void:
	for y in h:
		for x in w:
			if g[y * w + x] != 0:
				continue
			if (x > 0 and g[y * w + x - 1] != 0) or (x < w - 1 and g[y * w + x + 1] != 0) or (y > 0 and g[(y - 1) * w + x] != 0) or (y < h - 1 and g[(y + 1) * w + x] != 0):
				img.set_pixel(x, y, col)


static func _gen_rock(seed_value: int, arch: bool) -> Image:
	var r := D.Rng.new(seed_value * 7919 + 13)
	var w := 40 if arch else 16 + floori(r.next() * 8)
	var h := 24 if arch else 9 + floori(r.next() * 5)
	var warm := arch or r.next() < 0.3
	var pal: Array
	if warm:
		pal = ["#c8ad8a", "#9c7f63", "#715a46", "#33271d", "#86705a"]
	elif r.next() < 0.5:
		pal = ["#a3b1c0", "#76859a", "#526073", "#262e3b", "#66748a"]
	else:
		pal = ["#9fae9a", "#728470", "#526351", "#232c23", "#637561"]
	var cw := w + 4
	var chh := h + 4
	var g := []
	g.resize(cw * chh)
	g.fill(0)
	var cx := cw / 2.0
	var base := h + 2.0
	var rx := w / 2.0
	var ry := float(h)
	var p1 := r.next() * 6.0
	var p2 := r.next() * 6.0
	for y in chh:
		for x in cw:
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - base) / ry
			if dy > 0:
				continue
			var an := atan2(dy, dx)
			var rr := 1.0 + 0.1 * sin(an * 3.0 + p1) + 0.07 * sin(an * 7.0 + p2)
			var ins := dx * dx + dy * dy <= rr * rr
			if ins and arch:
				var ix := (x + 0.5 - cx) / (rx * 0.45)
				var iy := (y + 0.5 - base) / (ry * 0.6)
				if ix * ix + iy * iy < 1.0:
					ins = false
			if ins:
				g[y * cw + x] = 1
	var img := _img(cw, chh)
	for y in chh:
		for x in cw:
			if g[y * cw + x] == 0:
				continue
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - base) / ry
			var l := -dx * 0.55 - dy * 0.85
			if y == 0 or g[(y - 1) * cw + x] == 0:
				l += 0.35
			var ck := (x + y) % 2 == 0
			var col: String
			if l > 0.85:
				col = pal[0]
			elif l > 0.6:
				col = pal[0] if ck else pal[1]
			elif l > 0.3:
				col = pal[1]
			elif l > 0.1:
				col = pal[1] if ck else pal[2]
			else:
				col = pal[2]
			if D.hash2(x, y, seed_value) < 0.07:
				col = pal[4]
			img.set_pixel(x, y, Color(col))
	_outline(g, cw, chh, img, Color(pal[3]))
	return img


static func _gen_coral(seed_value: int) -> Image:
	var r := D.Rng.new(seed_value * 31 + 7)
	var w := 32
	var h := 28
	var g := []
	g.resize(w * h)
	g.fill(0)
	var pal: Array = ["#c23a5e", "#ea6382", "#ffb3bf", "#5c1530"] if r.next() < 0.5 else ["#d2602a", "#f2884a", "#ffcf94", "#5e2410"]
	_coral_branch(g, w, h, r, w / 2.0, h - 2.0, -PI / 2.0 + (r.next() - 0.5) * 0.2, 7.0, 0)
	var img := _img(w, h)
	for i in w * h:
		var v: int = g[i]
		if v != 0:
			img.set_pixel(i % w, i / w, Color(pal[v - 1]))
	_outline(g, w, h, img, Color(pal[3]))
	return img


static func _coral_set(g: Array, w: int, h: int, xf: float, yf: float, v: int) -> void:
	var x := D.jr(xf)
	var y := D.jr(yf)
	if x < 1 or y < 1 or x >= w - 1 or y >= h - 1:
		return
	var i := y * w + x
	if g[i] == 0 or v < g[i]:
		g[i] = v


static func _coral_branch(g: Array, w: int, h: int, r: D.Rng, x: float, y: float, a: float, length: float, d: int) -> void:
	var i := 0
	while i < length:
		x += cos(a)
		y += sin(a)
		_coral_set(g, w, h, x, y, 1 if d < 2 else 2)
		if d < 1:
			_coral_set(g, w, h, x + 1.0, y, 1)
		i += 1
	if d < 4:
		var a1 := a - 0.3 - r.next() * 0.35
		var l1 := length * (0.62 + r.next() * 0.2)
		_coral_branch(g, w, h, r, x, y, a1, l1, d + 1)
		var a2 := a + 0.3 + r.next() * 0.35
		var l2 := length * (0.62 + r.next() * 0.2)
		_coral_branch(g, w, h, r, x, y, a2, l2, d + 1)
	else:
		_coral_set(g, w, h, x + cos(a), y + sin(a), 3)


static func decor_img(type: String, seed_value: int) -> Image:
	var k := type + str(seed_value)
	if not _decor.has(k):
		var img: Image
		match type:
			"rock":
				img = _gen_rock(seed_value, false)
			"arch":
				img = _gen_rock(seed_value, true)
			"coral":
				img = _gen_coral(seed_value)
			"shell":
				img = _sprite_from(SHELL, SHELL_PAL)
			_ when DECOR_ART.has(type):
				img = _sprite_from(DECOR_ART[type].rows, DECOR_ART[type].pal)
			_:
				img = _sprite_from(CHEST, CHEST_PAL)
		_decor[k] = {"img": img, "tex": ImageTexture.create_from_image(img)}
	return _decor[k].img


static func decor_tex(type: String, seed_value: int) -> ImageTexture:
	decor_img(type, seed_value)
	return _decor[type + str(seed_value)].tex


static func stone_tex() -> ImageTexture:
	if not _misc.has("stone"):
		_misc["stone"] = ImageTexture.create_from_image(_sprite_from(STONE, STONE_PAL))
	return _misc["stone"]


const FACE_W := 40
const FACE_H := 52


## The keeper's face. The frame is "face", "smile" or "blink".
static func face_img(frame: String) -> Image:
	var k := "face_img_" + frame
	if not _misc.has(k):
		var rows: Array = {"smile": KeeperArt.SMILE, "blink": KeeperArt.BLINK}.get(frame, KeeperArt.FACE)
		_misc[k] = _sprite_from(rows, KeeperArt.PAL)
	return _misc[k]


static func face_tex(frame: String) -> ImageTexture:
	var k := "face_tex_" + frame
	if not _misc.has(k):
		_misc[k] = ImageTexture.create_from_image(face_img(frame))
	return _misc[k]


static func plant_data(type: String, seed_value: int) -> Array:
	var k := type + str(seed_value)
	if _plants.has(k):
		return _plants[k]
	var r := D.Rng.new(seed_value * 131 + 5)
	var out := []
	if type == "grass":
		var n := 5 + floori(r.next() * 4)
		var cols := [Color("#4fa05a"), Color("#3d8a4c"), Color("#6cbf6a"), Color("#2f7442")]
		for i in n:
			var ox := D.jr((r.next() - 0.5) * 10.0)
			var hh := 8 + floori(r.next() * 14)
			var col: Color = cols[floori(r.next() * 4)]
			var ph := r.next() * 6.0
			out.append({"ox": ox, "h": hh, "col": col, "ph": ph})
	elif type == "anemone":
		var sets := [["#e8709e", "#ffd0e0", "#b8487a", "#8a2e5a"], ["#a070e0", "#e0c8ff", "#7048b0", "#4e2e86"], ["#f09a4a", "#ffe0b0", "#c0602a", "#8a3e1a"]]
		var cs: Array = sets[floori(r.next() * 3)]
		var n := 9
		for i in n:
			out.append({"a": lerpf(-1.25, 1.25, float(i) / (n - 1)) + (r.next() - 0.5) * 0.15, "len": 6 + floori(r.next() * 4), "ph": r.next() * 6.0,
				"body": Color(cs[0]), "tip": Color(cs[1]), "stalk": Color(cs[2]), "dark": Color(cs[3])})
	else:
		var n := 2 + floori(r.next() * 2)
		for i in n:
			var ox := D.jr((r.next() - 0.5) * 8.0)
			var hh := floori(50.0 + r.next() * 45.0)
			var ph := r.next() * 6.0
			out.append({"ox": ox, "h": hh, "ph": ph})
	_plants[k] = out
	return out


const KELP_DARK := Color("#3d6624")
const KELP_STALK := Color("#4e7d2e")
const KELP_LEAF := Color("#86b84a")
const KELP_TIP := Color("#a6d65e")


## Draws a swaying plant. The target is a CanvasItem (live tank) or an Image (shop preview).
static func draw_plant(target: Object, type: String, x: int, by: int, seed_value: int, flip: bool, t: float, top_limit: int) -> void:
	var data := plant_data(type, seed_value)
	var s := -1 if flip else 1
	var ci := target as CanvasItem
	var img := target as Image
	if type == "grass":
		for b in data:
			var col: Color = b.col
			var bh: int = b.h
			var side := 1 if b.ox > 0 else -1
			var run_x := -99999
			var run_top := 0
			var run_len := 0
			for j in bh:
				var k := float(j) / bh
				var sx := D.jr(sin(t * 1.3 + b.ph + j * 0.12) * k * k * 3.0 + side * k * 2.0 * s)
				var px: int = x + b.ox * s + sx
				var py := by - j
				if px == run_x:
					run_top = py
					run_len += 1
				else:
					if run_len > 0:
						_fill(ci, img, run_x, run_top, 1, run_len, col)
					run_x = px
					run_top = py
					run_len = 1
			if run_len > 0:
				_fill(ci, img, run_x, run_top, 1, run_len, col)
		return
	if type == "anemone":
		var a0: Dictionary = data[0]
		_fill(ci, img, x - 3, by - 3, 6, 3, a0.stalk)
		_fill(ci, img, x - 3, by - 1, 6, 1, a0.dark)
		_fill(ci, img, x - 2, by - 4, 4, 1, a0.stalk)
		for tn in data:
			var ln: int = tn.len
			for j in ln:
				var sw := sin(t * 2.0 + tn.ph + j * 0.5) * j * 0.12 * s
				var px := D.jr(x - 0.5 + sin(tn.a) * j * 0.95 * s + sw)
				var py := D.jr(by - 4.5 - cos(tn.a) * j * 0.95)
				_fill(ci, img, px, py, 1, 1, tn.tip if j >= ln - 1 else tn.body)
		return
	for st in data:
		var sh: int = st.h
		for j in sh:
			var k := float(j) / sh
			var sx := D.jr(sin(t * 0.8 + st.ph + j * 0.06) * k * 4.0)
			var px: int = x + st.ox * s + sx
			var py := by - j
			if py < top_limit:
				break
			_fill(ci, img, px, py, 2, 1, KELP_DARK if j % 9 == 0 else KELP_STALK)
			if j % 6 == 3 and j > 2:
				var dir := (1 if (j / 6) % 2 == 1 else -1) * s
				_fill(ci, img, px + 2 if dir > 0 else px - 3, py, 3, 1, KELP_LEAF)
				_fill(ci, img, px + 4 if dir > 0 else px - 4, py - 1, 1, 1, KELP_TIP)


static func _fill(ci: CanvasItem, img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	if ci != null:
		ci.draw_rect(Rect2(x, y, w, h), col)
	elif img != null:
		var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
		if r.size.x > 0 and r.size.y > 0:
			img.fill_rect(r, col)


static func decor_preview(type: String) -> ImageTexture:
	if _previews.has(type):
		return _previews[type]
	var c := _img(44, 40)
	if type == "grass" or type == "kelp" or type == "anemone":
		var tmp := _img(44, 110)
		draw_plant(tmp, type, 22, 108, 4 if type == "kelp" else 3, false, 1.2, 18)
		if type == "anemone":
			c = tmp.get_region(Rect2i(10, 90, 24, 20))
		elif type == "kelp":
			var region := tmp.get_region(Rect2i(11, 28, 22, 80))
			region.resize(22, 40, Image.INTERPOLATE_NEAREST)
			c.blit_rect(region, Rect2i(0, 0, 22, 40), Vector2i(11, 0))
		else:
			c.blit_rect(tmp, Rect2i(0, 70, 44, 40), Vector2i(0, 0))
	else:
		# Crop to the item, so the shop thumbnail scales it up.
		var seed_value := 2 if type == "arch" else (5 if type == "rock" else 3)
		var im := decor_img(type, seed_value)
		var side := maxi(im.get_width(), im.get_height()) + 4
		c = _img(maxi(side, im.get_width() + 4), side)
		c.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((c.get_width() - im.get_width()) / 2, c.get_height() - im.get_height() - 1))
	_previews[type] = ImageTexture.create_from_image(c)
	return _previews[type]
