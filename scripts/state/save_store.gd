extends RefCounted
## Local save files, Valheim-style: characters and worlds are separate. A character file holds
## the name, a placeholder appearance and what the character carries and wears; it can join any
## world. A world file holds one camp (communal stores, residents, plans, built structures) and
## its mission results. Plain JSON under user://saves, one file per character or world.
## No networking: a world is opened (hosted) on this computer; joining over the network is later.
const VERSION := 1
## Overridden by tests so they never touch real saves.
static var root := "user://saves"

static func _folder(kind: String) -> String:
	return root.path_join(kind)

static func _path(kind: String, id: String) -> String:
	return _folder(kind).path_join(id + ".json")

## Records of one kind ("characters" or "worlds"), newest first.
static func list(kind: String) -> Array:
	var records: Array = []
	var folder := _folder(kind)
	if not DirAccess.dir_exists_absolute(folder):
		return records
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".json"): continue
		var record := read(kind, file.get_basename())
		if not record.is_empty(): records.append(record)
	records.sort_custom(func(a, b): return int(a.get("saved_at", 0)) > int(b.get("saved_at", 0)))
	return records

static func read(kind: String, id: String) -> Dictionary:
	var path := _path(kind, id)
	if not FileAccess.file_exists(path): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("version") != VERSION or parsed.get("id") != id:
		push_warning("Ignoring unreadable save: " + path)
		return {}
	return parsed

## Writes through a temporary file, so a failed write never leaves half a save behind.
static func write(kind: String, record: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(_folder(kind))
	record.version = VERSION
	record.saved_at = Time.get_unix_time_from_system()
	var path := _path(kind, record.id)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("Could not write save: " + path)
		return false
	file.store_string(JSON.stringify(record, "\t"))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

static func new_id(prefix: String) -> String:
	return prefix + "_" + Crypto.new().generate_random_bytes(8).hex_encode()

## A new character: a name and the placeholder appearance. Equipment is empty until the first
## save, which means "issue the standard kit".
static func create_character(display_name: String) -> Dictionary:
	var record := {"id":new_id("character"),"name":display_name.strip_edges(),"appearance":"placeholder","equipment":{}}
	return record if write("characters", record) else {}

## A new world: a name, an empty camp (filled with the starting stores on first load) and no
## mission results.
static func create_world(display_name: String) -> Dictionary:
	var record := {"id":new_id("world"),"name":display_name.strip_edges(),"camp":{},"missions":{"results":{},"completed":[]}}
	return record if write("worlds", record) else {}
