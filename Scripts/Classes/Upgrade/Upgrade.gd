class_name Upgrade
extends RefCounted



enum Type {
	UNLOCK_UPGRADES,
	HASTE01,
	OUTPUT01,
	COST01,
	XP02,
	UNLOCK_RPG_TREE,
	UNLOCK_XP,
	UNLOCK_CRIT,
	CRIT01,
	CRITS_GIVE_GOLD,
	TOTAL_OUTPUT_RANGE01,
	CURRENT_DURATION_RANGE01,
	TOTAL_XP_GAIN01,
	CURRENT_XP_INCREASE_RANGE01,
	OUTPUT_INCREASE01,
	OUTPUT02,
	XP_GAIN01,
	XP01,
	DURATION01,
	DURATION_INCREASE01,
	CRITS_AFFECT_XP_GAIN,
	CRIT_RANGE01,
	CRITS_AFFECT_COIN_GAIN,
	OUTPUT_INCREASE_RANGE_TOTAL01,
	DURATION02,
	DURATION03,
	OUTPUT03,
	COIN01,
	CRITS_APPLY_TO_DURATION,
	UNLOCK_JUICE,
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
var thingy_attributes_to_edit: Array
var modifier: LoudFloat
var modifier_add := 0.0
var modifier_multiply := 1.0

var unlocked_tree: up.UpgradeTree.Type



func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	details.name = key.capitalize()
	var mod: float
	
