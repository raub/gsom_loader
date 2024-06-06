extends Node

## This is an autoload singleton, that becomes globally available when you enable the plugin.
## It exposes the async loading API that you can call from scripts.


var _loadQueue: Dictionary = {};


func _nop(_res: Resource) -> void:
	pass;


func loadAsync(path: String, cb: Callable = _nop):
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		cb.call();
		return;
	
	if !_loadQueue.has(path):
		ResourceLoader.load_threaded_request(path);
		_loadQueue[path] = [];
	
	var callbacks: Array = (_loadQueue[path] as Array);
	callbacks.append(cb);


func _ready() -> void:
	var timer: Timer = Timer.new();
	timer.wait_time = 0.1;
	timer.one_shot = false;
	timer.autostart = true;
	timer.connect("timeout", _updateLoadQueue);
	add_child(timer);


func _updateLoadQueue() -> void:
	for path: String in _loadQueue:
		var status = ResourceLoader.load_threaded_get_status(path);
		
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue;
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res: Resource = ResourceLoader.load_threaded_get(path);
			for cb: Callable in _loadQueue[path]:
				cb.call(res);
			_loadQueue.erase(path);
			continue;
		
		_loadQueue.erase(path);
		# Any other status is fail
		push_warning("Failed to load resource: '%s'." % [path]);
