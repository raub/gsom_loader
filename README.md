# gsom_loader

A Half-Life 1 inspired loader for Godot projects.
There is a singleton and optional UI (that doesn't autoload).
It's also possible to craft your own UI instead.
Future versions may provide additional UI implementations as well.


## GsomLoader

This is **an autoload singleton**, that becomes globally available when you enable the plugin.
It holds all the common loader logic and is not tied to any specific UI.

**Properties**

* `log_text: String` - the whole log text content. This may be also used to reset the log.

**Methods**

* `register_cvar(cvar_name: String, value: Variant, help_text: String = "") -> void` - makes a new
    CVAR available with default value and optional help note.