	match type:
		Type.UNLOCK_UPGRADES:
			cost = Cost.new({Currency.Type.WILL: Value.new(10)})
			details.color = up.upgrade_color
			details.icon = bag.get_resource("upgrades")
			unlocked_tree = up.UpgradeTree.Type.FIRESTARTER
		Type.HASTE01:
			details.name = "Urgency"
			details.description = "Duration [b]-%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({Currency.Type.WILL: Value.new(10)})
			thingy_attribute = Thingy.Attribute.DURATION_RANGE
			category = "subtracted"
			mod = 1.0
		Type.OUTPUT01:
			details.name = "Boxer"
			details.description = wa.get_details(
				Currency.Type.WILL
			).icon_and_name + " output [b]+%s[/b]."
			details.color = wa.get_color(Currency.Type.WILL)
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({Currency.Type.WILL: Value.new(20)})
			thingy_attribute = Thingy.Attribute.OUTPUT_RANGE
			category = "added"
			mod = 1.0
		Type.COST01:
			details.name = "Greed"
			details.description = "Cost [b]x%s[/b]."
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({Currency.Type.WILL: Value.new(90)})
			cost.increase_multiplier = 8.0
			thingy_attribute = Thingy.Attribute.COST
			purchase_limit = 3
			category = "multiplied"
			mod = 0.75
		Type.UNLOCK_XP:
			details.name = "Adventurer"
			details.description = "Unlocks %s." % wa.get_details(
				Currency.Type.XP
			).icon_and_colored_name
			details.color = wa.get_color(Currency.Type.XP)
			details.icon = bag.get_resource("Star")
			cost = Cost.new({Currency.Type.WILL: Value.new(50)})
		Type.UNLOCK_RPG_TREE:
			required_upgrade = Type.UNLOCK_XP
			unlocked_tree = up.UpgradeTree.Type.VOYAGER
			details.name = "Voyager"
			details.icon = up.get_upgrade_tree(unlocked_tree).details.icon
			cost = Cost.new({
				Currency.Type.WILL: Value.new(100000),
				Currency.Type.COIN: Value.new(250),
			})
		Type.UNLOCK_CRIT:
			details.name = "Low Roller"
			details.description = "Crit chance [b]+%s%%[/b]."
			details.icon = bag.get_resource("Dice")
			cost = Cost.new({Currency.Type.WILL: Value.new(45)})
			thingy_attribute = Thingy.Attribute.CRIT
			category = "added"
			mod = 5.0
		Type.CRITS_GIVE_GOLD:
			required_upgrade = Type.UNLOCK_CRIT
			details.name = "Cat Burglar"
			details.description = "All crits produce up to %s " + wa.get_details(
				Currency.Type.COIN
			).icon_and_colored_name + "."
			details.color = wa.get_color(Currency.Type.COIN)
			details.icon = bag.get_resource("Coin Hand")
			cost = Cost.new({Currency.Type.WILL: Value.new(100)})
			cost.increase_multiplier = 10.0
			purchase_limit = 3
			mod = 1.0
			thingy_attribute = Thingy.Attribute.CRIT_COIN_OUTPUT_TOTAL
			category = "added"
		Type.CRIT01:
			required_upgrade = Type.UNLOCK_CRIT
			details.name = "Die, Son!"
			details.description = "Crit chance [b]+%s%%[/b]."
			details.icon = bag.get_resource("Dice")
			cost = Cost.new({Currency.Type.COIN: Value.new(1)})
			cost.increase_multiplier = 2.0
			purchase_limit = 5
			mod = 1.0
			thingy_attribute = Thingy.Attribute.CRIT
			category = "added"
		Type.TOTAL_OUTPUT_RANGE01:
			required_upgrade = Type.UNLOCK_CRIT
			details.name = "Beg"
			details.description = "Maximum " + wa.get_details(
				Currency.Type.WILL
			).icon_and_name + " output [b]+%s[/b]."
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({Currency.Type.COIN: Value.new(5)})
			cost.increase_multiplier = 3.0
			purchase_limit = 3
			mod = 1.0
			thingy_attribute = Thingy.Attribute.OUTPUT_RANGE_TOTAL
			category = "added"
		Type.CURRENT_DURATION_RANGE01:
			required_upgrade = Type.UNLOCK_CRIT
			details.name = "Time Bandit"
			details.description = "Minimum duration [b]x%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({Currency.Type.COIN: Value.new(3)})
			cost.increase_multiplier = 2
			purchase_limit = 5
			mod = 0.9
			thingy_attribute = Thingy.Attribute.DURATION_RANGE_CURRENT
			category = "multiplied"
		Type.TOTAL_XP_GAIN01:
			required_upgrade = Type.UNLOCK_XP
			details.name = "One-on-One"
			details.description = "Maximum " + (
				wa.get_details(Currency.Type.XP).icon_and_name
			) + " output [b]+%s[/b]."
			details.icon = bag.get_resource("Star")
			cost = Cost.new({
				Currency.Type.XP: Value.new(80),
				Currency.Type.COIN: Value.new(1)
			})
			cost.increase_multiplier = 5
			purchase_limit = 5
			mod = 1
			thingy_attribute = Thingy.Attribute.XP_OUTPUT_TOTAL
			category = "added"
		Type.CURRENT_XP_INCREASE_RANGE01:
			required_upgrade = Type.UNLOCK_XP
			details.name = "Inheritance"
			details.description = "Minimum " + (
				wa.get_details(Currency.Type.XP).icon_and_name
			) + " increase [b]-%s[/b]."
			details.icon = bag.get_resource("Arrow Up Fill")
			cost = Cost.new({
				Currency.Type.SOUL: Value.new(1)
			})
			cost.increase_multiplier = 2
			purchase_limit = 5
			mod = 0.03
			thingy_attribute = Thingy.Attribute.CURRENT_XP_INCREASE_RANGE
			category = "subtracted"
		Type.OUTPUT_INCREASE01:
			required_upgrade = Type.UNLOCK_XP
			details.name = "The Thinker"
			details.description = wa.get_details(
				Currency.Type.WILL
			).icon_and_name + " output increase [b]+%s[/b]."
			details.icon = bag.get_resource("Brain")
			cost = Cost.new({
				Currency.Type.SOUL: Value.new(1)
			})
			cost.increase_multiplier = 2.0
			purchase_limit = 3
			mod = 0.05
			thingy_attribute = Thingy.Attribute.OUTPUT_INCREASE_RANGE
			category = "added"
		Type.OUTPUT02:
			required_upgrade = Type.UNLOCK_XP
			details.name = "Randy Orton"
			details.description = wa.get_details(
				Currency.Type.WILL
			).icon_and_name + " output [b]x%s[/b]."
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({
				Currency.Type.XP: Value.new(30),
				Currency.Type.WILL: Value.new(350)
			})
			cost.increase_multiplier = 4.0
			purchase_limit = 5
			thingy_attribute = Thingy.Attribute.OUTPUT_RANGE
			category = "multiplied"
			mod = 1.5
		Type.XP_GAIN01:
			required_upgrade = Type.UNLOCK_XP
			details.name = "How to Google"
			details.description = wa.get_details(Currency.Type.XP).icon_and_name
			details.description += " output [b]+%s[/b]."
			details.icon = bag.get_resource("Star")
			cost = Cost.new({
				Currency.Type.XP: Value.new(100),
			})
			cost.increase_multiplier = 2.5
			purchase_limit = 3
			thingy_attribute = Thingy.Attribute.XP_OUTPUT
			category = "added"
			mod = 1
		Type.XP01:
			required_upgrade = Type.CRITS_AFFECT_XP_GAIN
			details.name = "Fast Pass"
			details.description = "Total " + (
				wa.get_details(Currency.Type.XP).icon_and_name
			) + " required [b]x%s[/b]."
			details.icon = bag.get_resource("Star")
			cost = Cost.new({
				Currency.Type.XP: Value.new(100),
				Currency.Type.WILL: Value.new(2500),
				Currency.Type.COIN: Value.new(1)
			})
			cost.increase_multiplier = 4.0
			purchase_limit = 3
			thingy_attribute = Thingy.Attribute.XP
			category = "multiplied"
			mod = 0.75
		Type.DURATION01:
			required_upgrade = Type.CRITS_AFFECT_XP_GAIN
			details.name = "Angst"
			details.description = "Duration [b]x%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({
				Currency.Type.XP: Value.new(120),
				Currency.Type.WILL: Value.new(3500),
			})
			cost.increase_multiplier = 4.0
			purchase_limit = 3
			thingy_attribute = Thingy.Attribute.DURATION_RANGE
			category = "multiplied"
			mod = 0.75
		Type.DURATION_INCREASE01:
			required_upgrade = Type.CRIT01
			details.name = "Consideration"
			details.description = "Minimum duration increase [b]-%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({
				Currency.Type.XP: Value.new(50),
				Currency.Type.WILL: Value.new(4000),
				Currency.Type.COIN: Value.new(15),
			})
			cost.increase_multiplier = 2.0
			purchase_limit = 5
			thingy_attribute = Thingy.Attribute.DURATION_INCREASE_RANGE_CURRENT
			category = "subtracted"
			mod = 0.02
		Type.CRITS_AFFECT_XP_GAIN:
			required_upgrade = Type.UNLOCK_CRIT
			details.name = "Rogue and Scholar"
			details.description = "Crits apply to %s output." % (
				wa.get_details(Currency.Type.XP).icon_and_name
			)
			details.icon = bag.get_resource("Star")
			cost = Cost.new({
				Currency.Type.XP: Value.new(250),
				Currency.Type.WILL: Value.new(1000),
			})
		Type.CRITS_AFFECT_COIN_GAIN:
			required_upgrade = Type.CRIT01
			details.name = "Through and Through"
			details.description = "Crits apply to %s output." % (
				wa.get_details(Currency.Type.COIN).icon_and_name
			)
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({
				Currency.Type.COIN: Value.new(25),
			})
		Type.CRIT_RANGE01:
			required_upgrade = Type.CRIT01
			details.name = "Venemous"
			details.description = "Maximum crit multiplier [b]+%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({
				Currency.Type.COIN: Value.new(8),
				Currency.Type.WILL: Value.new(3000),
			})
			cost.increase_multiplier = 2.0
			purchase_limit = 5
			thingy_attribute = Thingy.Attribute.CRIT_RANGE_TOTAL
			category = "added"
			mod = 0.1
		Type.OUTPUT_INCREASE_RANGE_TOTAL01:
			details.name = "Puncture"
			details.description = "Maximum " + wa.get_details(
				Currency.Type.WILL
			).icon_and_name + " output increase [b]+%s[/b]."
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({
				Currency.Type.SOUL: Value.new(1),
			})
			cost.increase_multiplier = 2.0
			purchase_limit = 4
			thingy_attribute = Thingy.Attribute.OUTPUT_INCREASE_RANGE_TOTAL
			category = "added"
			mod = 0.05
		Type.DURATION02:
			required_upgrade = Type.CRIT01
			details.name = "Mood Swing"
			details.description = "Minimum duration [b]-%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({
				Currency.Type.COIN: Value.new(20),
				Currency.Type.WILL: Value.new(20000),
			})
			cost.increase_multiplier = 2.0
			purchase_limit = 3
			thingy_attribute = Thingy.Attribute.DURATION_RANGE_CURRENT
			category = "subtracted"
			mod = 1
		Type.DURATION03:
			details.name = "[i]Rapido![/i]"
			details.description = "Duration [b]x%s[/b]."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({
				Currency.Type.SOUL: Value.new(1),
			})
			cost.increase_multiplier = 3.0
			purchase_limit = 2
			thingy_attribute = Thingy.Attribute.DURATION_RANGE
			category = "multiplied"
			mod = 0.5
		Type.OUTPUT03:
			required_upgrade = Type.OUTPUT02
			details.name = "Batter"
			details.description = wa.get_details(
				Currency.Type.WILL
			).icon_and_name + " output [b]x%s[/b]."
			details.icon = bag.get_resource("Boxing")
			cost = Cost.new({
				Currency.Type.WILL: Value.new(10000),
			})
			cost.increase_multiplier = 4.0
			purchase_limit = 3
			thingy_attribute = Thingy.Attribute.OUTPUT_RANGE
			category = "multiplied"
			mod = 1.5
		Type.COIN01:
			required_upgrade = Type.CRITS_GIVE_GOLD
			details.name = "Fiscal"
			details.description = wa.get_details(
				Currency.Type.COIN
			).icon_and_name + " output [b]+%s[/b]."
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({
				Currency.Type.WILL: Value.new(50000),
			})
			thingy_attribute = Thingy.Attribute.CRIT_COIN_OUTPUT
			category = "added"
			mod = 1
		Type.CRITS_APPLY_TO_DURATION:
			required_upgrade = Type.CRITS_AFFECT_COIN_GAIN
			details.name = "Theif's Gait"
			details.description = "Crits apply to duration."
			details.icon = bag.get_resource("Speed")
			cost = Cost.new({
				Currency.Type.COIN: Value.new(100),
			})
		Type.UNLOCK_JUICE:
			details.name = "Unlock Juice"
			details.description = "Thingies may produce and consume %s to become [i][wave amp=20 freq=2]juiced![/wave][/i], reducing duration and increasing primary output. If none is available to drink, they will produce it." % (
				wa.get_details(Currency.Type.JUICE).icon_and_name
			)
			details.icon = bag.get_resource("Juice")
			details.color = wa.get_color(Currency.Type.JUICE)
			cost = Cost.new({
				Currency.Type.SOUL: Value.new("1"),
			})
		Type.XP02:
			required_upgrade = Type.XP_GAIN01
			details.name = "Fiscal"
			details.description = wa.get_details(
				Currency.Type.XP
			).icon_and_name + " output [b]x%s[/b]."
			details.icon = bag.get_resource("Coin")
			cost = Cost.new({
				Currency.Type.WILL: Value.new(20000),
			})
			cost.increase_multiplier = 4.0
			purchase_limit = 3
			thingy_attribute = Thingy.Attribute.XP_OUTPUT
			category = "multiplied"
			mod = 1.5
	
	match thingy_attribute:
		Thingy.Attribute.XP:
			thingy_attributes_to_edit.append(th.xp_multiplier)
			details.color = wa.get_color(Currency.Type.XP)
		Thingy.Attribute.XP_OUTPUT_TOTAL:
			thingy_attributes_to_edit.append(th.xp_output_range.total)
			details.color = wa.get_color(Currency.Type.XP)
		Thingy.Attribute.XP_OUTPUT_CURRENT:
			thingy_attributes_to_edit.append(th.xp_output_range.current)
			details.color = wa.get_color(Currency.Type.XP)
		Thingy.Attribute.XP_OUTPUT:
			thingy_attributes_to_edit.append(th.xp_output_range.current)
			thingy_attributes_to_edit.append(th.xp_output_range.total)
			details.color = wa.get_color(Currency.Type.XP)
		Thingy.Attribute.CURRENT_XP_INCREASE_RANGE:
			thingy_attributes_to_edit.append(th.xp_increase_range.current)
			details.color = wa.get_color(Currency.Type.XP)
		Thingy.Attribute.DURATION_RANGE:
			thingy_attributes_to_edit.append(th.duration_range.current)
			thingy_attributes_to_edit.append(th.duration_range.total)
		Thingy.Attribute.DURATION_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.duration_range.current)
		Thingy.Attribute.DURATION_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.duration_range.total)
		Thingy.Attribute.DURATION_INCREASE_RANGE:
			thingy_attributes_to_edit.append(th.duration_increase_range.current)
			thingy_attributes_to_edit.append(th.duration_increase_range.total)
		Thingy.Attribute.DURATION_INCREASE_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.duration_increase_range.current)
		Thingy.Attribute.DURATION_INCREASE_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.duration_increase_range.total)
		Thingy.Attribute.OUTPUT_RANGE:
			thingy_attributes_to_edit.append(th.output_range.current)
			thingy_attributes_to_edit.append(th.output_range.total)
		Thingy.Attribute.OUTPUT_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.output_range.total)
		Thingy.Attribute.OUTPUT_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.output_range.current)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE:
			thingy_attributes_to_edit.append(th.output_increase_range.current)
			thingy_attributes_to_edit.append(th.output_increase_range.total)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.output_increase_range.current)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.output_increase_range.total)
		Thingy.Attribute.CRIT:
			thingy_attributes_to_edit.append(th.crit_chance)
		Thingy.Attribute.CRIT_RANGE:
			thingy_attributes_to_edit.append(th.crit_range.current)
			thingy_attributes_to_edit.append(th.crit_range.total)
		Thingy.Attribute.CRIT_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.crit_range.current)
		Thingy.Attribute.CRIT_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.crit_range.total)
		Thingy.Attribute.CRIT_COIN_OUTPUT:
			thingy_attributes_to_edit.append(th.crit_coin_output.current)
			thingy_attributes_to_edit.append(th.crit_coin_output.total)
			details.color = wa.get_color(Currency.Type.COIN)
		Thingy.Attribute.CRIT_COIN_OUTPUT_CURRENT:
			thingy_attributes_to_edit.append(th.crit_coin_output.current)
			details.color = wa.get_color(Currency.Type.COIN)
		Thingy.Attribute.CRIT_COIN_OUTPUT_TOTAL:
			thingy_attributes_to_edit.append(th.crit_coin_output.total)
			details.color = wa.get_color(Currency.Type.COIN)
		Thingy.Attribute.COST:
			await th.initialized
			for cur in th.cost.amount:
				thingy_attributes_to_edit.append(th.cost.amount[cur])
	
	if unlocked_tree != up.UpgradeTree.Type.NONE:
		var tree = up.get_upgrade_tree(unlocked_tree)
		details.color = tree.details.color
		if type != Type.UNLOCK_UPGRADES:
			details.icon = tree.details.icon
		if details.description == "":
			details.description = "Unlock %s upgrades." % tree.details.icon_and_name
		match type:
			Type.UNLOCK_RPG_TREE:
				details.description = details.description.rstrip(".") + (
					" and %s." % (
						wa.get_details(Currency.Type.SOUL).icon_and_name
					)
				)
	
	match category:
		"added", "subtracted":
			modifier_add = mod
			modifier = LoudFloat.new(0)
		"multiplied", "divided":
			modifier_multiply = mod
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
	for att in thingy_attributes_to_edit:
		att.remove_change(category, self)
	if unlocked_tree != up.UpgradeTree.Type.NONE:
		up.upgrade_trees[unlocked_tree].unlocked.set_to(false)
	match type:
		Type.CRITS_AFFECT_XP_GAIN:
			th.crits_apply_to_xp.set_to(false)
		Type.CRITS_AFFECT_COIN_GAIN:
			th.crits_apply_to_coin.set_to(false)
		Type.UNLOCK_XP:
			wa.lock(Currency.Type.XP)
		Type.CRITS_APPLY_TO_DURATION:
			th.crits_apply_to_duration.set_to(false)
		Type.CRITS_GIVE_GOLD:
			wa.lock(Currency.Type.COIN)
		Type.UNLOCK_JUICE:
			wa.lock(Currency.Type.JUICE)
		Type.UNLOCK_RPG_TREE:
			wa.lock(Currency.Type.SOUL)


