extends Control
## Builds the scene. The tank renders at low resolution into a SubViewport. TankDisplay shows
## the camera's part of it, scaled up with nearest filtering. The HUD sits on top.

## Simulation speed. The design exposed 1, 2 and 4.
@export_enum("1:1", "2:2", "4:4") var speed := 1
## Optional CRT scanlines over the screen.
@export var scanlines := false

var game: Game
var synth: Synth
var vp: SubViewport
var bg: ColorRect
var sand_front: ColorRect
var algae_rect: ColorRect
var tint: ColorRect
var display: TankDisplay
var hud: Hud
var _dpr := 1.0


func _ready() -> void:
	_setup_window()
	# The Clean tool draws its own ring, so its cursor shape is an empty image.
	var empty := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	empty.fill(Color(0, 0, 0, 0))
	Input.set_custom_mouse_cursor(empty, Input.CURSOR_HELP)

	synth = Synth.new()
	add_child(synth)
	game = Game.new()
	game.synth = synth
	game.speed = float(speed)
	add_child(game)

	vp = SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.snap_2d_transforms_to_pixel = true
	vp.snap_2d_vertices_to_pixel = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(256, 160)
	add_child(vp)
	bg = _shader_rect("res://shaders/bg.gdshader")
	vp.add_child(bg)
	var face := FaceView.new()
	face.g = game
	vp.add_child(face)
	sand_front = _shader_rect("res://shaders/bg.gdshader")
	(sand_front.material as ShaderMaterial).set_shader_parameter("sand_only", true)
	vp.add_child(sand_front)
	var tv := TankView.new()
	tv.g = game
	vp.add_child(tv)
	algae_rect = _shader_rect("res://shaders/algae.gdshader")
	vp.add_child(algae_rect)
	tint = ColorRect.new()
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	tint.material = mul
	tint.mouse_filter = MOUSE_FILTER_IGNORE
	vp.add_child(tint)
	var ov := OverlayView.new()
	ov.g = game
	vp.add_child(ov)

	display = TankDisplay.new()
	display.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	display.g = game
	display.vp = vp
	add_child(display)
	if scanlines:
		var scan := _shader_rect("res://shaders/scanlines.gdshader")
		scan.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		add_child(scan)
	hud = Hud.new()
	add_child(hud)
	hud.build(game)

	game.world_resized.connect(_on_world_resized)
	game.algae_texture_created.connect(_on_algae_texture)
	# Wait for the HUD to lay out, so the tank knows how much of the screen the bars cover.
	await get_tree().process_frame
	await get_tree().process_frame
	game.start(hud.size, hud.top_bar.global_position.y + hud.top_bar.size.y + 3.0, hud.size.y - hud.bottom_bar.global_position.y + 3.0)


func _shader_rect(path: String) -> ColorRect:
	var r := ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = load(path)
	r.material = m
	r.mouse_filter = MOUSE_FILTER_IGNORE
	return r


func _setup_window() -> void:
	var win := get_window()
	_dpr = clampf(DisplayServer.screen_get_scale(), 1.0, 4.0)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.size_changed.connect(_fit_scale)
	_fit_scale()


## Keeps one UI pixel equal to one CSS pixel on high-density screens such as phones.
func _fit_scale() -> void:
	var win := get_window()
	var base := Vector2i((Vector2(win.size) / _dpr).round()).max(Vector2i(1, 1))
	if win.content_scale_size != base:
		win.content_scale_size = base


func _on_world_resized() -> void:
	var sz := Vector2(game.W, game.H)
	vp.size = Vector2i(game.W, game.H)
	for r in [bg, sand_front, algae_rect, tint]:
		r.position = Vector2.ZERO
		r.size = sz
	for m: ShaderMaterial in [bg.material, sand_front.material]:
		m.set_shader_parameter("W", float(game.W))
		m.set_shader_parameter("H", float(game.H))
		m.set_shader_parameter("TOP", float(game.TOP))
		m.set_shader_parameter("SAND", float(game.SAND))
	var a: ShaderMaterial = algae_rect.material
	a.set_shader_parameter("AW", game.AW)
	a.set_shader_parameter("AH", game.AH)
	a.set_shader_parameter("W", float(game.W))
	a.set_shader_parameter("H", float(game.H))
	a.set_shader_parameter("TOP", float(game.TOP))


func _on_algae_texture(t: ImageTexture) -> void:
	(algae_rect.material as ShaderMaterial).set_shader_parameter("grid", t)


func _process(_dt: float) -> void:
	if game.S.is_empty():
		return
	var sky := D.sky_at(game.S.t)
	var c: Color = sky.tint
	tint.visible = c != Color.WHITE
	tint.color = c
