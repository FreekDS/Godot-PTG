extends Spatial

export(float, 0.0, 10, 0.1) onready var rotation_speed = 0.2

func _process(delta):
	rotate_y(rotation_speed * delta)
