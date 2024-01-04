extends Node



class UpgradeTree:
	
	enum Type {
		NONE,
		GAMBLIN_MAN,
		FIRESTARTER,
		VOYAGER,
	}
	
	var type: Type
	var key: String
	var unlocked := LoudBool.new(false)
	
	
	func _init(_type: Type) -> void:
		type = _type
		key = Type.keys()[type]
		unlocked.changed.connect(unlocked_changed)
	
	
	func unlocked_changed() -> void:
		up.container.tab_container.set_tab_hidden(int(type) - 1, not unlocked.get_value())

signal upgrades_initialized

var upgrades := {}
var upgrade_color := Color(0.075, 0.808, 0.467)
var upgrade_trees := {}
var container: UpgradeContainer



func _ready() -> void:
	for upgrade_type in Upgrade.Type.values():
		upgrades[upgrade_type] = await Upgrade.new(upgrade_type)
	for upgrade_tree in UpgradeTree.Type.values():
		if upgrade_tree == UpgradeTree.Type.NONE:
			continue
		upgrade_trees[upgrade_tree] = UpgradeTree.new(upgrade_tree)
	upgrades_initialized.emit()



# - Action



# - Get


func get_upgrade(upgrade_type: Upgrade.Type) -> Upgrade:
	return upgrades[upgrade_type]


func is_purchased(upgrade_type: Upgrade.Type) -> bool:
	return get_upgrade(upgrade_type).purchased.is_true()
