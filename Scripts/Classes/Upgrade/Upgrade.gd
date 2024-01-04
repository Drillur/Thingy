class_name Upgrade
extends RefCounted



enum Type {
	UNLOCK_UPGRADES,
	
	# Firestarter
	HASTE01,
	OUTPUT01,
	COST01,
	UNLOCK_RANDOM_TREE,
	UNLOCK_XP,
	UNLOCK_CRIT,
	CRIT01,
	CRITS_GIVE_GOLD,
	TOTAL_OUTPUT_RANGE01,
	CURRENT_DURATION_RANGE01,
}

var type: Type
var key: String
var details := Details.new()
var purchase_limit := 1
var times_purchased := LoudInt.new(0)
var purchased := LoudBool.new(false)
var category: String

var unlocked := LoudBool.new(true)
var required_upgrade: Upgrade.Type:
	set(val):
		required_upgrade = val
		unlocked.set_default_value(false)
		unlocked.reset()
		await up.upgrades_initialized
		up.get_upgrade(required_upgrade).purchased.became_true.connect(
			unlocked.set_true
		)
		up.get_upgrade(required_upgrade).purchased.became_false.connect(
			unlocked.set_false
		)

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
			cost = Cost.new({Currency.Type.WILL: Value.new(5)})
			details.color = up.upgrade_color
			details.icon = bag.get_resource("upgrades")
			unlocked_tree = up.UpgradeTree.Type.FIRESTARTER
		Type.HASTE01:
			details.name = "Urgency"
			details.description = "Thingy duration [b]-%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({Currency.Type.WILL: Value.new(10)})
			thingy_attribute = Thingy.Attribute.DURATION
			category = "subtracted"
			modifier_add = 1.0
		Type.OUTPUT01:
			details.name = "Boxer"
			details.description = "Thingy output [b]+%s[/b]."
			details.color = wa.get_color(Currency.Type.WILL)
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({Currency.Type.WILL: Value.new(20)})
			thingy_attribute = Thingy.Attribute.OUTPUT
			category = "added"
			modifier_add = 1.0
		Type.COST01:
			details.name = "Greed"
			details.description = "Thingy cost [b]x%s[/b]."
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({Currency.Type.WILL: Value.new(90)})
			cost.increase_multiplier = 8.0
			thingy_attribute = Thingy.Attribute.COST
			purchase_limit = 3
			category = "multiplied"
			modifier_multiply = 0.75
		Type.UNLOCK_RANDOM_TREE:
			required_upgrade = Type.UNLOCK_CRIT
			unlocked_tree = up.UpgradeTree.Type.GAMBLIN_MAN
			details.name = "Gamblin' Man"
			details.description = "Unlocks the [b]%s[/b] tree." % details.name
			details.icon = bag.get_resource("Coin Hand")
			cost = Cost.new({Currency.Type.WILL: Value.new(50)})
		Type.UNLOCK_XP:
			details.name = "Adventurer"
			details.description = "Unlocks %s." % wa.get_details(
				Currency.Type.XP
			).icon_and_colored_name
			details.color = wa.get_color(Currency.Type.XP)
			details.icon = bag.get_resource("Star")
			cost = Cost.new({Currency.Type.WILL: Value.new(50)})
		Type.UNLOCK_CRIT:
			details.name = "Low Roller"
			details.description = "Thingy crit chance [b]+%s%%[/b]."
			details.icon = bag.get_resource("Dice")
			cost = Cost.new({Currency.Type.WILL: Value.new(45)})
			thingy_attribute = Thingy.Attribute.CRIT
			category = "added"
			modifier_add = 5.0
		Type.CRITS_GIVE_GOLD:
			details.name = "Cat Burglar"
			details.description = "All crits produce up to %s " + wa.get_details(
				Currency.Type.COIN
			).icon_and_colored_name + "."
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({Currency.Type.WILL: Value.new(100)})
			cost.increase_multiplier = 10.0
			purchase_limit = 3
			modifier_add = 1.0
			thingy_attribute = Thingy.Attribute.TOTAL_COIN_FROM_CRIT
			category = "added"
		Type.CRIT01:
			details.name = "Die, Son!"
			details.description = "Thingy crit chance [b]+%s%%[/b]."
			details.icon = bag.get_resource("Dice")
			cost = Cost.new({Currency.Type.COIN: Value.new(3)})
			cost.increase_multiplier = 3.0
			purchase_limit = 5
			modifier_add = 1.0
			thingy_attribute = Thingy.Attribute.CRIT
			category = "added"
		Type.TOTAL_OUTPUT_RANGE01:
			details.name = "Beg"
			details.description = "Thingy max output [b]+%s[/b]."
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({Currency.Type.COIN: Value.new(5)})
			cost.increase_multiplier = 3.0
			purchase_limit = 3
			modifier_add = 1.0
			thingy_attribute = Thingy.Attribute.TOTAL_OUTPUT_RANGE
			category = "added"
		Type.CURRENT_DURATION_RANGE01:
			details.name = "Time Bandit"
			details.description = "Thingy min duration [b]x%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({Currency.Type.COIN: Value.new(25)})
			cost.increase_multiplier = 5
			purchase_limit = 5
			modifier_multiply = 0.9
			thingy_attribute = Thingy.Attribute.CURRENT_DURATION_RANGE
			category = "multiplied"
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



