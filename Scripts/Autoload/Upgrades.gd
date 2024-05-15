extends Node



signal upgrades_initialized
signal container_loaded

@export var upgrades := {}
@export var upgrade_trees_by_name := {}

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
	for key in Upgrade.data.keys():
		upgrades[key] = await Upgrade.new(key)
	upgrades_initialized.emit()



#region Action


func flash_vico(key: String) -> void:
	var color = get_color(key)
	gv.flash(get_upgrade(key).vico, color)


#endregion



# - Get


func get_upgrade(key: String) -> Upgrade:
	return upgrades[key]


func get_details(key: String) -> Details:
	return get_upgrade(key).details


func get_color(key: String) -> Color:
	return get_upgrade(key).details.get_color()


func tree_exists_and_is_unlocked(val: int) -> bool:
	return val in upgrade_trees.keys() and is_upgrade_tree_unlocked(val)


func get_upgrade_tree(type: UpgradeTree.Type) -> UpgradeTree:
	return upgrade_trees[type]


func is_purchased(key: String) -> bool:
	return get_upgrade(key).purchased.is_true()


func is_upgrade_tree_unlocked(type: UpgradeTree.Type) -> bool:
	return get_upgrade_tree(type).unlocked.get_value()
