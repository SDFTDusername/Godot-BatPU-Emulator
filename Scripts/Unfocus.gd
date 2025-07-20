extends Control

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		var global_rect := get_global_rect()
		if not global_rect.has_point(event.global_position):
			release_focus()
