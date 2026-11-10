class_name Hud
extends Control
## The interface over the tank. A port of the Aquarium v2 design component.

var g: Game
var snap := {}
var panel := ""
var narrow := false
var hint_until := 0.0
var reset_arm := false
var _reset_t := 0.0
var _taps: Array = []
var _clock := 0.0

var top_bar: PanelContainer
var stats_flow: HFlowContainer
var day_l: Label
var clock_l: Label
var phase_l: Label
var stat_rows: Array = []
var fish_l: Label
var alerts_box: HBoxContainer
var _alerts_sig := ""
var coins_l: Label
var income_l: Label
var water_btn: PxButton
var sound_btn: PxButton

var middle: Control
var toast_box: VBoxContainer
var card: PanelContainer
var cr := {}
var decor_card: PanelContainer
var dr := {}
var drawer: PanelContainer
var drawer_header: Control
var drawer_title: Label
var drawer_meta: Label
var drawer_scroll: ScrollContainer
var drawer_inner: MarginContainer
var drawer_body: VBoxContainer
var zoom_box: VBoxContainer
var _sig := ""
var _refs := {}
var _anim := {"drawer": 1.0, "card": 1.0, "decor": 1.0}

var bottom_bar: HFlowContainer
var tool_btns := {}
var panel_btns := {}
var hint_box: PanelContainer
var hint_l: Label

const TOOLS := [["look", "Look", "1", "Inspect fish"], ["feed", "Feed", "2", "Drop food"], ["clean", "Clean", "3", "Siphon waste, scrub algae"], ["arrange", "Arrange", "4", "Move decorations"]]
const PANELS := [["fish", "Fish"], ["shop", "Shop"], ["breed", "Breed"], ["book", "Book"], ["awards", "Awards"]]
const HINTS := {
	"look": "Tap a fish to check on it. Fish need food, clean water and some decor to stay happy.",
	"feed": "Tap the water to drop food. Leftovers sink, rot and foul the water.",
	"clean": "Drag over the gravel to siphon waste, or over the glass to scrub algae.",
	"arrange": "Tap a decoration, then drag it. Buy more in the shop.",
}
const PANEL_BG := Color(14 / 255.0, 21 / 255.0, 38 / 255.0, 0.94)
const BAR_BG := Color(11 / 255.0, 17 / 255.0, 32 / 255.0, 0.86)


func build(game: Game) -> void:
	g = game
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = UI.make_theme()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 15)
	add_child(margin)
	var col := UI.vbox(18)
	margin.add_child(col)
	_build_top(col)
	middle = Control.new()
	middle.size_flags_vertical = SIZE_EXPAND_FILL
	middle.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(middle)
	_build_middle()
	_build_bottom(col)
	hint_box = UI.px_panel(BAR_BG, UI.BORDER, 2, Vector4(14, 8, 14, 8))
	hint_box.mouse_filter = MOUSE_FILTER_IGNORE
	hint_l = UI.wrap_label("", UI.pix, 14, UI.HINT)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_box.add_child(hint_l)
	hint_box.visible = false
	add_child(hint_box)
	g.changed.connect(_on_changed)
	g.toast.connect(_on_toast)
	hint_until = _clock + 7.0


# ---------- build ----------

func _build_top(col: VBoxContainer) -> void:
	top_bar = UI.px_panel(BAR_BG, UI.BORDER, 3, Vector4(12, 8, 12, 8))
	col.add_child(top_bar)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 18)
	flow.add_theme_constant_override("v_separation", 10)
	flow.mouse_filter = MOUSE_FILTER_IGNORE
	top_bar.add_child(flow)
	var lg := UI.hbox(12)
	lg.size_flags_vertical = SIZE_SHRINK_CENTER
	var logo := UI.label("LITTLE REEF", UI.silk, 16, UI.LOGO)
	logo.mouse_filter = MOUSE_FILTER_STOP
	logo.gui_input.connect(_on_logo_input)
	lg.add_child(logo)
	var ck := UI.hbox(8)
	day_l = UI.label("DAY 1", UI.silk, 12)
	clock_l = UI.label("06:00", UI.silk, 12, UI.MUTED)
	phase_l = UI.label("Dawn", UI.silk, 12)
	for l in [day_l, clock_l, phase_l]:
		l.size_flags_vertical = SIZE_SHRINK_CENTER
		ck.add_child(l)
	ck.size_flags_vertical = SIZE_SHRINK_CENTER
	lg.add_child(ck)
	flow.add_child(lg)
	stats_flow = HFlowContainer.new()
	stats_flow.add_theme_constant_override("h_separation", 14)
	stats_flow.add_theme_constant_override("v_separation", 8)
	stats_flow.size_flags_horizontal = SIZE_EXPAND_FILL
	stats_flow.size_flags_vertical = SIZE_SHRINK_CENTER
	stats_flow.mouse_filter = MOUSE_FILTER_IGNORE
	flow.add_child(stats_flow)
	var tips := ["Water quality. Siphon waste and change water to raise it.", "Algae on the glass. Scrub it with Clean.", "Average fullness of your fish", "Average health of your fish", "Average happiness. Happy adults earn more."]
	for i in 5:
		var item := UI.vbox(4)
		item.custom_minimum_size.x = 64
		item.size_flags_horizontal = SIZE_EXPAND_FILL
		item.size_flags_vertical = SIZE_SHRINK_CENTER
		item.mouse_filter = MOUSE_FILTER_PASS
		item.tooltip_text = tips[i]
		var head := UI.hbox(6)
		head.add_child(UI.label(["WATER", "ALGAE", "FED", "HEALTH", "MOOD"][i], UI.silk, 10, UI.MUTED))
		head.add_child(UI.spacer())
		var val := UI.label("0", UI.silk, 10)
		head.add_child(val)
		item.add_child(head)
		var bar := UI.Bar.new(6, true)
		item.add_child(bar)
		stats_flow.add_child(item)
		stat_rows.append({"val": val, "bar": bar})
	var fg := UI.hbox(10)
	fg.size_flags_vertical = SIZE_SHRINK_CENTER
	fg.add_child(UI.label("FISH", UI.silk, 11, UI.MUTED))
	fish_l = UI.label("0/6", UI.silk, 11)
	fg.add_child(fish_l)
	alerts_box = UI.hbox(10)
	fg.add_child(alerts_box)
	stats_flow.add_child(fg)
	var rg := UI.hbox(10)
	rg.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_END
	rg.size_flags_vertical = SIZE_SHRINK_CENTER
	var coin := UI.hbox(8)
	coin.size_flags_vertical = SIZE_SHRINK_CENTER
	coin.add_child(UI.CoinIcon.new())
	coins_l = UI.label("0", UI.silk, 16, UI.GOLD_TEXT)
	coin.add_child(coins_l)
	income_l = UI.label("+0.0/M", UI.silk, 10, UI.MUTED)
	income_l.size_flags_vertical = SIZE_SHRINK_CENTER
	coin.add_child(income_l)
	rg.add_child(coin)
	water_btn = PxButton.new("+WATER 15", UI.silk, 11, UI.LOGO)
	water_btn.tooltip_text = "Change 1/3 of the water"
	water_btn.pressed.connect(func(): g.water_change())
	rg.add_child(water_btn)
	sound_btn = PxButton.new("SOUND ON", UI.silk, 11, UI.TEXT)
	sound_btn.pressed.connect(func(): g.set_sound(not g.synth.on))
	rg.add_child(sound_btn)
	flow.add_child(rg)


