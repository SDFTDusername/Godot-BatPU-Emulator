extends Control

@onready var machine_node: MachineNode = $MachineNode

@onready var start_button: Button = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/StartButton
@onready var reset_button: Button = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var step_button: Button = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/StepButton

@onready var pc_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/PCValue

@onready var instructions_per_tick_slider: HSlider = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer7/MarginContainer/VBoxContainer/HBoxContainer2/InstructionsPerTickSlider
@onready var spin_box: SpinBox = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer7/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox

@onready var zero_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer3/MarginContainer/VBoxContainer/HBoxContainer/ZeroValue
@onready var carry_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/PanelContainer3/MarginContainer/VBoxContainer/HBoxContainer/CarryValue

var reset := true

func _ready() -> void:
	update_start_button()
	update_all()
	update_controller()
	
	machine_node.update_screen(true)
	machine_node.load_mc_file("movement.mc")

func _process(_delta: float) -> void:
	update_controller()

func update_controller() -> void:
	machine_node.set_controller_value(7, Input.is_action_pressed("start"))
	machine_node.set_controller_value(6, Input.is_action_pressed("select"))
	
	machine_node.set_controller_value(5, Input.is_action_pressed("a"))
	machine_node.set_controller_value(4, Input.is_action_pressed("b"))
	
	machine_node.set_controller_value(3, Input.is_action_pressed("up"))
	machine_node.set_controller_value(2, Input.is_action_pressed("right"))
	machine_node.set_controller_value(1, Input.is_action_pressed("down"))
	machine_node.set_controller_value(0, Input.is_action_pressed("left"))

func update_all() -> void:
	update_program_counter()
	update_flags()

func update_start_button() -> void:
	if machine_node.is_running():
		start_button.text = "Pause"
	else:
		if reset:
			start_button.text = "Start"
		else:
			start_button.text = "Resume"

func update_program_counter() -> void:
	pc_value.text = "%04d" % machine_node.get_program_counter()

func update_flags() -> void:
	zero_value.text = var_to_str(machine_node.get_zero_flag())
	carry_value.text = var_to_str(machine_node.get_carry_flag())

func _on_machine_node_ticked() -> void:
	update_all()

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
	update_all()
	update_controller()

func _on_step_button_pressed() -> void:
	machine_node.tick()

func _on_instructions_per_tick_slider_value_changed(value: float) -> void:
	machine_node.instructions_per_second = roundi(value)
	spin_box.value = value

func _on_spin_box_value_changed(value: float) -> void:
	machine_node.instructions_per_second = roundi(value)
	instructions_per_tick_slider.value = value
