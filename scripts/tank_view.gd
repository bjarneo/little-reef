class_name TankView
extends Node2D
## Draws the tank scene layer: light rays, decor, waste, food, eggs, fish, bubbles and the water surface.

var g: Game

const WASTE_A := Color("#4a3a24")
const WASTE_B := Color("#6a5534")
const FOOD_A := Color("#b8682c")
const FOOD_B := Color("#f0a858")
const ROT_A := Color("#4e4a2a")
const ROT_B := Color("#6a6236")
const EGG_A := Color("#e0c890")
const EGG_B := Color("#fff6dc")
const BUBBLE_1 := Color(220 / 255.0, 244 / 255.0, 1.0, 0.75)
const BUBBLE_2 := Color(220 / 255.0, 244 / 255.0, 1.0, 0.6)
const BUBBLE_C := Color(1, 1, 1, 0.9)
const SURFACE := Color("#b9e6f4")
const SURFACE_LINE := Color(1, 1, 1, 0.18)
const EGG_OFFS := [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(3, -1)]


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
	var sky := D.sky_at(S.t)
	if sky.light > 0.5:
		var col := Color(1, 1, 1, 0.05 * (sky.light - 0.4))
		var span := float(SAND - TOP)
		for i in ceili(W / 64.0):
			var x0 := fmod(i * 71 + T * 3.0, W + 60) - 50.0
			var w := 9.0 + i * 2
			draw_colored_polygon(PackedVector2Array([Vector2(x0, TOP), Vector2(x0 + w, TOP), Vector2(x0 + w + span * 0.45, SAND), Vector2(x0 + span * 0.45, SAND)]), col)
	var sorted: Array = S.decor.duplicate()
	sorted.sort_custom(func(a, b): return a.d < b.d)
	for d in sorted:
		if d.d < 0.5:
			_draw_decor(d, T)
	if S.up.pump > 0:
		draw_texture(Sprites.stone_tex(), Vector2(W - 20, g.sand_y(W - 18) - 2))
	for w in S.waste:
		var x := D.jr(w.x)
		var y := D.jr(w.y)
		draw_rect(Rect2(x, y, 2, 1), WASTE_A)
		draw_rect(Rect2(x, y, 1, 1), WASTE_B)
	for p in S.food:
		var x := D.jr(p.x)
		var y := D.jr(p.y)
		draw_rect(Rect2(x, y, 2, 2), ROT_A if p.rot else FOOD_A)
		draw_rect(Rect2(x, y, 1, 1), ROT_B if p.rot else FOOD_B)
	for e in S.eggs:
		var wob := D.jr(sin(T * 3.0 + e.x) * 0.5)
		for o in EGG_OFFS:
			draw_rect(Rect2(e.x + o.x, e.y + o.y + wob, 2, 2), EGG_A)
			draw_rect(Rect2(e.x + o.x, e.y + o.y + wob, 1, 1), EGG_B)
	for f in S.fish:
		if f.alive:
			_draw_fish(f)
	for f in S.fish:
		if not f.alive:
			_draw_fish(f)
	for b in bubbles_list():
		var x := D.jr(b.x)
		var y := D.jr(b.y)
		if b.r == 1:
			draw_rect(Rect2(x, y, 1, 1), BUBBLE_1)
		else:
			draw_rect(Rect2(x, y - 1, 1, 1), BUBBLE_2)
			draw_rect(Rect2(x - 1, y, 1, 1), BUBBLE_2)
			draw_rect(Rect2(x + 1, y, 1, 1), BUBBLE_2)
			draw_rect(Rect2(x, y + 1, 1, 1), BUBBLE_2)
			draw_rect(Rect2(x, y, 1, 1), BUBBLE_C)
	for d in sorted:
		if d.d >= 0.5:
			_draw_decor(d, T)
	# Water surface, merged into runs of equal height.
	var run_x := 0
	var run_up := false
	for x in W + 1:
		var up := x < W and sin(x * 0.3 + T * 2.0) + sin(x * 0.11 - T * 1.3) > 0.4
		if x == 0:
			run_up = up
			continue
		if x == W or up != run_up:
			draw_rect(Rect2(run_x, TOP - 1 if run_up else TOP, x - run_x, 1), SURFACE)
			run_x = x
			run_up = up
	draw_rect(Rect2(0, TOP + 1, W, 1), SURFACE_LINE)


func bubbles_list() -> Array:
	return g.bubbles


func _draw_decor(d: Dictionary, t: float) -> void:
	var b := g.decor_base(d)
	if D.DECOR[d.type].get("anim", false):
		Sprites.draw_plant(self, d.type, D.jr(d.x), b, d.seed, d.flip, t, g.TOP + 6)
		return
	var tex := Sprites.decor_tex(d.type, d.seed)
	var w := tex.get_width()
	var y := b - tex.get_height() + 1
	if d.flip:
		draw_set_transform(Vector2(D.jr(d.x), 0), 0.0, Vector2(-1, 1))
		draw_texture(tex, Vector2(-D.jr(w / 2.0), y))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture(tex, Vector2(D.jr(d.x - w / 2.0), y))


func _draw_fish(f: Dictionary) -> void:
	var st: int = f.stage
	var m := Sprites.mask(f.g.b, st)
	var fr: int = int(floor(f.anim)) % 4 if f.alive else 0
	var tex := Sprites.fish_tex(f.g, st, fr, "" if f.alive else "dead")
	draw_set_transform(Vector2(D.jr(f.x), D.jr(f.y)), 0.0, Vector2(-1 if f.face < 0 else 1, 1 if f.alive else -1))
	draw_texture(tex, Vector2(-D.jr(m.bx), -D.jr(m.by) - 1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
