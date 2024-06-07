# gsom_loader

A threaded async loader for Godot resources.
Loads a resource in another thread and then calls your callback(s).


## GsomLoader

This is **an autoload singleton**, that becomes globally available when you enable the plugin.
It holds all the common loader logic and is not tied to any specific UI.

**Properties**

* `log_text: String` - the whole log text content. This may be also used to reset the log.

**Methods**

* `register_cvar(cvar_name: String, value: Variant, help_text: String = "") -> void` - makes a new
    CVAR available with default value and optional help note.
