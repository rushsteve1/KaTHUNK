extends KinematicBody2D

enum TankColor {
	BEIGE,
	BLACK,
	BLUE,
	GREEN,
	RED
}

const SPRITE_DIR: String = "res://player/sprites/"
const SPRITE_PATHS: Dictionary = {
	TankColor.BEIGE: ["tank_beige.png", "barrel_beige.png"],
	TankColor.BLACK: ["tank_black.png", "barrel_black.png"],
	TankColor.BLUE: ["tank_blue.png", "barrel_blue.png"],
	TankColor.GREEN: ["tank_green.png", "barrel_green.png"],
	TankColor.RED: ["tank_red.png", "barrel_red.png"],
}

export(TankColor) var _color: int = TankColor.BEIGE setget set_color

var _speed: int = 0 setget _set_speed, _get_speed

func _ready():
	self.set_color(self._color)

func set_color(color: int):
	var paths = SPRITE_PATHS[color]
	$Chassis.set_texture(load(SPRITE_DIR + paths[0]))
	$Barrel.set_texture(load(SPRITE_DIR + paths[1]))

func set_barrel_rotation(degrees: int):
	$Barrel.set_rotation(degrees)

func get_barrel_rotation() -> int:
	return $Barrel.get_rotation()

func _set_speed(speed: int):
	_speed = int(clamp(speed, -1.0, 1.0))

func _get_speed() -> int:
	return _speed
