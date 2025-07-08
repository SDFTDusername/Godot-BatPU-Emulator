extends PanelContainer

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var code_edit: CodeEdit = $MarginContainer/VBoxContainer/CodeEdit

@onready var save_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer/Save

@onready var open_file_dialog: FileDialog = $OpenFileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog

@onready var new_dialog: ConfirmationDialog = $NewDialog
@onready var open_dialog: ConfirmationDialog = $OpenDialog

var file_path := ""
var file_name := "Untitled"

var file_exists := false
var file_modified := false

var file_dropped := ""

func _ready() -> void:
	get_window().files_dropped.connect(files_dropped_signal)
	update_all()

func update_all() -> void:
	update_title()
	update_buttons()

func update_title() -> void:
	if file_modified:
		title_label.text = "*" + file_name
	else:
		title_label.text = file_name

func update_buttons() -> void:
	save_btn.disabled = not file_exists or not file_modified

func files_dropped_signal(files: PackedStringArray) -> void:
	file_dropped = files[0]
	if file_modified:
		open_dialog.dialog_text = "Delete changes of %s?" % file_name
		open_dialog.show()
	else:
		_on_open_dialog_confirmed()

func _on_code_edit_text_changed() -> void:
	file_modified = true
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

func _on_open_file_dialog_file_selected(path: String) -> void:
	file_path = path
	file_name = file_path.get_file()
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	code_edit.text = file.get_as_text()
	file.close()
		
	file_exists = true
	file_modified = false
	
	update_all()

func _on_save_pressed() -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(code_edit.text)
	file.close()
	
	file_modified = false
	update_all()

func _on_save_file_dialog_file_selected(path: String) -> void:
	file_path = path
	file_name = file_path.get_file()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(code_edit.text)
	file.close()
		
	file_exists = true
	file_modified = false
	
	update_all()

func _on_save_as_pressed() -> void:
	save_file_dialog.show()

func _on_new_dialog_confirmed() -> void:
	code_edit.text = ""
	
	file_path = ""
	file_name = "Untitled"
	
	file_exists = false
	file_modified = false
	
	update_all()

func _on_open_dialog_confirmed() -> void:
	if not file_dropped.is_empty():
		_on_open_file_dialog_file_selected(file_dropped)
	else:
		open_file_dialog.show()
