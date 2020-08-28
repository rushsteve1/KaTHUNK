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

const SPEED_MULT: int = 8000
const ANG_SPEED_MULT: int = 1

export(TankColor) var _color: int = TankColor.BEIGE setget set_color

var _speed: int = 0 setget set_speed, get_speed
var _ang_speed: int = 0

func _ready() -> void:
	self.set_color(self._color)
	$Camera2D.current = self._is_current()

func _physics_process(delta: float) -> void:
	self.set_rotation(self.get_rotation() + (self._ang_speed * ANG_SPEED_MULT * delta))
	var vel = Vector2(0, -self._speed).rotated(self.get_rotation()) * SPEED_MULT * delta
	self.move_and_slide(vel)

	if self._is_current():
		Debug.set_watched("Tank Position", self.get_position())

func set_color(color: int) -> void:
	var paths = SPRITE_PATHS[color]
	$Chassis.set_texture(load(SPRITE_DIR + paths[0]))
	$Barrel.set_texture(load(SPRITE_DIR + paths[1]))

func set_barrel_rotation(degrees: int) -> void:
	$Barrel.set_rotation(degrees)

func get_barrel_rotation() -> int:
	return $Barrel.get_rotation()

func set_speed(speed: int) -> void:
	_speed = int(clamp(speed, -1.0, 1.0))

func get_speed() -> int:
	return _speed

func start_rotating_chassis(dir: String) -> void:
	if dir == "left":
		self._ang_speed = -1
	elif dir == "right":
		self._ang_speed = 1

func stop_rotating_chassis() -> void:
	self._ang_speed = 0
	EventHandler.event("sync_rotation", { "deg": self.get_rotation() })

func _is_current() -> bool:
	return self.get_name() == str(get_tree().get_network_unique_id())