func _build_middle() -> void:
	card = UI.px_panel(PANEL_BG, UI.BORDER, 3, Vector4(14, 14, 14, 14))
	middle.add_child(card)
	var cv := UI.vbox(14)
	card.add_child(cv)
	var top := UI.hbox(14)
	cv.add_child(top)
	var sb := UI.sprite_box(Vector2(96, 76), Vector2(90, 70))
	top.add_child(sb[0])
	cr.tex = sb[1]
	var info := UI.vbox(7)
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(info)
	var nm := UI.hbox(10)
	cr.name = UI.label("", UI.pix_bold, 22)
	cr.status = UI.label("", UI.silk, 11)
	nm.add_child(cr.name)
	nm.add_child(cr.status)
	info.add_child(nm)
	cr.variety = UI.clip(UI.label("", UI.pix, 14, UI.SUB))
	info.add_child(cr.variety)
	cr.meta = UI.clip(UI.label("", UI.silk, 10, UI.MUTED))
	info.add_child(cr.meta)
	var grid := UI.hbox(10)
	cr.bars = []
	for t in ["FED", "HEALTH", "MOOD"]:
		var c := UI.vbox(4)
		c.size_flags_horizontal = SIZE_EXPAND_FILL
		var h := UI.hbox(4)
		h.add_child(UI.label(t, UI.silk, 10, UI.MUTED))
		h.add_child(UI.spacer())
		var v := UI.label("0", UI.silk, 10, UI.MUTED)
		h.add_child(v)
		c.add_child(h)
		var bar := UI.Bar.new(6)
		c.add_child(bar)
		grid.add_child(c)
		cr.bars.append({"val": v, "bar": bar})
	info.add_child(grid)
	var act := UI.hbox(8)
	cv.add_child(act)
	cr.sell = PxButton.new("SELL", UI.silk, 12, UI.GOLD_TEXT, UI.BTN, Vector2(0, 40), Vector2(12, 8))
	cr.sell.pressed.connect(_sel_do.bind("sell"))
	cr.pa = PxButton.new("PARENT A", UI.silk, 12, UI.TEXT, UI.BTN, Vector2(0, 40), Vector2(12, 8))
	cr.pa.pressed.connect(_sel_do.bind("pa"))
	cr.pb = PxButton.new("PARENT B", UI.silk, 12, UI.TEXT, UI.BTN, Vector2(0, 40), Vector2(12, 8))
	cr.pb.pressed.connect(_sel_do.bind("pb"))
	cr.scoop = PxButton.new("SCOOP OUT", UI.silk, 12, UI.BG, UI.BAD, Vector2(0, 40), Vector2(14, 8))
	cr.scoop.pressed.connect(_sel_do.bind("scoop"))
	var close := PxButton.new("CLOSE", UI.silk, 12, UI.MUTED, Color(0, 0, 0, 0), Vector2(0, 40), Vector2(6, 8))
	close.pressed.connect(func(): g.deselect())
	for b in [cr.sell, cr.pa, cr.pb, cr.scoop]:
		act.add_child(b)
	act.add_child(UI.spacer())
	act.add_child(close)
	card.visible = false

	decor_card = UI.px_panel(PANEL_BG, UI.BORDER, 3, Vector4(14, 12, 14, 12))
	middle.add_child(decor_card)
	var dv := UI.vbox(10)
	decor_card.add_child(dv)
	var dh := HFlowContainer.new()
	dh.add_theme_constant_override("h_separation", 12)
	dh.mouse_filter = MOUSE_FILTER_IGNORE
	dr.name = UI.label("", UI.pix_bold, 20)
	dh.add_child(dr.name)
	var dhint := UI.label("Drag to move · up or down to change depth", UI.pix, 14, UI.MUTED)
	dhint.size_flags_vertical = SIZE_SHRINK_END
	dh.add_child(dhint)
	dv.add_child(dh)
	var da := UI.hbox(8)
	var flip := PxButton.new("FLIP", UI.silk, 12, UI.TEXT, UI.BTN, Vector2(0, 40), Vector2(12, 8))
	flip.pressed.connect(_decor_do.bind("flip"))
	dr.store = PxButton.new("REMOVE", UI.silk, 12, UI.GOLD_TEXT, UI.BTN, Vector2(0, 40), Vector2(12, 8))
	dr.store.pressed.connect(_decor_do.bind("store"))
	var done := PxButton.new("DONE", UI.silk, 12, UI.MUTED, Color(0, 0, 0, 0), Vector2(0, 40), Vector2(6, 8))
	done.pressed.connect(func(): g.deselect())
	da.add_child(flip)
	da.add_child(dr.store)
	da.add_child(UI.spacer())
	da.add_child(done)
	dv.add_child(da)
	decor_card.visible = false

	drawer = UI.px_panel(Color(14 / 255.0, 21 / 255.0, 38 / 255.0, 0.95), UI.BORDER, 3, Vector4(0, 0, 0, 0))
	middle.add_child(drawer)
	var vv := UI.vbox(0)
	drawer.add_child(vv)
	var hm := MarginContainer.new()
	hm.mouse_filter = MOUSE_FILTER_IGNORE
	for side in [["left", 14], ["right", 14], ["top", 10], ["bottom", 10]]:
		hm.add_theme_constant_override("margin_" + side[0], side[1])
	drawer_header = hm
	var hh := UI.hbox(10)
	hm.add_child(hh)
	drawer_title = UI.label("", UI.silk, 14, UI.LOGO)
	drawer_title.size_flags_vertical = SIZE_SHRINK_CENTER
	drawer_meta = UI.label("", UI.silk, 12, UI.MUTED)
	drawer_meta.size_flags_vertical = SIZE_SHRINK_CENTER
	var dclose := PxButton.new("CLOSE", UI.silk, 12, UI.MUTED, Color(0, 0, 0, 0), Vector2(0, 36), Vector2(4, 6))
	dclose.pressed.connect(func(): _set_panel(""))
	hh.add_child(drawer_title)
	hh.add_child(UI.spacer())
	hh.add_child(drawer_meta)
	hh.add_child(UI.spacer())
	hh.add_child(dclose)
	vv.add_child(hm)
	var line := ColorRect.new()
	line.color = UI.BORDER
	line.custom_minimum_size.y = 3
	line.mouse_filter = MOUSE_FILTER_IGNORE
	vv.add_child(line)
	drawer_scroll = ScrollContainer.new()
	drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	drawer_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	vv.add_child(drawer_scroll)
	drawer_inner = MarginContainer.new()
	drawer_inner.size_flags_horizontal = SIZE_EXPAND_FILL
	drawer_inner.mouse_filter = MOUSE_FILTER_PASS
	for side in ["left", "top", "right", "bottom"]:
		drawer_inner.add_theme_constant_override("margin_" + side, 14)
	drawer_scroll.add_child(drawer_inner)
	drawer_body = UI.vbox(12)
	drawer_body.mouse_filter = MOUSE_FILTER_PASS
	drawer_inner.add_child(drawer_body)
	drawer.visible = false

	zoom_box = UI.vbox(6)
	var zin := PxButton.new("+", UI.silk, 16, UI.TEXT, Color(BAR_BG, 0.9), Vector2(40, 40), Vector2(0, 0))
	zin.tooltip_text = "Zoom in"
	zin.pressed.connect(func(): g.zoom_step(1))
	var zout := PxButton.new("-", UI.silk, 16, UI.TEXT, Color(BAR_BG, 0.9), Vector2(40, 40), Vector2(0, 0))
	zout.tooltip_text = "Zoom out"
	zout.pressed.connect(func(): g.zoom_step(-1))
	zoom_box.add_child(zin)
	zoom_box.add_child(zout)
	middle.add_child(zoom_box)

	toast_box = UI.vbox(8)
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_box.z_index = 3
	middle.add_child(toast_box)


