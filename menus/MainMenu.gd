extends CenterContainer

func _ready():
	pass

func _on_HostButton_pressed():
	Networking.start_server(10) # TODO make max_players configurable
	get_tree().change_scene("res://menus/Lobby.tscn")
