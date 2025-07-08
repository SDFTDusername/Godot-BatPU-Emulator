extends CodeEdit

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			var rect = get_global_rect()
			if not rect.has_point(event.global_position):
				release_focus()
