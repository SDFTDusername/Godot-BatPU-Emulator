extends Button

@onready var emulator: Emulator = $"../../../../../../../../.."

@export var action_name: StringName

func _ready() -> void:
	button_down.connect(button_down_signal)
	button_up.connect(button_up_signal)

func get_event(key_pressed: bool) -> InputEventKey:
	var events := InputMap.action_get_events(action_name)
	
	var event := events[0] as InputEventKey
	event.pressed = key_pressed
	
	return event

func button_down_signal() -> void:
	emulator._unhandled_input(get_event(true))

func button_up_signal() -> void:
	emulator._unhandled_input(get_event(false))

#func _unhandled_input(event: InputEvent) -> void:
#	if event is InputEventKey:
#		if event.is_action_pressed(action_name):
#			text = "1"
#		elif event.is_action_released(action_name):
#			text = "0"
