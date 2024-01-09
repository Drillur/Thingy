extends Node



class UpgradeTree:
	extends Resource
	
	enum Type {
		NONE,
		FIRESTARTER,
		VOYAGER,
	}
	
	var type: Type
	var key: String
	var unlocked := LoudBool.new(false)
	var details := Details.new()
	
	
	func _init(_type: Type) -> void:
		type = _type
		key = Type.keys()[type]
		unlocked.changed.connect(unlocked_changed)
		details.name = Type.keys()[type].capitalize()
		match type:
			Type.FIRESTARTER:
				details.color = Color(0.89, 0.118, 0.263)
				details.icon = bag.get_resource("Fire")
			Type.VOYAGER:
				details.color = Color(0.118, 0.725, 0.89)
				details.icon = bag.get_resource("Map")
	
	
	func unlocked_changed() -> void:
		up.container.tab_container.set_tab_hidden(int(type) - 1, not unlocked.get_value())

signal upgrades_initialized
signal container_loaded

var upgrades := {}
@export var upgrades_by_name := {}

var upgrade_color := Color(0.075, 0.808, 0.467)
var upgrade_trees := {}
var container: UpgradeContainer:
	set(val):
		container = val
		container_loaded.emit()



func _ready() -> void:
	for upgrade_tree in UpgradeTree.Type.values():
		if upgrade_tree == UpgradeTree.Type.NONE:
			continue
		upgrade_trees[upgrade_tree] = UpgradeTree.new(upgrade_tree)
	for upgrade_type in Upgrade.Type.values():
		upgrades[upgrade_type] = await Upgrade.new(upgrade_type)
		upgrades_by_name[upgrades[upgrade_type].key] = upgrades[upgrade_type]
	upgrades_initialized.emit()



# - Action



# - Get


func get_upgrade(upgrade_type: Upgrade.Type) -> Upgrade:
	return upgrades[upgrade_type]


func tree_exists_and_is_unlocked(val: int) -> bool:
	return val in upgrade_trees.keys() and is_upgrade_tree_unlocked(val)


func get_upgrade_tree(type: UpgradeTree.Type) -> UpgradeTree:
	return upgrade_trees[type]


func is_purchased(upgrade_type: Upgrade.Type) -> bool:
	return get_upgrade(upgrade_type).purchased.is_true()


func is_upgrade_tree_unlocked(type: UpgradeTree.Type) -> bool:
	return get_upgrade_tree(type).unlocked.get_value()