func _build_bottom(col: VBoxContainer) -> void:
	bottom_bar = HFlowContainer.new()
	bottom_bar.alignment = FlowContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("h_separation", 20)
	bottom_bar.add_theme_constant_override("v_separation", 16)
	bottom_bar.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(bottom_bar)
	var tp := UI.px_panel(BAR_BG, UI.BORDER, 3, Vector4(6, 6, 6, 6))
	var th := UI.hbox(6)
	tp.add_child(th)
	for t in TOOLS:
		var b := PxButton.new("", null, 12, UI.TEXT, UI.BTN, Vector2(64, 44), Vector2(10, 6))
		b.tooltip_text = t[3]
		var c := UI.hbox(6)
		c.size_flags_horizontal = SIZE_SHRINK_CENTER
		c.size_flags_vertical = SIZE_SHRINK_CENTER
		var l := UI.label(t[1], UI.silk, 13)
		var n := UI.label(t[2], UI.silk, 10, UI.MUTED)
		l.size_flags_vertical = SIZE_SHRINK_CENTER
		n.size_flags_vertical = SIZE_SHRINK_CENTER
		c.add_child(l)
		c.add_child(n)
		b.add_child(c)
		var key: String = t[0]
		b.pressed.connect(func(): _pick_tool(key))
		th.add_child(b)
		tool_btns[key] = {"btn": b, "label": l, "num": n}
	bottom_bar.add_child(tp)
	var pp := UI.px_panel(BAR_BG, UI.BORDER, 3, Vector4(6, 6, 6, 6))
	var ph := UI.hbox(6)
	pp.add_child(ph)
	for p in PANELS:
		var b := PxButton.new(p[1], UI.silk, 12, UI.TEXT, UI.BTN, Vector2(58, 44), Vector2(8, 6))
		var key: String = p[0]
		b.pressed.connect(func(): _set_panel("" if panel == key else key))
		ph.add_child(b)
		panel_btns[key] = b
	bottom_bar.add_child(pp)


# ---------- events ----------

func _sel_do(what: String) -> void:
	var sel = snap.get("sel")
	if sel == null:
		return
	match what:
		"sell":
			g.sell_fish(sel.id)
		"pa":
			g.set_parent(0, sel.id)
		"pb":
			g.set_parent(1, sel.id)
		"scoop":
			g.scoop(sel.id)


