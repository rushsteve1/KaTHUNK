extends CenterContainer

func _ready():
	var label = $HBoxContainer/PanelContainer/VBoxContainer/PinLabel
	label.set_text(Networking.get_pin)
	var button = $HBoxContainer/PanelContainer/VBoxContainer/StartButton
	button.set_disabled(!get_tree().is_network_server())



func _on_StartButton_pressed():
	EventHandler.event("game_start")
