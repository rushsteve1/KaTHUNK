extends Node

const PORT: int = 21021

var _ip: String setget , get_ip
var _pin: String setget , get_pin

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

# Hosts a server for others to connect to
# Returns the pin of the external IP of the created server
func start_server(max_players: int) -> String:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT, max_players)
	get_tree().set_network_peer(peer)

	# Open UPNP and get the external IP
	self._ip = "127.0.0.1"
	self._pin = self._ip_to_pin(self._ip)
	
	# Dispatch events at the start of the server
	EventHandler.event("start_server", { "ip": self._ip, "pin": self._pin })
	EventHandler.event("connect", {"color": 0, "name": "Nobody"})
	EventHandler.event("set_map_seed", { "seed": randi() })
	
	# Return the pin
	return self._pin

# Stop the server which will disconnect all players
func stop_server() -> void:
	if get_tree().is_network_server():
		get_tree().get_network_peer().close_connection()
		EventHandler.event("stop_server")

# Join a server based on the given pin code
func join_server(pin: String) -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(self._pin_to_ip(pin), PORT)
	get_tree().set_network_peer(peer)

func disconnect_server() -> void:
	get_tree().get_network_pee().close_connection()

# Converts an IP to an 8 digit hex code
static func _ip_to_pin(ip: String) -> String:
	var parts: Array = []
	for num in ip.split(".", false):
		parts.push_back(int(num))
	return "%02x%02x-%02x%02x" % parts

# Converts an 8 digit hex code to an IP
static func _pin_to_ip(pin: String) -> String:
	pin = pin.replace("-", "")
	var parts: Array = []
	for i in range(0, 8, 2):
		parts.push_back(("0x" + pin.substr(i, 2)).hex_to_int())
	return "%d.%d.%d.%d" % parts

func get_ip() -> String:
	return _ip

func get_pin() -> String:
	return _pin

# === Server/Other User Signal Callbacks ===

func _player_connect(id: int) -> void:
	EventHandler.send_state(id)

func _player_disconnected(id: int) -> void:
	EventHandler.event("disconnect", {"id": id})

# === Client Signal Callbacks ===

func _connected_ok() -> void:
	EventHandler.event("connect", {"color": 0, "name": "Nobody"}) # TODO make this configurable

func _connected_fail() -> void:
	pass

func _server_disconnected() -> void:
	pass
