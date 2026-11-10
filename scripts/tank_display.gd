class_name TankDisplay
extends Control
## Shows the camera's part of the tank and turns mouse and touch input into tool actions,
## pans and zooms.

var g: Game
var vp: SubViewport

var _touches := {}
var _gesture := false
var _g_dist := 1.0
var _g_scale := 1.0
var _g_world := Vector2.ZERO
var _pressing := false
var _panning := false
var _pan_button := false
var _press_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _touch_mode := false

const PAN_SLOP := 7.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	texture_filter = TEXTURE_FILTER_NEAREST
	mouse_exited.connect(_on_exit)


func _on_exit() -> void:
	if g:
		g.leave()


func _process(_dt: float) -> void:
	queue_redraw()
	var shape := CURSOR_POINTING_HAND
	match g.tool if g else "look":
		"feed":
			shape = CURSOR_CROSS
		"clean":
			shape = CURSOR_HELP
		"arrange":
			shape = CURSOR_DRAG
	if _panning or _pan_button:
		shape = CURSOR_MOVE
	mouse_default_cursor_shape = shape


func _draw() -> void:
	if g == null or vp == null or g.S.is_empty():
		return
	var s := g.cam_scale
	draw_texture_rect_region(vp.get_texture(), Rect2(Vector2.ZERO, size), Rect2(g.cam_snapped(), size / s))
	_draw_pan_hint()


## A thin track shows which part of a large tank is in view, for a moment after the camera moves.
func _draw_pan_hint() -> void:
	if not g.can_pan():
		return
	var age := g.T - g.cam_moved_t
	if age > 1.6:
		return
	var a := clampf((1.6 - age) / 0.4, 0.0, 1.0)
	var v := size / g.cam_scale
	var track_w := minf(160.0, size.x * 0.4)
	var tx := (size.x - track_w) * 0.5
	var ty := size.y - g.inset_bottom - 12.0
	draw_rect(Rect2(tx, ty, track_w, 4), Color(0.043, 0.067, 0.125, 0.7 * a))
	var thumb_w := maxf(8.0, track_w * minf(1.0, v.x / g.W))
	var thumb_x := tx + (track_w - thumb_w) * (g.cam.x / maxf(1.0, g.W - v.x))
	draw_rect(Rect2(thumb_x, ty, thumb_w, 4), Color(0.345, 0.898, 0.929, 0.9 * a))
	if v.y < g.H - 0.5:
		var track_h := minf(120.0, (size.y - g.inset_top - g.inset_bottom) * 0.4)
		var sx := size.x - 10.0
		var sy := g.inset_top + (size.y - g.inset_top - g.inset_bottom - track_h) * 0.5
		draw_rect(Rect2(sx, sy, 4, track_h), Color(0.043, 0.067, 0.125, 0.7 * a))
		var th := maxf(8.0, track_h * minf(1.0, v.y / g.H))
		var tyy := sy + (track_h - th) * (g.cam.y / maxf(1.0, g.H - v.y))
		draw_rect(Rect2(sx, tyy, 4, th), Color(0.345, 0.898, 0.929, 0.9 * a))


# ---------- input ----------

func _gui_input(e: InputEvent) -> void:
	if g == null or g.S.is_empty():
		return
	if e is InputEventScreenTouch:
		_touch_mode = true
		_on_touch(e)
		accept_event()
		return
	if e is InputEventScreenDrag:
		_on_touch_drag(e)
		accept_event()
		return
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if e is InputEventMouseButton:
		_touch_mode = false
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if e.pressed:
					if e.shift_pressed:
						g.pan(Vector2(40, 0))
					else:
						g.zoom_at(e.position, 1.0 + 0.12 * maxf(1.0, e.factor))
			MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed:
					if e.shift_pressed:
						g.pan(Vector2(-40, 0))
					else:
						g.zoom_at(e.position, 1.0 / (1.0 + 0.12 * maxf(1.0, e.factor)))
			MOUSE_BUTTON_WHEEL_LEFT:
				if e.pressed:
					g.pan(Vector2(30 * maxf(1.0, e.factor), 0))
			MOUSE_BUTTON_WHEEL_RIGHT:
				if e.pressed:
					g.pan(Vector2(-30 * maxf(1.0, e.factor), 0))
			MOUSE_BUTTON_LEFT:
				if e.pressed:
					_down(e.position)
				else:
					_up(e.position)
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_pan_button = e.pressed
		accept_event()
	elif e is InputEventMouseMotion:
		if _pan_button:
			g.pan(e.relative)
		else:
			_move(e.position)
	elif e is InputEventMagnifyGesture:
		g.zoom_at(e.position, e.factor)
	elif e is InputEventPanGesture:
		g.pan(-e.delta * 10.0)


func _down(pos: Vector2) -> void:
	_pressing = true
	_panning = false
	_press_pos = pos
	_last_pos = pos
	g.press(g.screen_to_world(pos))


func _move(pos: Vector2) -> void:
	var w := g.screen_to_world(pos)
	if _pressing and g.tool == "look":
		if not _panning and pos.distance_to(_press_pos) > PAN_SLOP and g.can_pan():
			_panning = true
		if _panning:
			g.pan(pos - _last_pos)
	_last_pos = pos
	g.hover(w)


func _up(pos: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false
	g.release(g.screen_to_world(pos), not _panning)
	_panning = false
	if _touch_mode:
		g.leave()


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 1 and not _gesture:
			_down(e.position)
		elif _touches.size() >= 2:
			_start_gesture()
	else:
		_touches.erase(e.index)
		if _gesture:
			if _touches.is_empty():
				_gesture = false
			else:
				_start_gesture()
		elif _touches.is_empty():
			_up(e.position)


func _on_touch_drag(e: InputEventScreenDrag) -> void:
	_touches[e.index] = e.position
	if _gesture:
		_update_gesture()
	elif _touches.size() == 1:
		_move(e.position)


func _two_points() -> Array:
	var pts: Array = _touches.values()
	return [pts[0], pts[1] if pts.size() > 1 else pts[0]]


func _start_gesture() -> void:
	if _pressing:
		_pressing = false
		_panning = false
		g.cancel_press()
		g.leave()
	_gesture = true
	var p := _two_points()
	var a: Vector2 = p[0]
	var b: Vector2 = p[1]
	_g_dist = maxf(1.0, a.distance_to(b))
	_g_scale = g.cam_scale
	_g_world = g.screen_to_world((a + b) * 0.5)


func _update_gesture() -> void:
	var p := _two_points()
	var a: Vector2 = p[0]
	var b: Vector2 = p[1]
	if _touches.size() < 2:
		# One finger is left after a pinch: keep panning with it.
		var mid: Vector2 = a
		g.set_zoom_scale(g.cam_scale, _g_world, mid)
		return
	var dist := maxf(1.0, a.distance_to(b))
	g.set_zoom_scale(_g_scale * dist / _g_dist, _g_world, (a + b) * 0.5)
