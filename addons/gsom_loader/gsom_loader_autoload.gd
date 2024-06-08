extends Node

## This is an autoload singleton, that becomes globally available when you enable the plugin.
## It exposes the async loading API that you can call from scripts.


## Status check interval. This is how often the loading progress is updated for each resource.
@export_range(0.02, 1.0) var interval: float = 0.1:
	get:
		return _timer.wait_time
	set(v):
		_timer.wait_time = v


var _timer := Timer.new()
var _load_queue: Dictionary = {}


func _ready() -> void:
	_timer.wait_time = 0.1
	_timer.one_shot = false
	_timer.autostart = true
	_timer.connect("timeout", _update_load_queue)
	add_child(_timer)


## Loads a new resource outside of main thread. The loaded resource is passed to [code]cb[/code].
## If the same resource is requested many times, ALL callbacks will be called.
## [br]
## * [code]func cb(res: Resource) -> void[/code] - called when and if the resource is loaded.
## [br]
## * [code]func stat(progress: float, status: ResourceLoader.ThreadLoadStatus) -> void[/code] -
## optional callback for progress tracking. When complete, [code]progress == 1.0[/code], when
## errored [code]progress == -1.0[/code]. During loading it goes from [code]0.0[/code] to [code]1.0[/code].
## [br]
## Note: Godot cache is WEAK ref, so if you don't store/use the resource it gets uncached!
func load_async(path: String, cb: Callable, stat: Callable = _nop_stat) -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		stat.call(1.0, status)
		cb.call(res)
		return
	
	_load_internal(path, cb, stat, ResourceLoader.CACHE_MODE_REUSE)


## Reloads the resource disregarding cache if any. The loaded resource is passed to [code]cb[/code].
## If the same resource is requested many times, EACH request will reload again separately.
## [br]
## * [code]func cb(res: Resource) -> void[/code] - called when and if the resource is loaded.
## [br]
## * [code]func stat(progress: float, status: ResourceLoader.ThreadLoadStatus) -> void[/code] -
## optional callback for progress tracking. When complete, [code]progress == 1.0[/code], when
## errored [code]progress == -1.0[/code]. During loading it goes from [code]0.0[/code] to [code]1.0[/code].
func reload_async(path: String, cb: Callable, stat: Callable = _nop_stat) -> void:
	# If not in queue, just load it
	if !_load_queue.has(path):
		_load_internal(path, cb, stat, ResourceLoader.CACHE_MODE_IGNORE)
		return
	
	# If already queued, WAIT for load and THEN re-load
	var next: Callable = func (_res: Resource) -> void:
		reload_async(path, cb, stat)
	
	var callbacks: Array = (_load_queue[path] as Array)
	callbacks.append([next, stat])


func _nop_stat(_progress: float, _status: ResourceLoader.ThreadLoadStatus) -> void:
	pass


func _load_internal(
		path: String,
		cb: Callable,
		stat: Callable,
		cache: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE,
) -> void:
	if !_load_queue.has(path):
		ResourceLoader.load_threaded_request(path, "", false, cache)
		_load_queue[path] = [] as Array[Array]
	
	var callbacks := (_load_queue[path] as Array[Array])
	callbacks.append([cb, stat])


func _update_load_queue() -> void:
	for path: String in _load_queue:
		_check_path_status(path)


func _check_path_status(path: String) -> void:
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
		path,
		progress,
	)
	
	var callbacks := (_load_queue[path] as Array[Array])
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		for cbstat: Array[Callable] in callbacks:
			cbstat[1].call(progress[0], status)
		return
	
	_load_queue.erase(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		for cbstat: Array[Callable] in callbacks:
			cbstat[1].call(1.0, status)
			cbstat[0].call(res)
		return
	
	# Any other status is fail
	for cbstat: Array[Callable] in callbacks:
		cbstat[1].call(-1.0, status)