func _decor_do(what: String) -> void:
	var sd = snap.get("selDecor")
	if sd == null:
		return
	if what == "flip":
		g.flip_decor(sd.id)
	else:
		g.store_decor(sd.id)


func _pick_tool(k: String) -> void:
	g.set_tool(k)
	hint_until = _clock + 4.5


func _set_panel(k: String) -> void:
	if k != panel and k != "":
		_anim.drawer = 0.0
	panel = k
	_refresh()


func _on_logo_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var now := _clock
		_taps = _taps.filter(func(t): return now - t < 4.0)
		_taps.append(now)
		if _taps.size() >= 10:
			_taps.clear()
			g.cheat(10000)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	match e.keycode:
		KEY_1:
			_pick_tool("look")
		KEY_2:
			_pick_tool("feed")
		KEY_3:
			_pick_tool("clean")
		KEY_4:
			_pick_tool("arrange")
		KEY_ESCAPE:
			_set_panel("")
			g.deselect()
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			g.zoom_step(1)
		KEY_MINUS, KEY_KP_SUBTRACT:
			g.zoom_step(-1)
		KEY_LEFT, KEY_A:
			g.pan(Vector2(60, 0))
		KEY_RIGHT, KEY_D:
			g.pan(Vector2(-60, 0))
		KEY_UP, KEY_W:
			g.pan(Vector2(0, 60))
		KEY_DOWN, KEY_S:
			g.pan(Vector2(0, -60))
		_:
			return
	get_viewport().set_input_as_handled()


func _on_changed() -> void:
	var s := g.snapshot()
	var prev := snap
	snap = s
	var ps = prev.get("sel")
	var pd = prev.get("selDecor")
	var new_sel: bool = (s.sel != null and (ps == null or ps.id != s.sel.id)) or (s.selDecor != null and (pd == null or pd.id != s.selDecor.id))
	if new_sel:
		_anim.card = 0.0
		_anim.decor = 0.0
		if narrow:
			panel = ""
	_refresh()


