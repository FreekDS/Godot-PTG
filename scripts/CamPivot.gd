extends KinematicBody


onready var camera = $Camera
var capturing = true

export var winterbeelden = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):
	if winterbeelden:
		rotate(Vector3(0, 1, 0), .1 * delta)
	
func _input(event):
	if event is InputEventMouseMotion and capturing:
		camera.rotation_degrees.x -= event.relative.y * .2
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 90)
		rotation_degrees.y -= event.relative.x * .2
		
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			if capturing:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				capturing = false
		if event.scancode == KEY_ENTER:
			if not capturing:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				capturing = true


func _physics_process(_delta):
	
	var movement = Vector3(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("up") - Input.get_action_strength("down"),
		Input.get_action_strength("back") - Input.get_action_strength("forward")
	)
	
	var dir = transform.basis * movement * 800
	
	move_and_slide(dir)
	
	pass
