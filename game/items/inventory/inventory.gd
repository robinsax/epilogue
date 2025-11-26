class_name Inventory extends Node

var update_culled: bool

var _owner: Node3D
var _slots: Array[InventorySlot]

func _ready():
	_owner = get_parent()

	_discover_slots(owner)

func _discover_slots(current: Node):
	if current is InventorySlot:
		_slots.push_back(current)
		current.inventory = self

	for child in current.get_children():
		_discover_slots(child)

func _process(delta):
	pass

func all_slots(include_requires_inventory_mode: bool = false) -> Array[InventorySlot]:
	var all: Array[InventorySlot] = []
	for slot in _slots:
		if slot.access_requires_inventory_mode and not include_requires_inventory_mode:
			continue

		all.push_back(slot)
		if slot.item != null:
			all.append_array(slot.item.inventory.all_slots(include_requires_inventory_mode))

	return all

func get_slot(key: String) -> InventorySlot:
	for slot in all_slots(true):
		if slot.key == key:
			return slot

	return null

func get_slot_with_item(item: Item) -> InventorySlot:
	for slot in all_slots(true):
		if slot.item == item:
			return slot

	return null

class RankedSlot:
	var rank: int
	var slot: InventorySlot

func get_ranked_compatible_slots_for(item: Item) -> Array[InventorySlot]:
	var ranked: Array[RankedSlot] = []
	var insert = func (slot: InventorySlot):
		var instance = RankedSlot.new()
		instance.rank = slot.compatibility_rank_for(item)
		instance.slot = slot

		for i in ranked.size():
			if ranked[i].rank < instance.rank:
				ranked.insert(i, instance)
				return

		ranked.push_back(instance)

	for slot in all_slots():
		if not slot.is_item_compatible(item):
			continue

		insert.call(slot)

	var slots: Array[InventorySlot] = []
	for instance in ranked:
		slots.push_back(instance.slot)

	return slots

func get_available_slot_for(item: Item) -> InventorySlot:
	var ranked_slots = get_ranked_compatible_slots_for(item)
	for slot in ranked_slots:
		if slot.is_available():
			return slot

	return null

func get_attachment_string(slot: InventorySlot) -> String:
	var owner_type = "i"
	var owner_name = _owner.name
	if _owner is Character:
		owner_type = "c"
		owner_name = _owner.get_parent().name

	return owner_type + "/" + owner_name + "/" + slot.key

func get_slot_with_item_tag(tag: String, exclude: Array[InventorySlot] = []) -> InventorySlot:
	for slot in all_slots():
		if exclude and slot in exclude:
			continue

		if slot.item != null and tag in slot.item.tags:
			return slot

	return null

func get_slot_with_item_tag_best_hand_value(tag: String) -> InventorySlot:
	var best: InventorySlot = null
	for slot in all_slots():
		if slot.item == null or not tag in slot.item.tags:
			continue

		var is_better = (
			best == null or
			(slot.item.rarity > best.item.rarity and slot.item.hand_value > best.item.hand_value)
		)
		if is_better:
			best = slot

	return best
