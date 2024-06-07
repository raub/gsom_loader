extends Node

## This is an autoload singleton, that becomes globally available when you enable the plugin.
## It exposes the async loading API that you can call from scripts.


## Status check interval. This is how often the 
@export_range(0.02, 1.0) var interval: float = 0.1:
	get:
		return _timer.wait_time
	set(v):
		_timer.wait_time = v


var _timer := Timer.new()
var _loadQueue: Dictionary = {}


func _ready() -> void:
	_timer.wait_time = 0.1
	_timer.one_shot = false
	_timer.autostart = true
	_timer.connect("timeout", _updateLoadQueue)
	add_child(_timer)


## Loads a new resource outside of main thread. The loaded resource is passed to `cb`.
## If the same resource is requested many times, ALL callbacks will be called.
func loadAsync(path: String, cb: Callable) -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
	
	if ResourceLoader.has_cached(path) and status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		cb.call(res)
		return
	
	_load_internal(path, cb)


## Reloads the resource disregarding cache if any. The loaded resource is passed to `cb`.
## If the same resource is requested many times, EACH request will reload again separately.
func reloadAsync(path: String, cb: Callable) -> void:
	# If not in queue, just load it
	if !_loadQueue.has(path):
		_load_internal(path, cb, ResourceLoader.CACHE_MODE_REPLACE)
		return
	
	# If already queued, WAIT for load and THEN re-load
	var callbacks: Array = (_loadQueue[path] as Array)
	callbacks.append(
		func (_res: Resource) -> void:
			reloadAsync(path, cb)
	)


func _load_internal(
		path: String,
		cb: Callable,
		cache: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE,
) -> void:
	if !_loadQueue.has(path):
		ResourceLoader.load_threaded_request(path, "", false, ResourceLoader.CACHE_MODE_REPLACE)
		_loadQueue[path] = []
	
	var callbacks: Array = (_loadQueue[path] as Array)
	callbacks.append(cb)


func _updateLoadQueue() -> void:
	for path: String in _loadQueue:
		_checkPathStatus(path)


func _checkPathStatus(path: String) -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		var callbacks: Array = (_loadQueue[path] as Array)
		_loadQueue.erase(path)
		for cb: Callable in callbacks:
			cb.call(res)
		return
	
	_loadQueue.erase(path)
	# Any other status is fail
	push_warning("Failed to load resource: '%s'." % [path])
