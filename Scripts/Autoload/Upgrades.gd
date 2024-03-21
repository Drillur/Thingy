extends Node



signal upgrades_initialized
signal container_loaded

@export var upgrades_by_name := {}
@export var upgrade_trees_by_name := {}

var upgrades := {}
var upgrade_trees := {}
var upgrade_color := Color(0.075, 0.808, 0.467)
var container: UpgradeContainer:
	set(val):
		container = val
		container_loaded.emit()



func _ready() -> void:
	for upgrade_tree in UpgradeTree.Type.values():
		if upgrade_tree == UpgradeTree.Type.NONE:
			continue
		upgrade_trees[upgrade_tree] = UpgradeTree.new(upgrade_tree)
		upgrade_trees_by_name[upgrade_trees[upgrade_tree].key] = upgrade_trees[upgrade_tree]
	for upgrade_type in Upgrade.Type.values():
		upgrades[upgrade_type] = await Upgrade.new(upgrade_type)
		upgrades_by_name[upgrades[upgrade_type].key] = upgrades[upgrade_type]
	upgrades_initialized.emit()



#region Action


func flash_vico(upgrade_type: Upgrade.Type) -> void:
	var color = get_color(upgrade_type)
	gv.flash(get_upgrade(upgrade_type).vico, color)


#endregion



# - Get


func get_upgrade(upgrade_type: Upgrade.Type) -> Upgrade:
	return upgrades[upgrade_type]


func get_color(upgrade_type: Upgrade.Type) -> Color:
	return get_upgrade(upgrade_type).details.get_color()


func tree_exists_and_is_unlocked(val: int) -> bool:
	return val in upgrade_trees.keys() and is_upgrade_tree_unlocked(val)


func get_upgrade_tree(type: UpgradeTree.Type) -> UpgradeTree:
	return upgrade_trees[type]


func is_purchased(upgrade_type: Upgrade.Type) -> bool:
	return get_upgrade(upgrade_type).purchased.is_true()


func is_upgrade_tree_unlocked(type: UpgradeTree.Type) -> bool:
	return get_upgrade_tree(type).unlocked.get_value()
