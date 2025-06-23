class_name GsomLoadQueue
extends Timer

## Sequential resource loader with a queue.
##
## This approach may help fix certain concurrency-related loading errors.
## E.g. [color=red]"ERROR: Another resource is loaded from path ..."[/color].
## [br][br]
## The important part is not "ordering" but to avoid race-loading.
## You can still have many such queues running concurrently, if desired.

## Emitted when a resource has been loaded successfully.
signal finished_load(path: String, res: Resource)

## Emitted if a resource is failed to load.
signal failed_load(path: String, status: ResourceLoader.ThreadLoadStatus)

## Emitted during load and immediately before [code]finished_load[/code].
## During loading the progress goes from [code]0.0[/code] to [code]1.0[/code].
signal changed_progress(path: String, t: float)

## Get the number of items that are in the queue right now.
var count_pending: int:
	get:
		return _load_queue.size()

var _load_queue: Array[Dictionary] = []

func _ready() -> void:
	wait_time = GsomLoader.interval
	one_shot = false
	autostart = false
	connect("timeout", _update_load_queue)


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
	_load_queue.append({ "path": path, "cache": cache })
	
	# If not currently loading, start immediately
	if _load_queue.size() == 1:
		_start_next_load()


func _start_next_load() -> void:
	if _load_queue.is_empty():
		stop()
		return
	
	var first: Dictionary = _load_queue[0]
	var path: String = first.path
	var cache: ResourceLoader.CacheMode = first.cache
	
	var status: Error = ResourceLoader.load_threaded_request(path, "", false, cache)
	
	if status != OK:
		failed_load.emit(path, ResourceLoader.THREAD_LOAD_FAILED)
		_load_queue.pop_front()
		_start_next_load()
		return
	
	changed_progress.emit(path, 0.0)
	
	if is_stopped():
		start()


func _update_load_queue() -> void:
	if _load_queue.size() < 1:
		return
	
	var first: Dictionary = _load_queue[0]
	var path: String = first.path
	
	var progress: Array[float] = []
	var status: ResourceLoader.ThreadLoadStatus = (
		ResourceLoader.load_threaded_get_status(path, progress)
	)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		changed_progress.emit(path, progress[0])
		return
	
	_load_queue.pop_front()
	if _load_queue.is_empty():
		stop()
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: Resource = ResourceLoader.load_threaded_get(path)
		changed_progress.emit(path, 1.0)
		finished_load.emit(path, res)
		_start_next_load()
		return
	
	# Any other status is fail
	failed_load.emit(path, status)
	_start_next_load()
