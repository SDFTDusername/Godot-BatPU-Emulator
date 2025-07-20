extends PanelContainer

@onready var emulator: Emulator = $"../../../.."

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var code_edit: CodeEdit = $MarginContainer/VBoxContainer/CodeEdit

@onready var assemble_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer/Assemble

@onready var save_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer2/Save
@onready var save_as_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer2/SaveAs

@onready var error_container: MarginContainer = $ErrorContainer
@onready var error_title_label: Label = $ErrorContainer/Panel/MarginContainer/VBoxContainer/Title
@onready var errors_label: RichTextLabel = $ErrorContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/Errors

@onready var open_file_dialog: FileDialog = $OpenFileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog

@onready var new_dialog: ConfirmationDialog = $NewDialog
@onready var open_dialog: ConfirmationDialog = $OpenDialog

var file_path := ""
var file_name := "Untitled"

var file_exists := false
var file_modified := false
var file_assembled := true

var is_machine_code := false
var instructions: InstructionArray = null

var file_dropped := ""

func _ready() -> void:
	get_window().files_dropped.connect(files_dropped_signal)
	update_all()

func update_all() -> void:
	update_title()
	update_buttons()
	code_edit.editable = not is_machine_code

func update_title() -> void:
	if file_modified:
		title_label.text = "*" + file_name
	else:
		title_label.text = file_name

func update_buttons() -> void:
	assemble_btn.disabled = file_assembled
	
	save_btn.disabled = not file_modified or is_machine_code
	save_as_btn.disabled = not file_modified and not file_exists

func files_dropped_signal(files: PackedStringArray) -> void:
	file_dropped = files[0]
	if file_modified:
		open_dialog.dialog_text = "Delete changes of %s?" % file_name
		open_dialog.show()
	else:
		_on_open_dialog_confirmed()

func _on_code_edit_text_changed() -> void:
	file_modified = true
	file_assembled = false
	
	update_all()

func _on_new_pressed() -> void:
	if file_modified:
		new_dialog.dialog_text = "Delete changes of %s?" % file_name
		new_dialog.show()
	else:
		_on_new_dialog_confirmed()

func _on_open_pressed() -> void:
	file_dropped = ""
	if file_modified:
		open_dialog.dialog_text = "Delete changes of %s?" % file_name
		open_dialog.show()
	else:
		_on_open_dialog_confirmed()

func read_file(file: FileAccess) -> void:
	if is_machine_code:
		var bytes: PackedByteArray = []
		
		while file.get_position() < file.get_length():
			var line := file.get_line().strip_edges()
			if line.is_empty():
				continue
			
			var byte_count := line.length() / 8
			var binary := line.bin_to_int()
			
			for i in range(byte_count):
				bytes.append((binary >> ((byte_count - i - 1) * 8)) & 0xFF)
		
		instructions = emulator.binary_to_instructions(bytes)
		if show_errors(instructions):
			return
		
		code_edit.text = emulator.instructions_to_text(instructions)
	else:
		instructions = null
		code_edit.text = file.get_as_text()

func show_errors(instruction_array: InstructionArray) -> bool:
	if instruction_array.has_errors():
		var errors := instruction_array.get_errors()
		
		error_title_label.text = "%d error%s" % [errors.size(), "" if errors.size() == 1 else "s"]
		errors_label.text = "\n".join(errors)
		
		error_container.show()
		return true
	
	error_container.hide()
	return false

func _on_open_file_dialog_file_selected(path: String) -> void:
	file_path = path
	file_name = file_path.get_file()
	
	is_machine_code = path.get_file().ends_with(".mc")
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	read_file(file)
	file.close()
		
	file_exists = true
	file_modified = false
	file_assembled = false
	
	update_all()
	_on_assemble_pressed()

func _on_save_pressed() -> void:
	if not file_exists:
		_on_save_as_pressed()
		return
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(code_edit.text)
	file.close()
	
	file_modified = false
	update_all()
	_on_assemble_pressed()

func _on_save_file_dialog_file_selected(path: String) -> void:
	file_path = path
	file_name = file_path.get_file()
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(code_edit.text)
	file.close()
	
	var previous_file_modified := file_modified
	
	file_exists = true
	file_modified = false
	file_assembled = false
	
	is_machine_code = false
	
	update_all()
	
	if previous_file_modified:
		_on_assemble_pressed()

func _on_save_as_pressed() -> void:
	save_file_dialog.show()

func _on_new_dialog_confirmed() -> void:
	code_edit.text = ""
	
	file_path = ""
	file_name = "Untitled"
	
	file_exists = false
	file_modified = false
	file_assembled = false
	
	is_machine_code = false
	
	update_all()

func _on_open_dialog_confirmed() -> void:
	if not file_dropped.is_empty():
		_on_open_file_dialog_file_selected(file_dropped)
	else:
		open_file_dialog.show()

func _on_assemble_pressed() -> void:
	if is_machine_code:
		emulator.load_instructions(instructions)
	else:
		var assembled_instructions := emulator.assemble_text(code_edit.text)
		if show_errors(assembled_instructions):
			return
		
		emulator.load_instructions(assembled_instructions)
	
	emulator.reset()
	
	file_assembled = true
	update_all()

func _on_okay_button_pressed() -> void:
	error_container.hide()
