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
		"rifle_holder": 0.05,
		"buttpack": 0.05,
		"defender": 0.05
	},
	"mechanical": {
		"duct_tape": 0.2,
		"wrench": 0.2,
		"battery": 0.2,
		"utility_belt": 0.1,
		"backpack": 0.01,
		"big_vest": 0.1,
		"gas_can": 0.1
	},
	"survivor": {
		"utility_belt": 0.1,
		"gas_can": 0.05,
		"controller": 0.05,
		"duct_tape": 0.2,
		"compass": 0.2,
		"wrench": 0.1,
		"backpack": 0.1,
		"big_vest": 0.1,
		"battery": 0.1,
		"defender": 0.05,
		"scabbard": 0.05
	},
	"tech": {
		"shield_gen": 0.05,
		"thermal_scope": 0.05,
		"controller": 0.1,
		"portable_solar": 0.1,
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
	"holster": load("res://items/wearable/holster_item.tscn"),
	"utility_belt": load("res://items/wearable/utility_belt_item.tscn"),
	"backpack": load("res://items/wearable/backpack_item.tscn"),
	"controller": load("res://items/controller_item.tscn"),
	"wrench": load("res://items/wrench_item.tscn"),
	"portable_solar": load("res://items/portable_solar_item.tscn"),
	"shield_gen": load("res://items/shield_generator_item.tscn"),
	"thermal_scope": load("res://items/thermal_scope_item.tscn"),
	"buttpack": load("res://items/wearable/buttpack_item.tscn"),
	"rifle_holder": load("res://items/wearable/rifle_holder_item.tscn"),
	"big_vest": load("res://items/wearable/big_vest_item.tscn"),
	"defender": load("res://items/wearable/defender_item.tscn"),
	"scabbard": load("res://items/wearable/scabbard_item.tscn"),
	"compass": load("res://items/compass_item.tscn"),
	"gas_can": load("res://items/gas_can_item.tscn")
}

static func roll_one(pool_key: String, modifier: float = 1.0) -> Resource:
	var pool: Dictionary = _table[pool_key]
	for item_key in pool.keys():
		if randf() * (1.0 / modifier) < pool[item_key]:
			return _refs[item_key]

	return null