# - Action


func purchase() -> void:
	cost.spend()
	times_purchased.add(1)
	if times_purchased.equal(purchase_limit):
		return
	
	cost.increase()


func reset() -> void:
	remove()
	times_purchased.reset()


func remove() -> void:
	match type:
		Type.UNLOCK_XP:
			th.xp_unlocked.set_to(false)
		_:
			if thingy_attribute != Thingy.Attribute.NONE:
				match thingy_attribute:
					Thingy.Attribute.DURATION:
						th.duration_range.current.remove_change(category, self)
						th.duration_range.total.remove_change(category, self)
					Thingy.Attribute.CURRENT_DURATION_RANGE:
						th.duration_range.current.remove_change(category, self)
					Thingy.Attribute.OUTPUT:
						th.output_range.current.remove_change(category, self)
						th.output_range.total.remove_change(category, self)
					Thingy.Attribute.TOTAL_OUTPUT_RANGE:
						th.output_range.total.remove_change(category, self)
					Thingy.Attribute.CRIT:
						th.crit_chance.remove_change(category, self)
					Thingy.Attribute.TOTAL_COIN_FROM_CRIT:
						th.crit_coin_output.total.remove_change(category, self)
					Thingy.Attribute.COST:
						for cur in th.cost.amount:
							th.cost.amount[cur].remove_change(category, self)
			elif unlocked_tree != up.UpgradeTree.Type.NONE:
				up.upgrade_trees[unlocked_tree].unlocked.set_to(false)


func apply() -> void:
	match type:
		Type.UNLOCK_XP:
			th.xp_unlocked.set_to(true)
		_:
			if thingy_attribute != Thingy.Attribute.NONE:
				match thingy_attribute:
					Thingy.Attribute.DURATION:
						th.duration_range.current.edit_change(category, self, modifier.get_value())
						th.duration_range.total.edit_change(category, self, modifier.get_value())
					Thingy.Attribute.CURRENT_DURATION_RANGE:
						th.duration_range.current.edit_change(category, self, modifier.get_value())
					Thingy.Attribute.OUTPUT:
						th.output_range.current.edit_change(category, self, modifier.get_value())
						th.output_range.total.edit_change(category, self, modifier.get_value())
					Thingy.Attribute.TOTAL_OUTPUT_RANGE:
						th.output_range.total.edit_change(category, self, modifier.get_value())
					Thingy.Attribute.CRIT:
						th.crit_chance.edit_change(category, self, modifier.get_value())
					Thingy.Attribute.TOTAL_COIN_FROM_CRIT:
						th.crit_coin_output.total.edit_change(category, self, modifier.get_value())
					Thingy.Attribute.COST:
						for cur in th.cost.amount:
							th.cost.amount[cur].edit_change(category, self, modifier.get_value())
			elif unlocked_tree != up.UpgradeTree.Type.NONE:
				up.upgrade_trees[unlocked_tree].unlocked.set_to(true)



# - Get


func can_afford() -> bool:
	return cost.affordable.is_true() or gv.dev_mode


func can_purchase() -> bool:
	return unlocked.is_true() and purchased.is_false() and can_afford()


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
			if thingy_attribute != Thingy.Attribute.NONE:
				match thingy_attribute:
					Thingy.Attribute.CRIT:
						text = details.description % "%s -> %s%"
					Thingy.Attribute.DURATION:
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
