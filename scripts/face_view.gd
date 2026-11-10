class_name FaceView
extends Node2D
## Draws the keeper's face behind the back glass. The water bands show through it,
## and the sand pass that follows covers the chin.

var g: Game

const GLASS := Color(0.9, 0.96, 1.0, 0.86)


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if g == null or g.S.is_empty() or g.keeper.state == "hidden":
		return
	draw_texture_rect(Sprites.face_tex(g.keeper_frame()), g.keeper_rect(), false, GLASS)
