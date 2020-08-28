extends CenterContainer

onready var popup = $AcceptDialog
onready var lineedit = $AcceptDialog/LineEdit

func _ready() -> void:
	self.popup.register_text_enter(self.lineedit)
	self.popup.set_text("Join a server with a pin code")

func _on_HostButton_pressed() -> void:
	Networking.start_server(10) # TODO make max_players configurable
	get_tree().change_scene("res://menus/Lobby.tscn")

func _on_JoinButton_pressed():
	self.popup.popup_centered()

func _on_AcceptDialog_confirmed():
	Networking.join_server(.get_text())
