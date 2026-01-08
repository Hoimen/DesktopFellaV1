extends Control
class_name SystemPromptPanel

@export var chat_requester_path: NodePath
@export var prompt_edit_path: NodePath
@export var apply_button_path: NodePath

# NEW: Save-path UI
@export var save_path_edit_path: NodePath

@export var apply_on_text_change: bool = false # prompt applies while typing (optional)

# Defaults (can be overridden via UI)
@export var save_path: String = "user://chat_requester_settings.cfg"
@export var save_section: String = "chat_requester"
@export var save_key: String = "system_prompt"

@onready var chat: ChatRequester = get_node_or_null(chat_requester_path) as ChatRequester
@onready var prompt_edit: Control = get_node(prompt_edit_path) as Control
@onready var apply_button: Button = get_node_or_null(apply_button_path) as Button
@onready var save_path_edit: LineEdit = get_node_or_null(save_path_edit_path) as LineEdit

func _ready() -> void:
	if chat == null:
		push_error("SystemPromptPanel: chat_requester_path is not set / invalid.")
		return

	# Initialize save-path UI
	if save_path_edit:
		save_path_edit.text = save_path
		save_path_edit.text_submitted.connect(_on_save_path_submitted)
		save_path_edit.focus_exited.connect(_on_save_path_focus_exited)

	# Load saved prompt (if any) and apply
	_reload_prompt_from_current_path()

	# Hook up events
	if apply_button:
		apply_button.pressed.connect(_apply_from_ui)

	if apply_on_text_change:
		if prompt_edit is LineEdit:
			(prompt_edit as LineEdit).text_changed.connect(_apply_text_and_save)
		elif prompt_edit is TextEdit:
			(prompt_edit as TextEdit).text_changed.connect(_apply_from_ui)

	# Allow Enter for LineEdit prompt
	if prompt_edit is LineEdit:
		(prompt_edit as LineEdit).text_submitted.connect(func(_t): _apply_from_ui())

# ---------- Save path handlers ----------

func _on_save_path_submitted(new_text: String) -> void:
	_set_save_path_from_ui(new_text)

func _on_save_path_focus_exited() -> void:
	if save_path_edit:
		_set_save_path_from_ui(save_path_edit.text)

func _set_save_path_from_ui(new_path: String) -> void:
	new_path = new_path.strip_edges()

	# Basic guardrails
	if new_path == "":
		push_warning("SystemPromptPanel: Save path cannot be empty.")
		if save_path_edit:
			save_path_edit.text = save_path
		return
	if not new_path.begins_with("user://"):
		# Keep it simple/safe: require user://
		push_warning("SystemPromptPanel: Save path must start with 'user://'")
		if save_path_edit:
			save_path_edit.text = save_path
		return

	save_path = new_path

	# Immediately reload prompt from the new file
	_reload_prompt_from_current_path()

# ---------- Prompt apply/save ----------

func _apply_text_and_save(new_text: String) -> void:
	if chat:
		chat.set_system_prompt(new_text)
	_save_prompt(new_text)

func _apply_from_ui() -> void:
	if chat == null:
		return
	var text := _get_editor_text()
	chat.set_system_prompt(text)
	_save_prompt(text)

func _reload_prompt_from_current_path() -> void:
	var saved := _load_saved_prompt()
	if saved != "":
		chat.set_system_prompt(saved)
		_set_editor_text(saved)
	else:
		# No save found at this path: show current requester prompt
		_set_editor_text(chat.system_prompt)

func _get_editor_text() -> String:
	if prompt_edit is LineEdit:
		return (prompt_edit as LineEdit).text
	if prompt_edit is TextEdit:
		return (prompt_edit as TextEdit).text
	return ""

func _set_editor_text(value: String) -> void:
	if prompt_edit is LineEdit:
		(prompt_edit as LineEdit).text = value
	elif prompt_edit is TextEdit:
		(prompt_edit as TextEdit).text = value

func _save_prompt(value: String) -> void:
	var cfg := ConfigFile.new()
	# Load existing file so we don't wipe other keys in it
	cfg.load(save_path)
	cfg.set_value(save_section, save_key, value)
	var err := cfg.save(save_path)
	if err != OK:
		push_warning("SystemPromptPanel: Failed saving config to %s (err %s)" % [save_path, str(err)])

func _load_saved_prompt() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load(save_path)
	if err != OK:
		return ""
	return str(cfg.get_value(save_section, save_key, ""))
