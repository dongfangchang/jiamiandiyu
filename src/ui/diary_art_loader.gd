extends RefCounted

## Background loader for the diary's 1260x1770 leaf illustrations.
## Neighbouring spreads are requested ahead with load_threaded_request, so a
## turn never pays a synchronous decode. Only a cold open (no prefetch yet)
## blocks, and that is counted so tests can assert the warm path never does.

var blocking_loads := 0
var threaded_requests := 0
var _held: Dictionary = {}


func request(path: String) -> void:
	if path.is_empty() or _held.has(path):
		return
	if ResourceLoader.has_cached(path):
		_held[path] = load(path) as Texture2D
		return
	if not ResourceLoader.exists(path, "Texture2D"):
		return
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		if ResourceLoader.load_threaded_request(path, "Texture2D") == OK:
			threaded_requests += 1


func ready(path: String) -> bool:
	if path.is_empty() or _held.has(path) or ResourceLoader.has_cached(path):
		return true
	var status := ResourceLoader.load_threaded_get_status(path)
	return status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_FAILED \
		or not ResourceLoader.exists(path, "Texture2D")


func take(path: String, block: bool) -> Texture2D:
	## Returns the texture if available without waiting; with `block`, waits
	## (cold open only). Null means "not ready yet" when not blocking.
	if path.is_empty():
		return null
	if _held.has(path):
		return _held[path]
	if ResourceLoader.has_cached(path):
		_held[path] = load(path) as Texture2D
		return _held[path]
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_held[path] = ResourceLoader.load_threaded_get(path) as Texture2D
		return _held[path]
	if not block:
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			request(path)
		return null
	blocking_loads += 1
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_held[path] = ResourceLoader.load_threaded_get(path) as Texture2D
	else:
		_held[path] = load(path) as Texture2D
	return _held[path]


func keep_only(paths: Array) -> void:
	## Drop strong refs outside the ring so the volume does not stay resident.
	for path in _held.keys():
		if not path in paths:
			_held.erase(path)