func _on_toast(text: String, kind: String) -> void:
	var colors := {"good": UI.GOOD, "bad": UI.BAD, "ach": UI.GOLD, "new": UI.AQUA, "info": UI.INFO, "keeper": UI.KEEPER}
	var box := UI.px_panel(Color(15 / 255.0, 23 / 255.0, 41 / 255.0, 0.96), colors.get(kind, UI.INFO), 3, Vector4(16, 9, 16, 9))
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = SIZE_SHRINK_CENTER
	var h := UI.hbox(10)
	box.add_child(h)
	var face_w := 0.0
	if kind == "keeper":
		var t := TextureRect.new()
		t.texture = Sprites.face_tex("smile")
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = TEXTURE_FILTER_NEAREST
		t.custom_minimum_size = Vector2(30, 38)
		t.mouse_filter = MOUSE_FILTER_IGNORE
		h.add_child(t)
		face_w = 34.0
	var l := UI.wrap_label(text, UI.pix, 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = SIZE_SHRINK_CENTER
	var tw := UI.pix.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 2.0
	l.custom_minimum_size.x = minf(tw, minf(520.0 - 32.0 - face_w, maxf(120.0, middle.size.x - 16.0 - 32.0 - face_w)))
	h.add_child(l)
	toast_box.add_child(box)
	while toast_box.get_child_count() > 3:
		var old := toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	box.modulate.a = 0.0
	var tw2 := box.create_tween()
	for i in 3:
		tw2.tween_property(box, "modulate:a", (i + 1) / 3.0, 0.0).set_delay(0.066)
	get_tree().create_timer(3.8).timeout.connect(box.queue_free)


# ---------- refresh ----------

func _refresh() -> void:
	if snap.is_empty():
		return
	var s := snap
	var has: bool = s.alive > 0
	day_l.text = "DAY %d" % s.day
	clock_l.text = s.clock
	phase_l.text = s.phase
	phase_l.add_theme_color_override("font_color", UI.PHASES.get(s.phase, UI.TEXT))
	var vals := [
		[str(s.water) + "%", s.water, _bar_c(s.water), UI.BAD if s.water < 30 else UI.TEXT],
		[str(s.algae) + "%", s.algae, UI.ALGAE, UI.WARN if s.algae > 50 else UI.TEXT],
		[str(s.fed) if has else "–", s.fed, _bar_c(s.fed), UI.WARN if has and s.fed < 30 else UI.TEXT],
		[str(s.health) if has else "–", s.health, _bar_c(s.health), UI.BAD if has and s.health < 35 else UI.TEXT],
		[str(s.mood) if has else "–", s.mood, _bar_c(s.mood), UI.TEXT],
	]
	for i in 5:
		var r: Dictionary = stat_rows[i]
		r.val.text = vals[i][0]
		r.val.add_theme_color_override("font_color", vals[i][3])
		r.bar.set_value(vals[i][1] / 100.0, vals[i][2])
	fish_l.text = "%d/%d" % [s.alive, s.cap]
	fish_l.add_theme_color_override("font_color", UI.WARN if s.alive >= s.cap else UI.TEXT)
	var alerts := []
	if s.hungry > 0:
		alerts.append(["%d HUNGRY" % s.hungry, UI.WARN])
	if s.sick > 0:
		alerts.append(["%d SICK" % s.sick, UI.BAD])
	if s.dead > 0:
		alerts.append(["%d DEAD" % s.dead, Color("#aab3c4")])
	var asig := str(alerts)
	if asig != _alerts_sig:
		_alerts_sig = asig
		for c in alerts_box.get_children():
			c.queue_free()
		for a in alerts:
			alerts_box.add_child(UI.label(a[0], UI.silk, 11, a[1]))
	coins_l.text = str(s.coins)
	income_l.text = "+%s/M" % s.income
	water_btn.set_text("WAIT %dS" % s.wcIn if s.wcIn > 0 else "+WATER 15")
	water_btn.set_dim(0.5 if s.wcIn > 0 or s.coins < 15 else 1.0)
	sound_btn.set_text("SOUND ON" if s.sound else "SOUND OFF")
	for k in tool_btns:
		var on: bool = s.tool == k
		var t: Dictionary = tool_btns[k]
		t.btn.set_colors(UI.AQUA if on else UI.BTN, UI.TEXT)
		t.label.add_theme_color_override("font_color", UI.BG if on else UI.TEXT)
		t.num.add_theme_color_override("font_color", UI.BG if on else UI.MUTED)
	var can_breed: bool = s.breedMsg == ""
	var dots := {"fish": [s.hungry + s.sick + s.dead > 0, UI.BAD if s.dead > 0 or s.sick > 0 else UI.WARN], "shop": [false, UI.GOLD],
		"breed": [can_breed, UI.PINK], "book": [false, UI.AQUA], "awards": [false, UI.GOLD]}
	for k in panel_btns:
		var b: PxButton = panel_btns[k]
		var open: bool = panel == k
		b.set_colors(UI.BTN2 if open else UI.BTN, UI.AQUA if open else UI.TEXT)
		b.set_dot(dots[k][0] and not open, dots[k][1])
	_refresh_card()
	_refresh_drawer()


func _bar_c(v: float) -> Color:
	return UI.GOOD if v > 60 else (UI.WARN if v > 30 else UI.BAD)


func _refresh_card() -> void:
	var s := snap
	var blocked := narrow and panel != ""
	var sel = s.sel
	card.visible = sel != null and not blocked
	if sel != null:
		cr.tex.texture = sel.tex
		cr.name.text = sel.name
		cr.status.text = sel.status
		cr.status.add_theme_color_override("font_color", UI.TONES.get(sel.tone, UI.MUTED))
		cr.variety.text = "%s · %s fins" % [sel.variety, sel.fins]
		cr.meta.text = "%s    %s DAYS    +%s/MIN" % [sel.stage, sel.age, sel.income]
		var vals := [sel.hunger, sel.health, sel.happy]
		for i in 3:
			cr.bars[i].val.text = str(vals[i])
			cr.bars[i].bar.set_value(vals[i] / 100.0, _bar_c(vals[i]))
		cr.sell.visible = sel.alive
		cr.sell.set_text("SELL %d" % sel.value)
		cr.pa.visible = sel.adult
		cr.pb.visible = sel.adult
		cr.pa.set_colors(UI.PINK if sel.isA else UI.BTN, UI.BG if sel.isA else UI.TEXT)
		cr.pb.set_colors(UI.PINK if sel.isB else UI.BTN, UI.BG if sel.isB else UI.TEXT)
		cr.scoop.visible = not sel.alive
	var sd = s.selDecor
	decor_card.visible = sd != null and not blocked
	if sd != null:
		dr.name.text = sd.name
		dr.store.set_text("REMOVE +%d" % sd.refund)


func _refresh_drawer() -> void:
	if panel == "":
		drawer.visible = false
		_sig = ""
		return
	drawer.visible = true
	var s := snap
	var titles := {"fish": ["YOUR FISH", "%d/%d" % [s.alive, s.cap]], "shop": ["SHOP", "%d COINS" % s.coins], "breed": ["BREED", ""],
		"book": ["FISH BOOK", "%d/%d" % [s.bookFound, s.bookTotal]], "awards": ["ACHIEVEMENTS", "%d/%d" % [s.achDone, s.achTotal]]}
	drawer_title.text = titles[panel][0]
	drawer_meta.text = titles[panel][1]
	var sig := panel + ":" + _panel_sig()
	if sig != _sig:
		var keep_scroll := sig.get_slice(":", 0) == _sig.get_slice(":", 0)
		var sc := drawer_scroll.scroll_vertical
		_sig = sig
		_refs = {}
		for c in drawer_body.get_children():
			drawer_body.remove_child(c)
			c.queue_free()
		match panel:
			"fish":
				_build_fish()
			"shop":
				_build_shop()
			"breed":
				_build_breed()
			"book":
				_build_book()
			"awards":
				_build_awards()
		if keep_scroll:
			drawer_scroll.set_deferred("scroll_vertical", sc)
		else:
			drawer_scroll.scroll_vertical = 0
	match panel:
		"fish":
			_update_fish()
		"shop":
			_update_shop()
		"breed":
			_update_breed()
		"awards":
			_update_awards()


func _panel_sig() -> String:
	var s := snap
	match panel:
		"fish":
			var parts := []
			for f in s.fish:
				parts.append("%d.%d.%s" % [f.id, f.stage_i, f.alive])
			return ",".join(parts) + "|" + str(s.eggs.size())
		"breed":
			var parts := []
			for f in s.fish:
				if f.adult:
					parts.append(str(f.id))
			return ",".join(parts) + "|" + str(s.parentA.id if s.parentA else -1) + "|" + str(s.parentB.id if s.parentB else -1)
		"book":
			return str(s.bookFound)
		"awards":
			return str(s.achDone)
	return ""


func _section(text: String) -> Label:
	var l := UI.label(text, UI.silk, 11, UI.MUTED)
	drawer_body.add_child(l)
	return l


func _fish_row(f: Dictionary) -> Dictionary:
	var row := PxButton.new("", null, 12, UI.TEXT, UI.BTN, Vector2(0, 0), Vector2(8, 8))
	row.mouse_filter = MOUSE_FILTER_PASS
	var h := UI.hbox(12)
	row.add_child(h)
	var sb := UI.sprite_box(Vector2(60, 46), Vector2(56, 42), f.tex)
	h.add_child(sb[0])
	var mid := UI.vbox(2)
	mid.size_flags_horizontal = SIZE_EXPAND_FILL
	mid.size_flags_vertical = SIZE_SHRINK_CENTER
	var name_l := UI.clip(UI.label(f.name, UI.pix_bold, 16))
	var sub_l := UI.clip(UI.label("", UI.pix, 13, UI.MUTED))
	mid.add_child(name_l)
	mid.add_child(sub_l)
	h.add_child(mid)
	return {"row": row, "h": h, "tex": sb[1], "name": name_l, "sub": sub_l}


func _build_fish() -> void:
	var list := UI.vbox(8)
	list.mouse_filter = MOUSE_FILTER_PASS
	drawer_body.add_child(list)
	for f in snap.fish:
		var r := _fish_row(f)
		var right := UI.vbox(5)
		right.custom_minimum_size.x = 64
		right.size_flags_vertical = SIZE_SHRINK_CENTER
		r.status = UI.label("", UI.silk, 10)
		r.status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(r.status)
		r.hbar = UI.Bar.new(4)
		r.lbar = UI.Bar.new(4)
		right.add_child(r.hbar)
		right.add_child(r.lbar)
		r.h.add_child(right)
		var id: int = f.id
		r.row.pressed.connect(func():
			g.select(id)
			if narrow:
				_set_panel(""))
		list.add_child(r.row)
		_refs[id] = r
	if snap.fish.is_empty():
		drawer_body.add_child(UI.wrap_label("The tank is empty. Visit the shop to bring some fish home.", UI.pix, 16, UI.MUTED))
	var eggs := UI.vbox(6)
	drawer_body.add_child(eggs)
	_refs["eggs"] = eggs
	for e in snap.eggs:
		eggs.add_child(UI.label("", UI.silk, 12, Color("#fff1c4")))


func _update_fish() -> void:
	for f in snap.fish:
		var r = _refs.get(f.id)
		if r == null:
			continue
		r.tex.texture = f.tex
		r.name.text = f.name
		r.sub.text = "%s · %s" % [f.stage, f.variety]
		r.status.text = f.status
		r.status.add_theme_color_override("font_color", UI.TONES.get(f.tone, UI.MUTED))
		r.hbar.set_value(f.hunger / 100.0, _bar_c(f.hunger))
		r.lbar.set_value(f.health / 100.0, _bar_c(f.health))
		r.row.set_colors(UI.BTN2 if f.selected else UI.BTN, UI.TEXT)
	var eggs: VBoxContainer = _refs.get("eggs")
	if eggs:
		for i in mini(eggs.get_child_count(), snap.eggs.size()):
			var e: Dictionary = snap.eggs[i]
			eggs.get_child(i).text = "EGGS · %d FRY · %dS" % [e.n, e.t]


func _shop_card(tex: Texture2D, box_h: int, img_h: int) -> Array:
	var c := UI.panel(UI.BTN, Vector4(10, 10, 10, 10))
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	var v := UI.vbox(8)
	c.add_child(v)
	var sb := UI.sprite_box(Vector2(0, box_h), Vector2(0, img_h), tex)
	v.add_child(sb[0])
	return [c, v]


func _build_shop() -> void:
	_section("FISH · RANDOM COLOR AND PATTERN")
	var fg := UI.AutoGrid.new(130, 10)
	drawer_body.add_child(fg)
	_refs.fish = {}
	for it in snap.shopFish:
		var cv := _shop_card(it.tex, 52, 46)
		var row := UI.hbox(6)
		row.add_child(UI.clip(UI.label(it.name, UI.pix_bold, 16)))
		var inc := UI.label("+%d/M" % int(it.income), UI.silk, 10, UI.MUTED)
		inc.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(inc)
		cv[1].add_child(row)
		var key: String = it.key
		var b := PxButton.new("BUY %d" % it.price, UI.silk, 12, UI.GOLD_TEXT, UI.BTN2, Vector2(0, 36), Vector2(6, 6))
		b.pressed.connect(func(): g.buy_fish(key))
		cv[1].add_child(b)
		fg.add_child(cv[0])
		_refs.fish[key] = b
	_refs.decor_l = _section("DECOR · 0/16")
	_refs.decor_l.custom_minimum_size.y = 18
	var dg := UI.AutoGrid.new(130, 10)
	drawer_body.add_child(dg)
	_refs.decor = {}
	for it in snap.shopDecor:
		var cv := _shop_card(it.tex, 56, 52)
		cv[1].add_theme_constant_override("separation", 6)
		cv[1].add_child(UI.clip(UI.label(it.name, UI.pix_bold, 16)))
		cv[1].add_child(UI.wrap_label(it.desc, UI.pix, 13, UI.MUTED))
		var key: String = it.key
		var b := PxButton.new("BUY %d" % it.price, UI.silk, 12, UI.GOLD_TEXT, UI.BTN2, Vector2(0, 36), Vector2(6, 6))
		b.pressed.connect(func():
			g.buy_decor(key)
			if narrow:
				_set_panel(""))
		cv[1].add_child(b)
		dg.add_child(cv[0])
		_refs.decor[key] = b
	_section("UPGRADES")
	var ul := UI.vbox(8)
	drawer_body.add_child(ul)
	_refs.upg = {}
	for u in snap.upgrades:
		var row := UI.panel(UI.BTN, Vector4(12, 10, 12, 10))
		var h := UI.hbox(12)
		row.add_child(h)
		var v := UI.vbox(2)
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		var top := UI.hbox(10)
		top.add_child(UI.label(u.name, UI.pix_bold, 16))
		var lv := UI.label("", UI.silk, 10, UI.MUTED)
		lv.size_flags_vertical = SIZE_SHRINK_CENTER
		top.add_child(lv)
		v.add_child(top)
		var desc := UI.wrap_label("", UI.pix, 13, UI.MUTED)
		v.add_child(desc)
		h.add_child(v)
		var key: String = u.key
		var b := PxButton.new("BUY", UI.silk, 12, UI.GOLD_TEXT, UI.BTN2, Vector2(84, 36), Vector2(10, 6))
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		b.pressed.connect(func(): g.buy_upgrade(key))
		h.add_child(b)
		ul.add_child(row)
		_refs.upg[key] = {"lv": lv, "desc": desc, "btn": b}


func _update_shop() -> void:
	for it in snap.shopFish:
		_refs.fish[it.key].set_dim(1.0 if it.can else 0.45)
	_refs.decor_l.text = "DECOR · %d/%d" % [snap.decorCount, snap.decorMax]
	for it in snap.shopDecor:
		_refs.decor[it.key].set_dim(1.0 if it.can else 0.45)
	for u in snap.upgrades:
		var r: Dictionary = _refs.upg[u.key]
		r.lv.text = "LV %d/%d" % [u.level, u.max]
		r.desc.text = u.desc
		r.btn.set_text("MAX" if u.maxed else "BUY %d" % u.price)
		r.btn.set_dim(1.0 if u.can else 0.45)


func _slot(title: String, p) -> PanelContainer:
	var c := UI.panel(UI.BG, Vector4(10, 10, 10, 10))
	c.custom_minimum_size.y = 104
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var t := UI.label(title, UI.silk, 10, UI.MUTED)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	if p != null:
		var sb := UI.sprite_box(Vector2(0, 52), Vector2(0, 52), p.tex)
		sb[0].add_theme_stylebox_override("panel", UI.flat(Color(0, 0, 0, 0)))
		v.add_child(sb[0])
		var n := UI.clip(UI.label(p.name, UI.pix_bold, 16))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
	else:
		var n := UI.label("Pick below", UI.pix, 13, UI.DIM)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
	return c


func _build_breed() -> void:
	var top := UI.hbox(10)
	top.add_child(_slot("PARENT A", snap.parentA))
	var plus := UI.label("+", UI.silk, 18, Color("#ff6f8a"))
	plus.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(plus)
	top.add_child(_slot("PARENT B", snap.parentB))
	drawer_body.add_child(top)
	var b := PxButton.new("BREED", UI.silk, 14, UI.BG, UI.PINK, Vector2(0, 46), Vector2(10, 6))
	b.pressed.connect(func(): g.breed())
	drawer_body.add_child(b)
	_refs.btn = b
	var note := UI.wrap_label("", UI.pix, 14, UI.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drawer_body.add_child(note)
	_refs.note = note
	_section("ADULTS")
	var list := UI.vbox(8)
	list.mouse_filter = MOUSE_FILTER_PASS
	drawer_body.add_child(list)
	_refs.adults = {}
	var any := false
	for f in snap.fish:
		if not f.adult:
			continue
		any = true
		var r := _fish_row(f)
		r.row.mouse_default_cursor_shape = CURSOR_ARROW
		r.sub.text = f.variety
		var id: int = f.id
		var ba := PxButton.new("A", UI.silk, 13, UI.TEXT, UI.BTN2, Vector2(40, 40), Vector2(0, 0))
		ba.mouse_filter = MOUSE_FILTER_PASS
		ba.pressed.connect(func(): g.set_parent(0, id))
		var bb := PxButton.new("B", UI.silk, 13, UI.TEXT, UI.BTN2, Vector2(40, 40), Vector2(0, 0))
		bb.mouse_filter = MOUSE_FILTER_PASS
		bb.pressed.connect(func(): g.set_parent(1, id))
		ba.size_flags_vertical = SIZE_SHRINK_CENTER
		bb.size_flags_vertical = SIZE_SHRINK_CENTER
		r.h.add_child(ba)
		r.h.add_child(bb)
		list.add_child(r.row)
		_refs.adults[id] = {"a": ba, "b": bb}
	if not any:
		drawer_body.add_child(UI.wrap_label("No adults yet. Juveniles grow up in about a day if they stay fed.", UI.pix, 16, UI.MUTED))


func _update_breed() -> void:
	var ok: bool = snap.breedMsg == ""
	_refs.btn.set_colors(UI.PINK if ok else UI.BTN, UI.BG if ok else UI.DIM)
	_refs.note.text = "Ready. Happier parents lay more eggs." if ok else snap.breedMsg
	for f in snap.fish:
		var r = _refs.adults.get(f.id)
		if r == null:
			continue
		r.a.set_colors(UI.PINK if f.isA else UI.BTN2, UI.BG if f.isA else UI.TEXT)
		r.b.set_colors(UI.PINK if f.isB else UI.BTN2, UI.BG if f.isB else UI.TEXT)


func _build_book() -> void:
	drawer_body.add_child(UI.wrap_label("Breed fish to discover new colors. Pearl, Ink and Gilt only appear by chance. Puff and Lantern can only be bred.", UI.pix, 14, UI.MUTED))
	for row in g.book_rows():
		var v := UI.vbox(6)
		v.add_child(UI.label(row.name, UI.pix_bold, 16))
		var grid := UI.AutoGrid.new(52, 6)
		for c in row.cells:
			var cell := PanelContainer.new()
			var st := UI.flat(UI.BG)
			st.border_width_bottom = 3
			st.border_color = UI.GOLD if c.rare else (UI.BORDER if c.found else UI.BG)
			cell.add_theme_stylebox_override("panel", st)
			cell.custom_minimum_size.y = 44
			cell.size_flags_horizontal = SIZE_EXPAND_FILL
			cell.tooltip_text = c.label
			cell.mouse_filter = MOUSE_FILTER_PASS
			var t := TextureRect.new()
			t.texture = c.tex
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			t.texture_filter = TEXTURE_FILTER_NEAREST
			t.custom_minimum_size = Vector2(46, 36)
			t.size_flags_horizontal = SIZE_SHRINK_CENTER
			t.size_flags_vertical = SIZE_SHRINK_CENTER
			t.mouse_filter = MOUSE_FILTER_IGNORE
			cell.add_child(t)
			grid.add_child(cell)
		v.add_child(grid)
		drawer_body.add_child(v)


func _build_awards() -> void:
	var list := UI.vbox(8)
	drawer_body.add_child(list)
	for a in g.ach_rows():
		var row := UI.panel(UI.BTN, Vector4(12, 10, 12, 10))
		row.modulate.a = 1.0 if a.done else 0.6
		var h := UI.hbox(12)
		row.add_child(h)
		h.add_child(UI.AchBox.new(a.done))
		var v := UI.vbox(2)
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		v.add_child(UI.label(a.name, UI.pix_bold, 16))
		v.add_child(UI.wrap_label(a.desc, UI.pix, 13, UI.MUTED))
		h.add_child(v)
		var r := UI.label("+%d" % a.reward, UI.silk, 12, UI.GOLD_TEXT)
		r.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(r)
		list.add_child(row)
	var line := ColorRect.new()
	line.color = UI.BORDER
	line.custom_minimum_size.y = 2
	drawer_body.add_child(line)
	var foot := UI.hbox(10)
	_refs.total = UI.wrap_label("", UI.pix, 13, UI.MUTED)
	_refs.total.size_flags_horizontal = SIZE_EXPAND_FILL
	_refs.total.size_flags_vertical = SIZE_SHRINK_CENTER
	foot.add_child(_refs.total)
	var rb := PxButton.new("RESET TANK", UI.silk, 11, UI.DIM, Color(0, 0, 0, 0), Vector2(0, 32), Vector2(4, 6))
	rb.pressed.connect(_on_reset)
	foot.add_child(rb)
	_refs.reset = rb
	drawer_body.add_child(foot)


func _update_awards() -> void:
	_refs.total.text = "Earned %d coins in total" % snap.total
	_refs.reset.set_text("TAP AGAIN TO RESET" if reset_arm else "RESET TANK")
	_refs.reset.set_colors(Color(0, 0, 0, 0), UI.BAD if reset_arm else UI.DIM)


func _on_reset() -> void:
	if not reset_arm:
		reset_arm = true
		_reset_t = _clock + 3.0
		_refresh()
		return
	reset_arm = false
	g.reset()


# ---------- layout ----------

func _process(dt: float) -> void:
	_clock += dt
	if reset_arm and _clock > _reset_t:
		reset_arm = false
		_refresh()
	var was := narrow
	narrow = size.x < 760.0
	if was != narrow:
		_refresh()
	stats_flow.custom_minimum_size.x = minf(320.0, maxf(0.0, top_bar.size.x - 24.0))
	var top_inset := top_bar.global_position.y + top_bar.size.y + 3.0
	var bottom_inset := size.y - bottom_bar.global_position.y + 3.0
	g.set_view(size, top_inset, bottom_inset)
	for k in _anim:
		_anim[k] = minf(1.0, _anim[k] + dt)
	_layout_hint()
	_layout_middle()


## Pixel-stepped slide-in offset, like the steps(3) CSS animation.
func _slide(k: String, dur: float) -> float:
	var t: float = _anim[k] / dur
	return 0.0 if t >= 1.0 else 10.0 * (1.0 - floorf(t * 3.0) / 3.0)


func _layout_middle() -> void:
	var mw := middle.size.x
	var mh := middle.size.y
	var dw := 0.0
	if drawer.visible:
		dw = minf(400.0, mw)
		var content: float = drawer_header.get_combined_minimum_size().y + 3.0 + drawer_inner.get_combined_minimum_size().y
		var dh := minf(content, mh)
		drawer.size = Vector2(dw, dh)
		drawer.position = Vector2(mw - dw, mh - dh + _slide("drawer", 0.18))
		drawer.modulate.a = minf(1.0, _anim.drawer / 0.18 * 1.5)
	var room := mw - (dw + 16.0 if dw > 0.0 else 0.0)
	if card.visible:
		var cw := clampf(room, minf(280.0, mw), minf(480.0, mw))
		card.size = Vector2(cw, 0)
		var ch := card.get_combined_minimum_size().y
		card.size = Vector2(cw, ch)
		card.position = Vector2(0, mh - ch + _slide("card", 0.18))
	if decor_card.visible:
		var cw := clampf(room, minf(280.0, mw), minf(440.0, mw))
		decor_card.size = Vector2(cw, 0)
		var ch := decor_card.get_combined_minimum_size().y
		decor_card.size = Vector2(cw, ch)
		decor_card.position = Vector2(0, mh - ch + _slide("decor", 0.18))
	zoom_box.visible = not drawer.visible
	var zs := zoom_box.get_combined_minimum_size()
	zoom_box.size = zs
	var zy := mh - zs.y
	if (card.visible or decor_card.visible) and mw < 560.0:
		zy = minf(zy, (card.position.y if card.visible else decor_card.position.y) - zs.y - 12.0)
	if hint_box.visible:
		zy = minf(zy, hint_box.position.y - middle.global_position.y - zs.y - 10.0)
	zoom_box.position = Vector2(mw - zs.x, maxf(0.0, zy))
	toast_box.size = Vector2(mw, 0)
	toast_box.position = Vector2(0, 0)


func _layout_hint() -> void:
	var s := snap
	var show := not s.is_empty() and _clock < hint_until and s.sel == null and s.selDecor == null and panel == ""
	hint_box.visible = show
	if not show:
		return
	var text: String = HINTS.get(s.tool, "")
	if hint_l.text != text:
		hint_l.text = text
	var tw := UI.pix.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 2.0
	var w := minf(tw, minf(560.0, size.x * 0.92) - 28.0)
	hint_l.custom_minimum_size.x = w
	hint_box.size = Vector2(w + 28.0, 0)
	var hs := hint_box.get_combined_minimum_size()
	hint_box.size = hs
	hint_box.position = Vector2((size.x - hs.x) * 0.5, bottom_bar.global_position.y - 3.0 - 12.0 - hs.y)
