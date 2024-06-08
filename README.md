# gsom_loader

A threaded async loader for Godot resources.
Loads a resource in another thread and then calls your callback(s).

```gdscript
# This is to demonstrate the cache - if the loaded resource is never used,
# Godot won't keep it in cache (which only weak-refs the resources)
var _strong_ref: Resource = null

func _load() -> void:
	print("Load started...")
	GsomLoader.load_async("res://test.tscn", _cb, _stat)

func _cb(res: Resource) -> void:
	_strong_ref = res
	print("Complete!")

func _stat(progress: float, status: ResourceLoader.ThreadLoadStatus) -> void:
	print("Progress %s..." % progress)
	
	if progress < 0.0:
		prints(
			"status:",
			"failed" if status == ResourceLoader.THREAD_LOAD_FAILED else "invalid",
		)
```

## GsomLoader

This is **an autoload singleton**, that becomes globally available when you enable the plugin.
It holds all the common loader logic and is not tied to any specific UI.

**Properties**

* `float interval` [default: 0.1] [property: setter, getter]

Status check interval. This is how often the loading progress is updated for each resource.


**Methods**

* `void load_async(path: String, cb: Callable, stat: Callable = <unknown>)` -
    Loads a new resource outside of main thread. The loaded resource is passed to `cb`.
    If the same resource is requested many times, ALL callbacks will be called.
    
    * `func cb(res: Resource) -> void` - called when and if the resource is loaded.
    * `func stat(progress: float, status: ResourceLoader.ThreadLoadStatus) -> void` -
        optional callback for progress tracking. When complete, `progress == 1.0`,
        when errored `progress == -1.0`. During loading it goes from `0.0` to `1.0`.
    
    Note: Godot cache is WEAK ref, so if you don't store/use the resource it gets uncached!

* `void reload_async(path: String, cb: Callable, stat: Callable = <unknown>)` -
    Reloads the resource disregarding cache if any. The loaded resource is passed to `cb`.
    If the same resource is requested many times, EACH request will reload again separately.
    
    * `func cb(res: Resource) -> void` - called when and if the resource is loaded.
    * `func stat(progress: float, status: ResourceLoader.ThreadLoadStatus) -> void` -
        optional callback for progress tracking. When complete, progress == 1.0,
        when errored `progress == -1.0`. During loading it goes from `0.0` to `1.0`.
