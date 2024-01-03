class_name Upgrade
extends RefCounted



enum Type {
	UNLOCK_UPGRADES,
	
	# Firestarter
	HASTE01,
	OUTPUT01,
	COST01,
	UNLOCK_RANDOM_TREE,
}

var type: Type
var key: String
var details := Details.new()
var purchase_limit := 1
var times_purchased := LoudInt.new(0)
var purchased := LoudBool.new(false)
var category: String

var cost: Cost

var thingy_attribute := Thingy.Attribute.NONE
var modifier: LoudFloat
var modifier_add := 0.0
var modifier_multiply := 1.0

var unlocked_tree: up.UpgradeTree.Type



func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	details.name = key.capitalize()
	match type:
		Type.UNLOCK_UPGRADES:
			cost = Cost.new({Currency.Type.GOLD: Value.new(10)})
			details.color = up.upgrade_color
			details.icon = bag.get_resource("Fire")
			unlocked_tree = up.UpgradeTree.Type.FIRESTARTER
		Type.HASTE01:
			details.name = "Haste"
			details.description = "Thingy Duration [b]-%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({Currency.Type.GOLD: Value.new(8)})
			cost.increase_multiplier = 5.0
			thingy_attribute = Thingy.Attribute.DURATION
			purchase_limit = 4
			category = "subtracted"
			modifier_add = 1
		Type.OUTPUT01:
			details.name = "Stranth"
			details.description = "Thingy Output [b]x%s[/b]."
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({Currency.Type.GOLD: Value.new(12)})
			cost.increase_multiplier = 5.0
			thingy_attribute = Thingy.Attribute.OUTPUT
			purchase_limit = 5
			category = "multiplied"
			modifier_multiply = 2
		Type.COST01:
			details.name = "Greed"
			details.description = "Thingy Cost [b]x%s[/b]."
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({Currency.Type.GOLD: Value.new(90)})
			cost.increase_multiplier = 8.0
			thingy_attribute = Thingy.Attribute.COST
			purchase_limit = 3
			category = "multiplied"
			modifier_multiply = 0.75
		Type.UNLOCK_RANDOM_TREE:
			unlocked_tree = up.UpgradeTree.Type.GAMBLIN_MAN
			details.name = "Gamblin' Man"
			details.description = "Unlocks the [b]%s[/b] tree." % details.name
			details.icon = bag.get_resource("Coin Hand")
			cost = Cost.new({Currency.Type.GOLD: Value.new(1000)})
	match category:
		"added", "subtracted":
			modifier = LoudFloat.new(0)
		"multiplied", "divided":
			modifier = LoudFloat.new(1)
	times_purchased.changed.connect(times_purchased_changed)
	times_purchased.increased.connect(times_purchased_increased)
	if not details.color:
		details.color = gv.get_random_nondark_color()
	if modifier:
		modifier.changed.connect(modifier_changed)



# - Signals


func times_purchased_changed() -> void:
	if times_purchased.less(purchase_limit):
		purchased.set_to(false)
	else:
		purchased.set_to(true)
	if times_purchased.equal(0):
		modifier.reset()

func times_purchased_increased() -> void:
	if modifier:
		modifier.add(modifier_add)
		modifier.multiply(modifier_multiply)
	else:
		apply()


func modifier_changed() -> void:
	if times_purchased.equal(0):
		remove()
	else:
		apply()


func remove() -> void:
	if thingy_attribute != Thingy.Attribute.NONE:
		match thingy_attribute:
			Thingy.Attribute.DURATION:
				th.duration.remove_change(category, self)
			Thingy.Attribute.OUTPUT:
				th.output.remove_change(category, self)
			Thingy.Attribute.COST:
				for cur in th.cost.amount:
					th.cost.amount[cur].remove_change(category, self)
	elif unlocked_tree != up.UpgradeTree.Type.NONE:
		up.upgrade_trees[unlocked_tree].unlocked.set_to(false)



func apply() -> void:
	if thingy_attribute != Thingy.Attribute.NONE:
		match thingy_attribute:
			Thingy.Attribute.DURATION:
				th.duration.edit_change(category, self, modifier.get_value())
			Thingy.Attribute.OUTPUT:
				th.output.edit_change(category, self, modifier.get_value())
			Thingy.Attribute.COST:
				for cur in th.cost.amount:
					th.cost.amount[cur].edit_change(category, self, modifier.get_value())
	elif unlocked_tree != up.UpgradeTree.Type.NONE:
		up.upgrade_trees[unlocked_tree].unlocked.set_to(true)



# - Action


func purchase() -> void:
	cost.spend()
	times_purchased.add(1)
	if times_purchased.equal(purchase_limit):
		return
	
	cost.increase()


func reset() -> void:
	times_purchased.reset()



# - Get


func can_afford() -> bool:
	return cost.affordable.is_true() or gv.dev_mode


func can_purchase() -> bool:
	return purchased.is_false() and can_afford()


func get_description() -> String:
	if modifier:
		if times_purchased.equal(0):
			if thingy_attribute == Thingy.Attribute.DURATION:
				return details.description % tp.quick_parse(
					(modifier.get_value() + modifier_add) * modifier_multiply,
					false
				)
			return details.description % Big.get_float_text(
				(modifier.get_value() + modifier_add) * modifier_multiply
			)
		if times_purchased.less(purchase_limit):
			var text = details.description % "%s -> %s"
			if thingy_attribute == Thingy.Attribute.DURATION:
				return text % [
					tp.quick_parse(modifier.get_value(), true),
					tp.quick_parse(
						(modifier.get_value() + modifier_add) * modifier_multiply,
						true
					)
				]
			return text % [
				modifier.get_text(),
				Big.get_float_text(
					(modifier.get_value() + modifier_add) * modifier_multiply
				)
			]
		if thingy_attribute == Thingy.Attribute.DURATION:
			return details.description % tp.quick_parse(modifier.get_value(), false)
		return details.description % modifier.get_text()
	return details.description
