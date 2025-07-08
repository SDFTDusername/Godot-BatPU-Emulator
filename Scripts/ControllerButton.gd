extends Button

@onready var parent: VBoxContainer = $"../../../../../.."

@export var action_name: StringName

func _ready() -> void:
	button_down.bind(button_down)
	button_up.bind(button_up)

func button_down() -> void:
	Input.action_press(action_name)

func button_up() -> void:
	Input.action_release(action_name)

#func _unhandled_input(event: InputEvent) -> void:
#	if event is InputEventKey:
#		if event.is_action_pressed(action_name):
#			text = "1"
#		elif event.is_action_released(action_name):
#			text = "0"
