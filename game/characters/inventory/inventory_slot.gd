class_name InventorySlot extends Node3D

@export var size: int = Item.SIZE_SMALL

var item: Item = null

func is_item_compatible(item: Item) -> bool:
	return item.size <= size

func is_available() -> bool:
	return item == null
