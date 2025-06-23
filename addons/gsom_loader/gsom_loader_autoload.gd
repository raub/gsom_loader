extends Node

## This is [b]an autoload singleton[/b], that becomes globally available when you enable the plugin.
##
## It is not tied to any specific UI, it doesn't care what kind of resources you load.
## [br][br]
## Importantly, this loader is concurrent, meaning all your requests are being processed
## as soon as possible and in parallel. This [b]may[/b] lead to issues when you load two
## or more resources, referencing a common dependency.
## E.g. [color=red]"ERROR: Another resource is loaded from path ..."[/color], or even crash the game.
## [br][br]
## So it fits better for loading unrelated resources or a single large resource, like a level.
## If you want to have more control, consider [GsomLoadQueue].

## Emitted when a resource has been loaded successfully.
signal finished_load(path: String, res: Resource)

## Emitted if a resource is failed to load.
signal failed_load(path: String, status: ResourceLoader.ThreadLoadStatus)

## Emitted during load to report loading progress.
## Emitted with [code]0.0[/code] at start and [code]1.0[/code] immediately before done.
## During loading the progress goes from [code]0.0[/code] to [code]1.0[/code].
signal changed_progress(path: String, t: float)

## Status check interval. This is how often the loading progress is updated for each resource.
@export_range(0.02, 1.0) var interval: float = 0.1:
	get:
		return _timer.wait_time
	set(v):
		_timer.wait_time = v


var _timer: Timer = Timer.new()
var _load_queue: Dictionary[String, bool] = {}


func _ready() -> void:
	_timer.wait_time = 0.1
	_timer.one_shot = false
	_timer.autostart = false
	_timer.connect("timeout", _update_load_queue)
	add_child(_timer)


## Create a queued loader instance.
## A queued loader also uses threads, but no concurrency within a single queue.
func create_queue() -> GsomLoadQueue:
	var instance: GsomLoadQueue = GsomLoadQueue.new()
	add_child(instance)
	return instance


## Loads a new resource outside of main thread. Emits [code]finished_load[/code] when complete.
## [br]
## * Additional calls to the resource being loaded are ignored.
## [br]
## * Additional calls to a cached resource will emit [code]finished_load[/code] immediately.
## [br]
## Emits [code]changed_progress[/code] while loading is in progress.
## [br]
## Note: Godot cache is WEAK ref, so if you don't store/use the resource it gets uncached!
func load_async(path: String) -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		changed_progress.emit(path, 1.0)
		finished_load.emit(path, res)
		return
	
	_load_internal(path, ResourceLoader.CACHE_MODE_REUSE)


## Similar to [code]load_async[/code] but disregards cache if the resource
## has already been cached by a previous load call.
func reload_async(path: String) -> void:
	# If not in queue, reload it
	_load_internal(path, ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _load_internal(path: String, cache: ResourceLoader.CacheMode) -> void:
	# Ignore if already in queue
	if _load_queue.has(path):
		return
	
	if _timer.is_stopped():
		_timer.start()
	
	var status: Error = ResourceLoader.load_threaded_request(path, "", false, cache)
	
	if status != OK:
		failed_load.emit(path, ResourceLoader.THREAD_LOAD_FAILED)
		return
	
	changed_progress.emit(path, 0.0)
	_load_queue[path] = true


func _update_load_queue() -> void:
	for path: String in _load_queue:
		_check_path_status(path)


func _check_path_status(path: String) -> void:
	var progress: Array[float] = []
	var status: ResourceLoader.ThreadLoadStatus = (
		ResourceLoader.load_threaded_get_status(path, progress)
	)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		changed_progress.emit(path, progress[0])
		return
	
	_load_queue.erase(path)
	if _load_queue.is_empty():
		_timer.stop()
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		changed_progress.emit(path, 1.0)
		finished_load.emit(path, res)
		return
	
	# Any other status is fail
	failed_load.emit(path, status)
