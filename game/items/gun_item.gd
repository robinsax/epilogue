class_name GunItem extends Item

@export var character_low_ready_anchor: String = ""
@export var character_aim_anchor: String = ""
@export var biped_aim_radius: float = 0.1
@export var biped_body_rotation: float = 0.2
@export var biped_dominant_shoulder_push: float = 0.3

var grip: Node3D = null
var magazine_well: InventorySlot = null
var offhand_grip: Node3D = null
var muzzle: Node3D = null
var aim_anchor: Node3D = null

func _ready():
	super._ready()
	grip = $Grip
	offhand_grip = $OffhandGrip
	muzzle = $Muzzle
	aim_anchor = $AimAnchor
	magazine_well = inventory.get_slot("magwell")

func get_hold_position():
	return grip.position
