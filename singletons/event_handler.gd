extends Node

var state: Dictionary = {
	"server": {},
	"players": {}
}
var event_queue: Array = []
var event_history: Array = []
var map: Node
var game_started: bool = false

# Processes the event queue every frame using the reducer
func _process(delta: float) -> void:
	# Sort the events according to the sorting function
	event_queue.sort_custom(self, "_event_sorter")
	# Go through them and run the reducer
	for event in event_queue:
		Debug.push_log(event)
		self.state = self._reducer(state, event)
	event_queue.clear()

# Add an event to the event queue which will be processed by the reducer
# Adds in the unique ID of the user and the time of the call as well
func event(action: String, payload: Dictionary = {}) -> void:
	rpc("_rpc_event_push", {
		# User ID
		"id": get_tree().get_network_unique_id(),
		# Time of the event in milliseconds
		"time": OS.get_system_time_msecs(),
		# The event's action
		"action": action,
		# The event's payload
		"payload": payload,
		})

# The internal function that should be called via RPC to add events to
# everyone's event queue
remotesync func _rpc_event_push(event: Dictionary) -> void:
	# Add to the event queue
	self.event_queue.push_back(event)

# TODO possibly replace string actions with an Enum?

# The state reducer that takes an event and modifies the state based on it.
# This function is modeled like a pure function, though will cause effects
# by modifying the various aspects of the running game to match the state.
func _reducer(state: Dictionary, event: Dictionary) -> Dictionary:
	# The reducer is effectively a huge match block
	match event:
		{"action": "start_server", "id": var id, "payload": { "ip": var ip, "pin": var pin }, "time": var time}:
			state["server"] = { "ip": ip, "pin": pin, "owner": id, "start_time": time}
		{"action": "connect", "id": var id, "payload": var payload, "time": _}:
			state["players"][id] = payload
			state["players"][id]["speed"] = 0
			state["players"][id]["pos"] = Vector2() # TODO replace this with a random location
			state["players"][id]["chassis_rot"] = 0
			state["players"][id]["barrel_rot"] = 0
		{"action": "set_map_seed", "payload": { "seed": var map_seed }, "id": _, "time": _}:
			state["map_seed"] = map_seed
		{"action": "game_start", "id":_, "payload": _, "time": _}:
			self.map = load("res://map/MainMap.tscn").instance()
			self.map.init(state["map_seed"], state["players"])
			switch_scene(map)
			self.game_started = true
		{"action": "increase_speed", "id": var id, "payload": _, "time": _}:
			var speed = clamp(state["players"][id]["speed"] + 1, -1, 1)
			state["players"][id]["speed"] = speed
			map.player_callv(id, "set_speed", [speed])
		{"action": "decrease_speed", "id": var id, "payload": _, "time": _}:
			var speed = clamp(state["players"][id]["speed"] - 1, -1, 1)
			state["players"][id]["speed"] = speed
			self.map.player_callv(id, "set_speed", [speed])
		{"action": "start_rotating", "id": var id, "payload": { "dir": var dir }, "time": _}:
			self.map.player_callv(id, "start_rotating_chassis", [dir])
		{"action": "stop_rotating", "id": var id, "payload": _, "time": _}:
			self.map.player_callv(id, "stop_rotating_chassis")
		{"action": "sync_rotation", "id": var id, "payload": { "deg": var deg }, "time": _}:
			self.map.player_callv(id, "set_rotation", [deg])
		{"action": "rotate_barrel", "id": var id, "payload": { "deg": var deg }, "time": _}:
			self.map.player_callv(id, "set_barrel_rotation", [deg])
		_:
			push_warning("Unknown event: %s" % event)

	# Finally return the possibly modified state
	return state

# === Input Listener ===

func _input(event: InputEvent) -> void:
	# Return early if the game has not begun
	if not self.game_started:
		return
	
	# Forward and backward movement
	if event.is_action_pressed("increase_speed"):
		self.event("increase_speed")
	elif event.is_action_pressed("decrease_speed"):
		self.event("decrease_speed")
	
	# Chassis Rotation
	if event.is_action_pressed("rotate_left"):
		self.event("start_rotating", {"dir": "left"})
	elif event.is_action_pressed("rotate_right"):
		self.event("start_rotating", {"dir": "right"})
	elif event.is_action_released("rotate_left") or event.is_action_released("rotate_right"):
		self.event("stop_rotating")
	
	# Mouse barrel rotation
	if event is InputEventMouseButton:
		if event.get_button_index() == BUTTON_LEFT:
			self.event("rotate_barrel", { "deg": pos2deg(event.get_global_position()) })
		elif event.get_button_index() == BUTTON_RIGHT:
			pass

# === Getters ===

func get_players() -> Dictionary:
	return self.state.get("players")

# === State Syncing ===

func send_state(id: int) -> void:
	rset_id(id, "state", self.state)

# === Helper Functions ===

# Switches the scene in a better way to an instance of another scene
func switch_scene(scene_instance: Node) -> void:
	var root = get_tree().get_root()
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(scene_instance)
	get_tree().set_current_scene(scene_instance)

# Converts a 2D position to degrees around the center of the screen
func pos2deg(pos: Vector2) -> int:
	var center = get_viewport().get_size() / 2
	return int(rad2deg(center.angle_to_point(pos)))

# Sorts events in a deterministic way based on their characteristics,
# falling back to each field in turn.
func _event_sorter(a: Dictionary, b: Dictionary) -> bool:
	# Sort by the time primarially
	if a["time"] == b["time"]:
		# Then sort by the ID
		if a["id"] == b["id"]:
			# Then sort by action name
			if a["action"] == b["action"]:
				# Finally if everything else was the same, sort by payload hash
				return a["payload"].hash() < b["payload"].hash()
			else:
				return a["action"] < b["action"]
		else:
			return a["id"] < b["id"]
	else:
		return a["time"] < b["time"]
