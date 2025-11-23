@tool
class_name EnvironmentObjectSource extends Node

@export var placements: int = 10

func generator() -> EnvironmentObjectGenerator:
	return EnvironmentObjectGenerator.new()
