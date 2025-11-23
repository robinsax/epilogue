@tool
class_name LootTable extends Object

static var _table: Dictionary = {
	"military": {
		"liteplate_vest": 0.05,
		"holster": 0.05,
		"enforcer_handgun": 0.1,
		"handgun_magazine": 0.2,
		"dmr_magazine": 0.1,
		"mainline_dmr": 0.05,
		"battery": 0.05,
		"duct_tape": 0.05
	},
	"mechanical": {
		"duct_tape": 0.5,
		"battery": 0.5
	}
}

static var _refs: Dictionary = {
	"enforcer_handgun": load("res://items/guns/enforcer_handgun_item.tscn"),
	"handgun_magazine": load("res://items/guns/handgun_magazine_item.tscn"),
	"dmr_magazine": load("res://items/guns/dmr_magazine_item.tscn"),
	"mainline_dmr": load("res://items/guns/mainline_dmr_item.tscn"),
	"battery": load("res://items/battery_item.tscn"),
	"duct_tape": load("res://items/duct_tape_item.tscn"),
	"liteplate_vest": load("res://items/wearable/liteplate_item.tscn"),
	"holster": load("res://items/wearable/holster_item.tscn")
}

static func roll_one(pool_key: String, modifier: float = 1.0) -> Resource:
	var pool: Dictionary = _table[pool_key]
	for item_key in pool.keys():
		if randf() * modifier < pool[item_key]:
			return _refs[item_key]

	return null
