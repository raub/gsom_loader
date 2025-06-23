# gsom_loader

A threaded async loader for Godot resources.
Loads a resource in another thread and emits signals.

There is a singleton `GsomLoader` - a concurrent loader.
And it is possible to create any number of queued loaders.

```gdscript
# This is to demonstrate the cache - if the loaded resource is never used,
# Godot won't keep it in cache (which only weak-refs the resources)
var _strong_ref: Resource = null

func _ready() -> void:
	GsomLoader.finished_load.connect(_handleResource)
	GsomLoader.changed_progress.connect(_handleProgress)
	GsomLoader.failed_load.connect(_handleFail)

func _load() -> void:
	print("Load started...")
	GsomLoader.load_async("res://test.tscn")

func _handleResource(path: String, res: Resource) -> void:
	_strong_ref = res
	print("Complete! (%s)" % path)

func _handleProgress(path: String, progress: float, status: ResourceLoader.ThreadLoadStatus) -> void:
	print("Progress %s... (%s)" % [progress, path])

func _handleFail(path: String, status: ResourceLoader.ThreadLoadStatus) -> void:
    prints(
        "status:",
        "failed" if status == ResourceLoader.THREAD_LOAD_FAILED else "invalid",
        "(%s)" % path,
    )
```

## GsomLoader

This is **an autoload singleton**, that becomes globally available when you enable the plugin.
It is not tied to any specific UI, it doesn't care what kind of resources you load.

Importantly, this loader is concurrent, meaning all your requests are being processed
as soon as possible and in parallel. This **may** lead to issues when you load two
or more resources, referencing a common dependency.
E.g. "ERROR: Another resource is loaded from path ...", or even crash the game.

So it fits better for loading unrelated resources or a single large resource, like a level.
If you want to have more control, consider [GsomLoadQueue](#gsomloadqueue).


**Signals**

- `signal finished_load(path: String, res: Resource)`
    
    Emitted when a resource has been loaded successfully.

- `signal failed_load(path: String, status: ResourceLoader.ThreadLoadStatus)`
    
    Emitted if a resource is failed to load.

- `signal changed_progress(path: String, t: float)`
    
    Emitted during load to report loading progress.
    Emitted with `0.0` at start and `1.0` immediately before done.
    During loading the progress goes from `0.0` to `1.0`.



**Properties**

* `float interval` [default: 0.1] [property: setter, getter]
    
    Status check interval. This is how often the loading progress is polled.
    This value is also inherited by new `GsomLoadQueue` objects
    (though you can later change it there).


**Methods**

* `GsomLoadQueue create_queue()`
    
    Create a queued loader instance. A queued loader also uses threads, but no concurrency within a single queue.


* `void load_async(path: String)`
    
    Loads a new resource outside of main thread. Emits finished_load when complete. 
    * Additional calls to the resource being loaded are ignored. 
    * Additional calls to a cached resource will emit finished_load immediately. 
    Emits changed_progress while loading is in progress. 
    Note: Godot cache is WEAK ref, so if you don't store/use the resource it gets uncached!


* `void reload_async(path: String)`
    
    Similar to load_async but disregards cache if the resource has already been cached by a previous load call.


## GsomLoadQueue

Sequential resource loader with a queue.

This approach may help fix certain concurrency-related loading errors. E.g. "ERROR: Another resource is loaded from path ...".

The important part is not "ordering" but to avoid race-loading. You can still have many such queues running concurrently, if desired.


**Signals**

Signals are the same as in [GsomLoader](#gsomloader).

- `signal finished_load(path: String, res: Resource)`
    
    Emitted when a resource has been loaded successfully.

- `signal failed_load(path: String, status: ResourceLoader.ThreadLoadStatus)`
    
    Emitted if a resource is failed to load.

- `signal changed_progress(path: String, t: float)`
    
    Emitted during load to report loading progress.


**Properties**

* `intcount_pending` [property: getter]
    
    Get the number of items that are in the queue right now.

Being a `Timer` node, `GsomLoadQueue` has `wait_time` (initially equal `GsomLoader.interval`).
You can change the `wait_time`, but it is not recommended to touch other `Timer` stuff.


**Methods**

* `void load_async(path: String)`
    
    Loads a new resource outside of main thread. Emits finished_load when complete. 
    * Additional calls to the resource being loaded are ignored. 
    * Additional calls to a cached resource will emit finished_load immediately. 
    Emits changed_progress while loading is in progress. 
    Note: Godot cache is WEAK ref, so if you don't store/use the resource it gets uncached!


* `void reload_async(path: String)`
    
    Similar to load_async but disregards cache if the resource has already been cached by a previous load call.
