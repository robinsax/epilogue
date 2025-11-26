class_name PortableSolarItem extends Item

@export var energy_gain_rate: float = 0.5

func update_as_attached(character: RobotBipedCharacter, delta: float):
	character.energy = min(character.energy + (energy_gain_rate * delta), character.initial_energy)
