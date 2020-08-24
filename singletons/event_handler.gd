extends Node

var state: Dictionary = {}
var event_queue: Array = []
var event_history: Array = []

# Processes the event queue every frame using the reducer
func _process(delta: float):
	# Sort the events according to the sorting function
	event_queue.sort_custom(self, "_event_sorter")
	# Go through them and run the reducer
	for event in event_queue:
		self.state = self._reducer(state, event)

# Add an event to the event queue which will be processed by the reducer
# Adds in the unique ID of the user and the time of the call as well
func event(action: String, payload: Dictionary = {}):
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
remotesync func _rpc_event_push(event: Dictionary):
	# Add to the event queue
	self.event_queue.push_back(event)

# TODO possibly replace string actions with an Enum?

# The state reducer that takes an event and modifies the state based on it.
# This function is modeled like a pure function, though will cause effects
# by modifying the various aspects of the running game to match the state.
func _reducer(state: Dictionary, event: Dictionary) -> Dictionary:
	# The reducer is effectively a huge match block
	match event:
		{"action": "connect", "id": var id, "payload": var payload}:
			state["players"][id] = payload
		{"action": "set_map_seed", "payload": { "seed": var map_seed}}:
			state["map_seed"] = map_seed
		{"action": "game_start"}:
			for id in state["players"]:
				state["players"][id]["speed"] = 0
				state["players"][id]["pos"] = Vector2() # TODO replace this with a random location
				state["players"][id]["chassis_rot"] = 0
				state["players"][id]["barrel_rot"] = 0

			var map = load("res://map/MainMap.gd").instance()
			map.start_game(state["map_seed"], state["players"])
			get_tree().change_scene_to(map)
		{"action": "increase_speed", "id": var id}:
			state["players"]
		_:
			push_warning("Unknown event")

	# Finally return the possibly modified state
	return state

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
