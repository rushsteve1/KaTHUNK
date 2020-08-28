extends CenterContainer

onready var pinlabel = $HBoxContainer/InfoPanel/VBoxContainer/PinLabel
onready var startbutton = $HBoxContainer/InfoPanel/VBoxContainer/StartButton
onready var playerlist = $HBoxContainer/PlayerPanel/PlayerList

func _ready() -> void:
	self.pinlabel.set_text(Networking.get_pin())
	self.startbutton.set_disabled(not get_tree().is_network_server())
	
	self._player_connected(get_tree().get_network_unique_id())
	get_tree().connect("network_peer_connected", self, "_player_connected")

func _on_StartButton_pressed() -> void:
	EventHandler.event("game_start")

func _player_connected(id: int):
	self.playerlist.clear()
	var players = EventHandler.get_players()
	Debug.set_watched("Players", players)
	for id in players:
		print_debug(players[id]["name"])
		# self.playerlist.add_item()
