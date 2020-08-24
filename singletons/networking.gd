extends Node

const PORT: int = 21021

var _upnp: UPNP
var _ip: String setget , get_ip
var _pin: String setget , get_pin

func _ready():
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
	self._ip = self._upnp_open()
	self._pin = self._ip_to_pin(self._ip)
	
	# Dispatch events at the start of the server
	EventHandler.event("start_server", { "ip": self._ip, "pin": self._pin })
	EventHandler.event("connect", {"color": 0, "name": "Nobody"})
	EventHandler.event("set_map_seed", { "seed": randi() })
	
	# Return the pin
	return self._pin

func stop_server():
	if get_tree().is_network_server():
		var err = self._upnp.delete_port_mapping(PORT)
		if err != 0:
			push_error("UPNP delete_port_mapping failed with code: %d" % err)
		get_tree().get_network_peer().close_connection()
		EventHandler.event("stop_server")

# Join a server based on the given pin code
func join_server(pin: String):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(self._pin_to_ip(pin), PORT)
	get_tree().set_network_peer(peer)

func disconnect_server():
	get_tree().get_network_pee().close_connection()

# Open the port using UPNP so the user doesn't have to forward manually
# Returns the external IP of the UPNP device
func _upnp_open() -> String:
	self._upnp = UPNP.new()
	var err = self._upnp.discover() # Use the default settings
	if err != 0:
		push_error("UPNP discover failed with code: %d" % err)
		return ""
	err = self._upnp.add_port_mapping(PORT)
	if err != 0:
		push_error("UPNP add_port_mapping failed with code: %d" % err)
		return ""

	return self._upnp.query_external_address()

# Converts an IP to an 8 digit hex code
func _ip_to_pin(ip: String) -> String:
	var parts: Array = []
	for num in ip.split(".", false):
		parts.push_back(int(num))
	return "%02x%02x-%02x%02x" % parts

# Converts an 8 digit hex code to an IP
func _pin_to_ip(pin: String) -> String:
	pin = pin.replace("-", "")
	var parts: Array = []
	for i in range(0, 8, 2):
		parts.push_back(("0x" + pin.substr(i, 2)).hex_to_int())
	return "%d.%d.%d.%d" % parts

func get_ip() -> String:
	return _ip

func get_pin() -> String:
	return _pin

# === Server Signal Callbacks ===

func _player_connect(id: String):
	pass

func _player_disconnected(id: String):
	pass

# === Client Signal Callbacks ===

func _connected_ok():
	EventHandler.event("connect", {"color": 0, "name": "Nobody"}) # TODO make this configurable
	pass

func _connected_fail():
	pass

func _server_disconnected():
	pass
