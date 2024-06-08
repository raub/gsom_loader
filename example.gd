extends Control

## This is to demonstrate the cache - if the loaded resource is never used,
## Godot won't keep it in cache (which only weak-refs the resources)
var _strong_ref: Resource = null

@onready var _button_load: Button = $VBoxContainer/HBoxContainer/ButtonLoad
@onready var _button_reload: Button = $VBoxContainer/HBoxContainer/ButtonReload
@onready var _label_log: Label = $VBoxContainer/LabelLog


func _ready() -> void:
	_button_load.pressed.connect(_load)
	_button_reload.pressed.connect(_reload)


func _load() -> void:
	_label_log.text = "Load started...\n"
	GsomLoader.load_async("res://population.tscn", _cb, _stat)


func _reload() -> void:
	_label_log.text = "RE-Load started...\n"
	GsomLoader.reload_async("res://population.tscn", _cb, _stat)


func _cb(res: Resource) -> void:
	_strong_ref = res
	_label_log.text += "Complete!\n"


func _stat(progress: float, status: ResourceLoader.ThreadLoadStatus) -> void:
	_label_log.text += "Progress %s...\n" % progress
	
	if progress < 0.0:
		prints(
			"status:",
			"failed" if status == ResourceLoader.THREAD_LOAD_FAILED else "invalid",
		)
