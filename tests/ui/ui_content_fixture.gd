extends RefCounted

## R2-09 test fixture: screens and UI catalogs no longer read content files,
## so runners that build them without an AppController hand over the same
## schema-validated card / diary content the app injects at startup.

const AppControllerScript := preload("res://src/app/app_controller.gd")


static func ensure() -> void:
	AppControllerScript.configure_ui_content()
