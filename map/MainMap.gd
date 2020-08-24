extends Node2D

export(OpenSimplexNoise) var _noise: OpenSimplexNoise
export(int) var _octaves: int = 4
export(float) var _period: float = 20.0
export(float) var _persistence: float = 0.8

const ZHEIGHT: float = 15.0

const PLAYER: PackedScene = preload("res://player/Player.tscn")

onready var _players = $Players

func _ready():
	self._generate_map()

func start_game(noise_seed: int, players: Dictionary):
	for id in players:
		var player = players[id]
		self._add_player(id, player)

func set_player_position(id: int, position: Vector2):
	self._players.find_node(str(id)).set_position(position)

func _generate_noise(noise_seed: int):
	self._noise = OpenSimplexNoise.new()
	self._noise.set_seed(noise_seed)
	self._noise.set_octaves(self._octaves)
	self._noise.set_period(self._period)
	self._noise.set_persistence(self._persistence)

# Generates a map based on the given seed using the noise 
func _generate_map():
	var ground = $GeneratedMap/Ground
	var obstacles = $GeneratedMap/Obstacles
	ground.clear()
	obstacles.clear()

func _add_player(id: int, player: Dictionary):
	var new_player = PLAYER.instance()
	new_player.set_name(id)
	new_player.set_color(player["color"])
	new_player.set_position(player["pos"])
	self._players.add_child(new_player)
