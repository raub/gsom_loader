extends Control

# This is to demonstrate the cache - if the loaded resource is never used,
# Godot won't keep it in cache (which only weak-refs the resources)
var _strong_ref: Resource = null

@onready var _button_clear: Button = $VBoxContainer/HBoxContainer/ButtonClear
@onready var _button_load: Button = $VBoxContainer/HBoxContainer/ButtonLoad
@onready var _button_err: Button = $VBoxContainer/HBoxContainer/ButtonErr
@onready var _button_reload: Button = $VBoxContainer/HBoxContainer/ButtonReload
@onready var _button_load_q: Button = $VBoxContainer/HBoxContainer/ButtonLoadQ
@onready var _button_reload_q: Button = $VBoxContainer/HBoxContainer/ButtonReloadQ
@onready var _label_log: Label = $VBoxContainer/ScrollContainer/LabelLog
@onready var _queue: GsomLoadQueue = GsomLoader.create_queue()


func _ready() -> void:
	GsomLoader.finished_load.connect(_handleResource)
	GsomLoader.changed_progress.connect(_handleProgress)
	
	_queue.finished_load.connect(_handleResource)
	_queue.changed_progress.connect(_handleProgress)
	
	_button_clear.pressed.connect(_clear)
	
	_button_load.pressed.connect(_load)
	_button_err.pressed.connect(_err)
	_button_reload.pressed.connect(_reload)
	
	_button_load_q.pressed.connect(_load_q)
	_button_reload_q.pressed.connect(_reload_q)


func _clear() -> void:
	_label_log.text = ""


func _load() -> void:
	_label_log.text += "Load started...\n"
	GsomLoader.load_async("res://population.tscn")
 
# Try to achieve "ERROR: Another resource is loaded from path ..."
# This happens not always. Sometimes it crashes :D
func _err() -> void:
	_label_log.text += "Load ERR started...\n"
	GsomLoader.reload_async("res://referrer_1.tscn")
	GsomLoader.reload_async("res://referrer_2.tscn")
	GsomLoader.reload_async("res://referrer_3.tscn")


func _reload() -> void:
	_label_log.text += "RE-Load started...\n"
	GsomLoader.reload_async("res://population.tscn")


func _load_q() -> void:
	_queue.load_async("res://referrer_1.tscn")
	_queue.load_async("res://referrer_2.tscn")
	_queue.load_async("res://referrer_3.tscn")
	_queue.load_async("res://referrer_4.tscn")


func _reload_q() -> void:
	_queue.reload_async("res://referrer_1.tscn")
	_queue.reload_async("res://referrer_2.tscn")
	_queue.reload_async("res://referrer_3.tscn")
	_queue.reload_async("res://referrer_4.tscn")


func _handleResource(path: String, res: Resource) -> void:
	_strong_ref = res
	_label_log.text += "Complete! (%s)\n" % path


func _handleProgress(path: String, t: float) -> void:
	if t == 0.0:
		_label_log.text += "Q Started! (%s)\n" % path
		return
	_label_log.text += "Progress %s... (%s)\n" % [t, path]


func _handleFail(path: String, status: ResourceLoader.ThreadLoadStatus) -> void:
	prints(
		"status:",
		"failed" if status == ResourceLoader.THREAD_LOAD_FAILED else "invalid",
		"(%s)" % path
	)
