extends Control

@onready var machine_node: MachineNode = $MachineNode

@onready var start_button: Button = $MarginContainer/HBoxContainer/ControlColumn/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/StartButton
@onready var reset_button: Button = $MarginContainer/HBoxContainer/ControlColumn/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var step_button: Button = $MarginContainer/HBoxContainer/ControlColumn/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/StepButton

@onready var instructions_per_tick_slider: HSlider = $MarginContainer/HBoxContainer/ControlColumn/VBoxContainer/PanelContainer7/MarginContainer/VBoxContainer/HBoxContainer2/InstructionsPerTickSlider
@onready var spin_box: SpinBox = $MarginContainer/HBoxContainer/ControlColumn/VBoxContainer/PanelContainer7/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox

@onready var pc_label: Label = $MarginContainer/HBoxContainer/ControlColumn/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/PCLabel

var reset := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_start_button()
	update_program_counter()
	
	machine_node.update_screen(true)
	machine_node.load_mc_file("movement.mc")

func update_program_counter() -> void:
	pc_label.text = "Program Counter: %d" % machine_node.get_program_counter()

func _on_machine_node_ticked() -> void:
	update_program_counter()

func _on_instructions_per_tick_slider_value_changed(value: float) -> void:
	machine_node.instructions_per_second = roundi(value)
	spin_box.value = value

func _on_spin_box_value_changed(value: float) -> void:
	machine_node.instructions_per_second = roundi(value)
	instructions_per_tick_slider.value = value

func update_start_button() -> void:
	if machine_node.is_running():
		start_button.text = "Pause"
	else:
		if reset:
			start_button.text = "Start"
		else:
			start_button.text = "Resume"

func _on_start_button_pressed() -> void:
	if machine_node.is_running():
		machine_node.stop()
	else:
		machine_node.start()
		reset = false
	
	update_start_button()

func _on_reset_button_pressed() -> void:
	machine_node.reset()
	reset = true
	
	update_start_button()
	update_program_counter()

func _on_step_button_pressed() -> void:
	machine_node.tick()
