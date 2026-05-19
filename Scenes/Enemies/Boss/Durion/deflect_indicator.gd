extends Node2D

var radius : float = 40.0
var color : Color = Color(0.8, 0.3, 1.5, 0.4)

func _draw():
	draw_circle(Vector2.ZERO, radius, color)

func set_color(new_color: Color):
	color = new_color
	queue_redraw()