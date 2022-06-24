extends Control


export(NodePath) onready var GenerateButton = get_node(GenerateButton) as Button
export(NodePath) onready var LODSliderLabel = get_node(LODSliderLabel) as Label
export(NodePath) onready var LODSlider = get_node(LODSlider) as HSlider

onready var root = get_parent().get_node("Root")

var autoGen = false



func _on_Regenerate_pressed():
	root.rebuild_chunk()
	pass


func _on_auto_toggled(button_pressed):
	GenerateButton.disabled = button_pressed
	autoGen = button_pressed


func _on_LODSlider_value_changed(value):
	LODSliderLabel.set_text("= " + str(value))
	root.switch_LOD(value - 1)
	if autoGen:
		root.rebuild_chunk()
