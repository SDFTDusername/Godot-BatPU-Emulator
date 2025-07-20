extends Control
class_name Emulator

@onready var machine_node: MachineNode = $MachineNode

@onready var start_button: Button = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/ControlContainer/MarginContainer/VBoxContainer/HBoxContainer/StartButton
@onready var reset_button: Button = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/ControlContainer/MarginContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var step_button: Button = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/ControlContainer/MarginContainer/VBoxContainer/HBoxContainer/StepButton

@onready var pc_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/ControlContainer/MarginContainer/VBoxContainer/HBoxContainer2/PCValue
@onready var speed_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/ControlContainer/MarginContainer/VBoxContainer/HBoxContainer3/SpeedValue

@onready var instructions_per_tick_slider: HSlider = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/IPSContainer/MarginContainer/VBoxContainer/HBoxContainer2/InstructionsPerTickSlider
@onready var spin_box: SpinBox = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/IPSContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox

@onready var zero_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/FlagsContainer/MarginContainer/VBoxContainer/HBoxContainer/ZeroValue
@onready var carry_value: Label = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/FlagsContainer/MarginContainer/VBoxContainer/HBoxContainer/CarryValue

@onready var registers_label: RichTextLabel = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/RegistersContainer/MarginContainer/ScrollContainer/RegistersLabel
@onready var memory_label: RichTextLabel = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/MemoryContainer/MarginContainer/ScrollContainer/MemoryLabel

@onready var update_registers_checkbox: CheckBox = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/SettingsContainer/MarginContainer/HBoxContainer/UpdateRegisters
@onready var update_memory_checkbox: CheckBox = $MarginContainer/HSplitContainer/HSplitContainer/ControlColumn/SettingsContainer/MarginContainer/HBoxContainer/UpdateMemory

var reset := true

var start_pressed := false
var select_pressed := false

var a_pressed := false
var b_pressed := false

var up_pressed := false
var right_pressed := false
var down_pressed := false
var left_pressed := false

func _ready() -> void:
	update_start_button()
	update_all()
	update_controller()
	
	machine_node.update_screen(true)
	machine_node.load_mc_file("movement.batpu")

func _process(_delta: float) -> void:
	update_controller()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("fullscreen"):
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		if event.is_action_pressed("start"): start_pressed = true
		if event.is_action_released("start"): start_pressed = false
		
		if event.is_action_pressed("select"): select_pressed = true
		if event.is_action_released("select"): select_pressed = false
		
		if event.is_action_pressed("a"): a_pressed = true
		if event.is_action_released("a"): a_pressed = false
		
		if event.is_action_pressed("b"): b_pressed = true
		if event.is_action_released("b"): b_pressed = false
		
		if event.is_action_pressed("up"): up_pressed = true
		if event.is_action_released("up"): up_pressed = false
		
		if event.is_action_pressed("right"): right_pressed = true
		if event.is_action_released("right"): right_pressed = false
		
		if event.is_action_pressed("down"): down_pressed = true
		if event.is_action_released("down"): down_pressed = false
		
		if event.is_action_pressed("left"): left_pressed = true
		if event.is_action_released("left"): left_pressed = false


func update_controller() -> void:
	machine_node.set_controller_value(7, start_pressed)
	machine_node.set_controller_value(6, select_pressed)
	
	machine_node.set_controller_value(5, a_pressed)
	machine_node.set_controller_value(4, b_pressed)
	
	machine_node.set_controller_value(3, up_pressed)
	machine_node.set_controller_value(2, right_pressed)
	machine_node.set_controller_value(1, down_pressed)
	machine_node.set_controller_value(0, left_pressed)

func update_all() -> void:
	update_info()
	update_flags()
	update_registers()
	update_memory()

func update_start_button() -> void:
	if machine_node.is_running():
		start_button.text = "Pause"
	else:
		if reset:
			start_button.text = "Start"
		else:
			start_button.text = "Resume"

func update_info() -> void:
	pc_value.text = "%04d" % machine_node.get_program_counter()
	speed_value.text = "%d%%" % machine_node.speed_percentage

func update_flags() -> void:
	if not machine_node.is_flags_updated():
		return
	
	zero_value.text = var_to_str(machine_node.get_zero_flag())
	carry_value.text = var_to_str(machine_node.get_carry_flag())
	
	machine_node.disable_flags_updated()

func update_registers() -> void:
	if not update_registers_checkbox.button_pressed:
		return
	
	if not machine_node.is_registers_updated():
		return
	
	var registers_text := ""
	var registers := machine_node.get_registers()
	
	for i in range(len(registers)):
		var register := registers[i]
		registers_text += "r%-3s [color=ffffff4f]%03d[/color]" % ["%d:" % i, register]
		if i % 3 < 2:
			registers_text += "  "
		else:
			registers_text += "\n"
	
	registers_label.text = registers_text
	machine_node.disable_registers_updated()

func update_memory() -> void:
	if not update_memory_checkbox.button_pressed:
		return
	
	if not machine_node.is_memory_updated():
		return
	
	var memory_text := ""
	var memory := machine_node.get_memory()
	
	for i in range(len(memory)):
		var value := memory[i]
		memory_text += "%-4s [color=ffffff4f]%03d[/color]" % ["%d:" % i, value]
		if i % 3 < 2:
			memory_text += "  "
		else:
			memory_text += "\n"
	
	memory_label.text = memory_text
	self.machine_node.disable_memory_updated()

func _on_machine_node_last_ticked() -> void:
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
	machine_node.tick(true)

func _on_instructions_per_tick_slider_value_changed(value: float) -> void:
	machine_node.instructions_per_second = roundi(value)
	spin_box.value = value

func _on_spin_box_value_changed(value: float) -> void:
	machine_node.instructions_per_second = roundi(value)
	instructions_per_tick_slider.value = value
