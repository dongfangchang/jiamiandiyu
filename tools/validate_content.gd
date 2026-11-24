extends SceneTree

## Validates data/manifest.json content (schema, unique ids, cross references).
## Usage: "$GODOT" --headless --path . --script res://tools/validate_content.gd [-- <manifest path>]

const ContentValidatorScript := preload("res://src/infrastructure/content_validator.gd")
const ContentManifestScript := preload("res://src/infrastructure/content_manifest.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else ContentManifestScript.DEFAULT_PATH
	var result := ContentValidatorScript.validate_manifest(path)
	if result.ok:
		print("validate_content: OK content_revision=%d kinds=%s" % [
			int(result.data.content_revision), ",".join(result.data.kinds)
		])
		quit(0)
		return
	printerr("validate_content: FAILED (%s)" % result.code)
	for message in result.details.get("errors", []):
		printerr("  " + String(message))
	quit(1)