func apply() -> void:
	for att in thingy_attributes_to_edit:
		att.edit_change(category, self, modifier.get_value())
	if unlocked_tree != up.UpgradeTree.Type.NONE:
		up.upgrade_trees[unlocked_tree].unlocked.set_to(true)
	match type:
		Type.CRITS_AFFECT_XP_GAIN:
			th.crits_apply_to_xp.set_to(true)
		Type.CRITS_AFFECT_COIN_GAIN:
			th.crits_apply_to_coin.set_to(true)
		Type.UNLOCK_XP:
			wa.unlock(Currency.Type.XP)
		Type.CRITS_APPLY_TO_DURATION:
			th.crits_apply_to_duration.set_to(true)
		Type.CRITS_GIVE_GOLD:
			wa.unlock(Currency.Type.COIN)
		Type.UNLOCK_JUICE:
			wa.unlock(Currency.Type.JUICE)
		Type.UNLOCK_RPG_TREE:
			wa.unlock(Currency.Type.SOUL)



# - Get


func can_afford() -> bool:
	return cost.affordable.is_true() or gv.dev_mode


func can_purchase() -> bool:
	return unlocked.is_true() and purchased.is_false() and can_afford()


func get_description() -> String:
	if modifier:
		if times_purchased.equal(0):
			if (
				thingy_attribute in [
					Thingy.Attribute.DURATION_RANGE,
					Thingy.Attribute.DURATION_RANGE_CURRENT
				]
				and category in ["subtracted", "added"]
			):
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
				if (
					thingy_attribute in [
						Thingy.Attribute.DURATION_RANGE,
						Thingy.Attribute.DURATION_RANGE_CURRENT
					]
					and category in ["subtracted", "added"]
				):
					if thingy_attribute == Thingy.Attribute.DURATION_RANGE:
						return text % [
							tp.quick_parse(modifier.get_value(), true),
							tp.quick_parse(
								(modifier.get_value() + modifier_add) * modifier_multiply,
								true
							)
						]
				else:
					match thingy_attribute:
						Thingy.Attribute.CRIT:
							text = details.description % "%s -> %s%"
			return text % [
				modifier.get_text(),
				Big.get_float_text(
					(modifier.get_value() + modifier_add) * modifier_multiply
				)
			]
		if thingy_attribute in [
			Thingy.Attribute.DURATION_RANGE,
			Thingy.Attribute.DURATION_RANGE_CURRENT
		]:
			return details.description % tp.quick_parse(modifier.get_value(), false)
		return details.description % modifier.get_text()
	return details.description
