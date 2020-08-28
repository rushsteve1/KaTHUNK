extends Node2D

export(OpenSimplexNoise) var _noise: OpenSimplexNoise
export(int) var _octaves: int = 4
export(float) var _period: float = 20.0
export(float) var _persistence: float = 0.8

const ZHEIGHT: float = 15.0
const PLAYER: PackedScene = preload("res://player/Player.tscn")

var _players_dict: Dictionary = {}
var _noise_seed: int

onready var _players = $Players

func _ready():
	for id in self._players_dict:
		var player = self._players_dict[id]
		self._add_player(id, player)
	self._generate_map()

func init(noise_seed: int, players: Dictionary) -> void:
	self._noise_seed = noise_seed
	self._players_dict = players

func player_callv(id: int, name: String, args: Array = []):
	return self._players.get_node(str(id)).callv(name, args)

func _generate_noise(noise_seed: int) -> void:
	self._noise = OpenSimplexNoise.new()
	self._noise.set_seed(noise_seed)
	self._noise.set_octaves(self._octaves)
	self._noise.set_period(self._period)
	self._noise.set_persistence(self._persistence)

# Generates a map based on the given seed using the noise 
func _generate_map() -> void:
	var ground = $GeneratedMap/Ground
	var obstacles = $GeneratedMap/Obstacles
	ground.clear()
	obstacles.clear()
	# self._generate_noise(self._noise_seed)
	for x in range(-10, 10):
		for y in range(-10, 10):
			ground.set_cell(x, y, int(abs(x+y)) % 3) # creates a pattern

func _add_player(id: int, player: Dictionary) -> void:
	var new_player = PLAYER.instance()
	new_player.set_name(str(id))
	new_player.set_color(player["color"])
	new_player.set_position(player["pos"])
	self._players.add_child(new_player)
