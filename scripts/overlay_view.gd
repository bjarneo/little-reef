class_name OverlayView
extends Node2D
## Draws the layer above the day and night tint: glass glints, emotes, timers, selection and tool cursors.

var g: Game

const DIG := {"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111", "4": "101101111001001",
	"5": "111100111001111", "6": "111100111101111", "7": "111001001001001", "8": "111101111101111", "9": "111101111001111", "+": "000010111010000"}
const HEART := ["01010", "11111", "11111", "01110", "00100"]
const BANG := ["1", "1", "1", "0", "1"]
const ZZZ := ["111", "010", "111"]
const SHADOW := Color("#0b1120")
const GLASS := Color(1, 1, 1, 0.06)


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if g == null or g.S.is_empty():
		return
	var S := g.S
	var T := g.T
	var W := g.W
	var TOP := g.TOP
	var SAND := g.SAND
	var gx := D.jr(W * 0.04)
	draw_rect(Rect2(gx, TOP + 4, 1, SAND - TOP - 8), GLASS)
	draw_rect(Rect2(gx + 2, TOP + 4, 1, D.jr((SAND - TOP) * 0.35)), GLASS)
	draw_rect(Rect2(W - gx, TOP + 10, 1, D.jr((SAND - TOP) * 0.25)), GLASS)
	var sky := D.sky_at(S.t)
	var night: bool = sky.light < 0.6
	for f in S.fish:
		if not f.alive:
			continue
		if night and D.BODIES[f.g.b].get("lure", false) and f.stage > 0:
			_draw_glow(f)
		var bx := g.fish_box(f)
		var x := D.jr(bx.position.x + bx.size.x / 2.0)
		var y := D.jr(bx.position.y) - 6
		if f.emo == "heart":
			_icon(HEART, x - 2, y - 1, Color("#ff6f8a"))
		elif f.health < 35.0:
			_icon(BANG, x, y, Color("#8ee07a"))
		elif f.hunger < 25.0:
			_icon(BANG, x, y, Color("#ffb340"))
		elif night and floori(T * 1.2 + f.phase) % 3 == 0:
			_icon(ZZZ, x + 2, y + 1, Color("#c8d4ff"))
	for e in S.eggs:
		var s := str(ceili(e.t))
		_text(s, e.x - s.length() * 2 + 1, e.y - 9, Color("#fff6dc"))
	var blink := floori(T * 3.0) % 2 == 0
	if g.sel >= 0:
		var f = g.fish_by_id(g.sel)
		if f != null:
			var b := g.fish_box(f)
			_bracket(b.position.x - 2, b.position.y - 2, b.end.x + 2, b.end.y + 2, Color.WHITE if blink else Color("#7fe6f2"))
	if g.tool == "arrange":
		var hd = g.decor_by_id(g.sel_decor) if g.sel_decor >= 0 else (g.hit_decor(Vector2(g.ptr.x, g.ptr.y)) if g.ptr.over else null)
		if hd != null:
			var b := g.decor_box(hd)
			var col := (Color.WHITE if blink else Color("#7fe6f2")) if g.sel_decor >= 0 else Color(1, 1, 1, 0.6)
			_bracket(b.position.x - 1, b.position.y - 1, b.end.x + 1, b.end.y + 1, col)
	for p in g.pops:
		var a := clampf(1.4 - p.t, 0.0, 1.0)
		_text(p.txt, D.jr(p.x - p.txt.length() * 2), D.jr(p.y), Color(1, 0.827, 0.306, a), a)
	if g.tool == "clean" and g.ptr.over:
		var x := D.jr(g.ptr.x)
		var y := D.jr(g.ptr.y)
		if g.ptr.down:
			draw_rect(Rect2(x - 1, 5, 3, y - 5), Color(210 / 255.0, 236 / 255.0, 244 / 255.0, 0.45))
			draw_rect(Rect2(x - 1, 5, 1, y - 5), Color(1, 1, 1, 0.35))
			draw_rect(Rect2(x - 2, y - 1, 5, 3), Color(160 / 255.0, 200 / 255.0, 214 / 255.0, 0.8))
		var ring := Color(1, 1, 1, 0.55)
		for i in 32:
			var an := i / 32.0 * TAU + T
			draw_rect(Rect2(D.jr(x + cos(an) * Game.CLEAN_R), D.jr(y + sin(an) * Game.CLEAN_R), 1, 1), ring)
	if g.tool == "feed" and g.ptr.over and g.ptr.y < SAND:
		var x := D.jr(g.ptr.x)
		var dash := Color(1, 1, 1, 0.5)
		var y := TOP + 2
		while y < SAND:
			draw_rect(Rect2(x, y, 1, 2), dash)
			y += 4


## Draws the Lantern lure light on top of the night tint so it glows.
func _draw_glow(f: Dictionary) -> void:
	var m := Sprites.mask(f.g.b, f.stage)
	if m.lx < 0:
		return
	var rbx := D.jr(m.bx)
	var lx: int = m.lx
	var px: int = D.jr(f.x) + (lx - rbx if f.face > 0 else -(lx - rbx) - 1)
	var py: int = D.jr(f.y) + m.ly - D.jr(m.by)
	var pulse := 0.75 + 0.25 * sin(g.T * 3.0 + f.phase)
	draw_rect(Rect2(px - 2, py - 1, 5, 3), Color(1, 0.95, 0.6, 0.12 * pulse))
	draw_rect(Rect2(px - 1, py - 2, 3, 5), Color(1, 0.95, 0.6, 0.12 * pulse))
	draw_rect(Rect2(px - 1, py, 3, 1), Color(1, 0.95, 0.6, 0.3 * pulse))
	draw_rect(Rect2(px, py - 1, 1, 3), Color(1, 0.95, 0.6, 0.3 * pulse))
	draw_rect(Rect2(px, py, 1, 1), Color("#fffbe0"))


func _text(s: String, x: int, y: int, col: Color, alpha := 1.0) -> void:
	var sh := Color(SHADOW, alpha)
	for ch in s:
		var b: String = DIG.get(ch, "")
		if b != "":
			for i in 15:
				if b[i] == "1":
					draw_rect(Rect2(x + i % 3, y + i / 3 + 1, 1, 1), sh)
			for i in 15:
				if b[i] == "1":
					draw_rect(Rect2(x + i % 3, y + i / 3, 1, 1), col)
		x += 4


func _icon(rows: Array, x: int, y: int, col: Color) -> void:
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			if r[i] == "1":
				draw_rect(Rect2(x + i + 1, y + j, 1, 1), SHADOW)
				draw_rect(Rect2(x + i, y + j + 1, 1, 1), SHADOW)
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			if r[i] == "1":
				draw_rect(Rect2(x + i, y + j, 1, 1), col)


func _bracket(x0f: float, y0f: float, x1f: float, y1f: float, col: Color) -> void:
	var x0 := D.jr(x0f)
	var y0 := D.jr(y0f)
	var x1 := D.jr(x1f)
	var y1 := D.jr(y1f)
	for c in [[x0, y0, 1, 1], [x1, y0, -1, 1], [x0, y1, 1, -1], [x1, y1, -1, -1]]:
		var x: int = c[0]
		var y: int = c[1]
		draw_rect(Rect2(x if c[2] > 0 else x - 2, y, 3, 1), col)
		draw_rect(Rect2(x, y if c[3] > 0 else y - 2, 1, 3), col)
