class_name Upgrade
extends Resource



enum Type {
	UNLOCK_UPGRADES,
	HASTE01,
	OUTPUT01,
	COST01,#
	XP02,
	UNLOCK_VOYAGER,
	UNLOCK_XP,
	UNLOCK_CRIT,
	CRIT01,
	CRITS_GIVE_GOLD,
	TOTAL_OUTPUT_RANGE01,
	CURRENT_DURATION_RANGE01,
	TOTAL_XP_GAIN01,
	OUTPUT02,
	XP_GAIN01,#
	XP01,#
	DURATION01,
	DURATION_INCREASE01,
	CRITS_AFFECT_XP_GAIN,
	CRIT_RANGE01,#
	CRITS_AFFECT_COIN_GAIN,
	DURATION02,
	OUTPUT03,
	COIN01,#
	CRITS_AFFECT_DURATION,
	
	
	UNLOCK_JUICE,
	DURATION03,
	OUTPUT_INCREASE01,
	UNLOCK_LUCKY_CRIT,
	DURATION_AFFECTS_XP_OUTPUT,
	CURRENT_XP_INCREASE_RANGE01,
	OUTPUT_INCREASE_RANGE_TOTAL01,
	CRIT02,
	CRIT_RANGE02,
	WILL_FROM_JUICE,
	SMART_JUICE,
	THINGY_AUTOBUYER,
	
	JUICER,#
	LUCKY_CRIT2,#
	CRITS_AFFECT_COIN_GAIN2,#
	CRITS_AFFECT_NEXT_DURATION,#
}

static var data: Dictionary

@export var times_purchased := LoudIntPair.new(0, 1)
@export var purchased := LoudBool.new(false)
@export var price: Price
@export var enabled := LoudBool.new(true)

var type: Type
var key: String
var details := Details.new()
var category: Book.Category
var unlocked := LoudBool.new(true)
var persist := Persist.new()
var times_applied := 0


var vico: UpgradeButton
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

var thingy_attribute := Thingy.Attribute.NONE
var thingy_attributes_to_edit: Array
var modifier: LoudFloat
var modifier_add := 0.0
var modifier_multiply := 1.0
var discord_state := ""
var tree: UpgradeTree.Type

var unlocked_tree: UpgradeTree.Type



func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	var my_data: Dictionary = data.get(key)
	details.set_name(my_data.get("Name"))
	tree = UpgradeTree.Type[my_data.get("Tree").to_upper()]
	set_price(my_data.get("Cost"))
	if my_data.get("Cost Increase"):
		price.increase_modifier.set_to(float(my_data.get("Cost Increase")))
	if my_data.get("Thingy Attribute"):
		thingy_attribute = Thingy.Attribute[my_data.get("Thingy Attribute")]
	if my_data.get("Category"):
		category = Book.Category[my_data.get("Category").to_upper()]
	if my_data.get("Icon"):
		details.set_icon(bag.get_icon(my_data.get("Icon")))
	if my_data.get("Color"):
		details.set_color(wa.get_color(Currency.Type[my_data.get("Color").to_upper()]))
	if my_data.get("Discord State"):
		discord_state = my_data.get("Discord State")
	if my_data.get("Limit"):
		times_purchased.total.set_default_value(my_data.get("Limit"))
	if my_data.get("Required Upgrade"):
		required_upgrade = Type[my_data.get("Required Upgrade")]
	var operator: String
	match category:
		Book.Category.ADDED:
			operator = "+"
		Book.Category.SUBTRACTED:
			operator = "-"
		Book.Category.MULTIPLIED:
			operator = "x"
		Book.Category.DIVIDED:
			operator = "/"
	match thingy_attribute:
		Thingy.Attribute.DURATION_RANGE:
			details.set_description("Duration [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_range.current)
			thingy_attributes_to_edit.append(th.duration_range.total)
		Thingy.Attribute.DURATION_RANGE_CURRENT:
			details.set_description("Minimum duration [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_range.current)
		Thingy.Attribute.DURATION_RANGE_TOTAL:
			details.set_description("Maximum duration [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_range.total)
		Thingy.Attribute.DURATION_INCREASE_RANGE:
			details.set_description("Duration increase [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_increase_range.current)
			thingy_attributes_to_edit.append(th.duration_increase_range.total)
		Thingy.Attribute.DURATION_INCREASE_RANGE_CURRENT:
			details.set_description("Minimum duration increase [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_increase_range.current)
		Thingy.Attribute.DURATION_INCREASE_RANGE_TOTAL:
			details.set_description("Maximum duration increase [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_increase_range.total)
		Thingy.Attribute.CRIT:
			details.set_description("Crit chance [b]%s[/b]." % (operator + "%s%%"))
			thingy_attributes_to_edit.append(th.crit_chance)
		Thingy.Attribute.CRIT_CRIT:
			details.set_description("Lucky crit chance [b]%s[/b]." % (operator + "%s%%"))
			thingy_attributes_to_edit.append(th.crit_crit_chance)
		Thingy.Attribute.CRIT_RANGE:
			details.set_description("Crit multiplier [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.crit_range.current)
			thingy_attributes_to_edit.append(th.crit_range.total)
		Thingy.Attribute.CRIT_RANGE_CURRENT:
			details.set_description("Minimum crit multiplier [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.crit_range.current)
		Thingy.Attribute.CRIT_RANGE_TOTAL:
			details.set_description("Maximum crit multiplier [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.crit_range.total)
		Thingy.Attribute.CRIT_COIN_OUTPUT:
			details.set_description("%s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.COIN).get_icon_and_name(),
				(operator + "%s")
			])
			details.set_description(wa.get_details(Currency.Type.COIN).get_icon_and_name() + " output [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.crit_coin_output.current)
			thingy_attributes_to_edit.append(th.crit_coin_output.total)
		Thingy.Attribute.CRIT_COIN_OUTPUT_CURRENT:
			details.set_description("Minimum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.COIN).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.crit_coin_output.current)
		Thingy.Attribute.CRIT_COIN_OUTPUT_TOTAL:
			details.set_description("Maximum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.COIN).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.crit_coin_output.total)
		Thingy.Attribute.OUTPUT_RANGE:
			details.set_description("%s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_range.current)
			thingy_attributes_to_edit.append(th.output_range.total)
		Thingy.Attribute.OUTPUT_RANGE_CURRENT:
			details.set_description("Minimum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_range.current)
		Thingy.Attribute.OUTPUT_RANGE_TOTAL:
			details.set_description("Maximum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_range.total)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE:
			details.set_description("%s output increase [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_increase_range.current)
			thingy_attributes_to_edit.append(th.output_increase_range.total)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE_CURRENT:
			details.set_description("Minimum %s output increase [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_increase_range.current)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE_TOTAL:
			details.set_description("Maximum %s output increase [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_increase_range.total)
		Thingy.Attribute.XP:
			details.set_description("Total %s required [b]%s[/b]." % [
				wa.get_details(Currency.Type.XP).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.xp_multiplier)
		Thingy.Attribute.XP_OUTPUT:
			details.set_description("%s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.XP).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.xp_output_range.current)
			thingy_attributes_to_edit.append(th.xp_output_range.total)
		Thingy.Attribute.XP_OUTPUT_CURRENT:
			details.set_description("Minimum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.XP).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.xp_output_range.current)
		Thingy.Attribute.XP_OUTPUT_TOTAL:
			details.set_description("Maximum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.XP).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.xp_output_range.total)
		Thingy.Attribute.CURRENT_XP_INCREASE_RANGE:
			details.set_description("Minimum %s increase [b]%s[/b]." % [
				wa.get_details(Currency.Type.XP).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.xp_increase_range.current)
		Thingy.Attribute.COST:
			details.set_description("Thingy cost [b]%s[/b]." % (operator + "%s"))
			await th.initialized
			for cur in th.price.price:
				thingy_attributes_to_edit.append(th.price.price[cur])
		Thingy.Attribute.JUICE_MULTIPLIER_RANGE:
			thingy_attributes_to_edit.append(th.juice_multiplier_range.current)
			thingy_attributes_to_edit.append(th.juice_multiplier_range.total)
		Thingy.Attribute.JUICE_MULTIPLIER_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.juice_multiplier_range.current)
		Thingy.Attribute.JUICE_MULTIPLIER_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.juice_multiplier_range.total)
		Thingy.Attribute.JUICE_INPUT_RANGE:
			thingy_attributes_to_edit.append(th.juice_input_range.current)
			thingy_attributes_to_edit.append(th.juice_input_range.total)
		Thingy.Attribute.JUICE_INPUT_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.juice_input_range.current)
		Thingy.Attribute.JUICE_INPUT_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.juice_input_range.total)
		Thingy.Attribute.JUICE_INPUT_INCREASE_RANGE:
			thingy_attributes_to_edit.append(th.juice_input_increase_range.current)
			thingy_attributes_to_edit.append(th.juice_input_increase_range.total)
		Thingy.Attribute.JUICE_INPUT_INCREASE_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.juice_input_increase_range.current)
		Thingy.Attribute.JUICE_INPUT_INCREASE_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.juice_input_increase_range.total)
		Thingy.Attribute.JUICE_OUTPUT_RANGE:
			details.set_description("%s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_output_range.current)
			thingy_attributes_to_edit.append(th.juice_output_range.total)
		Thingy.Attribute.JUICE_OUTPUT_RANGE_CURRENT:
			details.set_description("Minimum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_output_range.current)
		Thingy.Attribute.JUICE_OUTPUT_RANGE_TOTAL:
			details.set_description("Maximum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_output_range.total)
		Thingy.Attribute.JUICE_OUTPUT_INCREASE_RANGE:
			thingy_attributes_to_edit.append(th.juice_output_increase_range.current)
			thingy_attributes_to_edit.append(th.juice_output_increase_range.total)
		Thingy.Attribute.JUICE_OUTPUT_INCREASE_RANGE_CURRENT:
			thingy_attributes_to_edit.append(th.juice_output_increase_range.current)
		Thingy.Attribute.JUICE_OUTPUT_INCREASE_RANGE_TOTAL:
			thingy_attributes_to_edit.append(th.juice_output_increase_range.total)
	
	match type:
		Type.UNLOCK_UPGRADES:
			details.set_color(up.upgrade_color)
			unlocked_tree = UpgradeTree.Type.FIRESTARTER
			persist.through_tier(4)
		Type.UNLOCK_XP:
			details.set_description("Unlocks %s and Thingy levels." % wa.get_details(
				Currency.Type.XP
			).get_icon_and_colored_name())
		Type.UNLOCK_VOYAGER:
			persist.through_tier(1)
		Type.CRITS_GIVE_GOLD:
			details.set_description("All crits produce up to %s " + wa.get_details(
				Currency.Type.COIN
			).get_icon_and_colored_name() + ".")
		Type.CRITS_AFFECT_XP_GAIN:
			details.set_description("Crits multiply %s output." % (
				wa.get_details(Currency.Type.XP).get_icon_and_name()
			))
		Type.CRITS_AFFECT_COIN_GAIN:
			details.set_description("Crits multiply %s output." % (
				wa.get_details(Currency.Type.COIN).get_icon_and_name()
			))
		Type.CRITS_AFFECT_NEXT_DURATION:
			details.set_description("Crits divide the next job's duration.")
		Type.UNLOCK_JUICE:
			details.set_description("Thingies may produce and consume %s to become [i][wave amp=20 freq=2]juiced![/wave][/i], halving duration and doubling primary output. If none is available to drink, they will produce it." % (
				wa.get_details(Currency.Type.JUICE).get_icon_and_name()
			))
		Type.SMART_JUICE:
			details.set_description("Thingies produce %s more intelligently, resulting in Thingies remaining juiced for every task." % (
				wa.get_details(Currency.Type.JUICE).get_icon_and_name()
			))
		Type.DURATION_AFFECTS_XP_OUTPUT:
			details.set_description("Duration multiplies %s output." % (
				wa.get_details(Currency.Type.XP).get_icon_and_name()
			))
		Type.WILL_FROM_JUICE:
			details.set_description("You gain 100%% of your current %s as %s per second." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				wa.get_details(Currency.Type.WILL).get_icon_and_name()
			])
		Type.CRITS_AFFECT_DURATION:
			details.set_description("Crits divide duration.")
		Type.UNLOCK_LUCKY_CRIT:
			details.set_description("Successful crits and lucky crits have a chance to roll for another crit, called a [i][wave amp=20 freq=2]lucky crit![/wave][/i] Crit multiplier will stack. Lucky crit chance [b]+%s%%[/b].")
		Type.CRITS_AFFECT_COIN_GAIN2:
			details.set_description("Crits multiply %s output twice." % (
				wa.get_details(Currency.Type.COIN).get_icon_and_name()
			))
		Type.THINGY_AUTOBUYER:
			details.set_description("Automatically purchases Thingies.")
	
	times_purchased.total.reset()
	price.owner_purchased.copycat(purchased)
	persist.failed_persist_check.connect(reset)
	
	if unlocked_tree != UpgradeTree.Type.NONE:
		var _tree = up.get_upgrade_tree(unlocked_tree)
		details.set_color(_tree.details.get_color())
		if type != Type.UNLOCK_UPGRADES:
			details.set_icon(_tree.details.get_icon())
		if details.get_description() == "":
			details.set_description("Unlock %s upgrades." % _tree.details.get_icon_and_name())
		match type:
			Type.UNLOCK_VOYAGER:
				details.set_description(details.get_description().rstrip(".") + (
					" and %s." % (
						wa.get_details(Currency.Type.SOUL).get_icon_and_name()
					)
				))
	
	var mod: float
	if my_data.get("Mod"):
		mod = my_data.get("Mod")
	match category:
		Book.Category.ADDED, Book.Category.SUBTRACTED:
			modifier_add = mod
			modifier = LoudFloat.new(0)
		Book.Category.MULTIPLIED, Book.Category.DIVIDED:
			modifier_multiply = mod
			modifier = LoudFloat.new(1)
	times_purchased.changed.connect(times_purchased_changed)
	times_purchased.current.increased.connect(times_purchased_increased)
	if not details.is_color_set():
		details.set_color(gv.get_random_nondark_color())
	if modifier:
		modifier.changed.connect(modifier_changed)


func set_price(_cost_text: String) -> void:
	var price_dict := {}
	for text in _cost_text.split(", "):
		var split = text.split(" ")
		var currency_name = split[0].to_upper()
		var amount = split[1]
		price_dict[Currency.Type[currency_name]] = amount
	price = Price.new(price_dict)


# - Signals


func times_purchased_changed() -> void:
	if times_purchased.full.is_false():
		purchased.set_to(false)
	else:
		purchased.set_to(true)
	if times_purchased.current.equal(0):
		times_applied = 0
		if modifier:
			modifier.reset()
	else:
		if discord_state != "":
			gv.update_discord_state(discord_state)


func times_purchased_increased() -> void:
	if modifier:
		while times_applied < times_purchased.get_value():
			times_applied += 1
			modifier.add(modifier_add)
			modifier.multiply(modifier_multiply)
	else:
		apply()




func modifier_changed() -> void:
	if times_purchased.current.equal(0):
		remove()
	else:
		apply()



# - Action


func purchase() -> void:
	price.purchase()
	times_purchased.add(1)
	if times_purchased.is_full():
		return


func reset() -> void:
	remove()
	times_purchased.reset()
	price.reset()


func remove() -> void:
	for att in thingy_attributes_to_edit:
		att.remove_change(category, self)
	if unlocked_tree != UpgradeTree.Type.NONE:
		up.upgrade_trees[unlocked_tree].unlocked.set_to(false)
	match type:
		Type.THINGY_AUTOBUYER:
			th.autobuyer_unlocked.set_to(false)
		Type.SMART_JUICE:
			th.smart_juice.set_to(false)
		Type.WILL_FROM_JUICE:
			wa.will_from_juice.set_to(false)
		Type.CRITS_AFFECT_XP_GAIN:
			th.crits_apply_to_xp.set_to(false)
		Type.CRITS_AFFECT_COIN_GAIN:
			th.crits_apply_to_coin.set_to(false)
		Type.CRITS_AFFECT_COIN_GAIN2:
			th.crits_apply_to_coin_twice.set_to(false)
		Type.UNLOCK_XP:
			wa.lock(Currency.Type.XP)
		Type.CRITS_AFFECT_DURATION:
			th.CRITS_AFFECT_DURATION.set_to(false)
		Type.CRITS_GIVE_GOLD:
			wa.lock(Currency.Type.COIN)
		Type.UNLOCK_JUICE:
			wa.lock(Currency.Type.JUICE)
		Type.UNLOCK_VOYAGER:
			wa.lock(Currency.Type.SOUL)
		Type.DURATION_AFFECTS_XP_OUTPUT:
			th.duration_affects_xp_output.set_to(false)


func apply() -> void:
	for att in thingy_attributes_to_edit:
		att.edit_change(category, self, modifier.get_value())
	if unlocked_tree != UpgradeTree.Type.NONE:
		up.upgrade_trees[unlocked_tree].unlocked.set_to(true)
	match type:
		Type.THINGY_AUTOBUYER:
			th.autobuyer_unlocked.set_to(true)
		Type.SMART_JUICE:
			th.smart_juice.set_to(true)
		Type.WILL_FROM_JUICE:
			wa.will_from_juice.set_to(true)
		Type.CRITS_AFFECT_XP_GAIN:
			th.crits_apply_to_xp.set_to(true)
		Type.CRITS_AFFECT_COIN_GAIN:
			th.crits_apply_to_coin.set_to(true)
		Type.CRITS_AFFECT_COIN_GAIN2:
			th.crits_apply_to_coin_twice.set_to(true)
		Type.UNLOCK_XP:
			wa.unlock(Currency.Type.XP)
		Type.CRITS_AFFECT_DURATION:
			th.CRITS_AFFECT_DURATION.set_to(true)
		Type.CRITS_GIVE_GOLD:
			wa.unlock(Currency.Type.COIN)
		Type.UNLOCK_JUICE:
			wa.unlock(Currency.Type.JUICE)
		Type.UNLOCK_VOYAGER:
			wa.unlock(Currency.Type.SOUL)
		Type.DURATION_AFFECTS_XP_OUTPUT:
			th.duration_affects_xp_output.set_to(true)
	
	times_applied += 1



# - Get


func can_afford() -> bool:
	return price.can_afford() or gv.dev_mode


func can_purchase() -> bool:
	return unlocked.is_true() and purchased.is_false() and can_afford()


func get_purchase_limit() -> int:
	return times_purchased.get_total()


func get_description() -> String:
	if modifier:
		if times_purchased.current.equal(0):
			if (
				thingy_attribute in [
					Thingy.Attribute.DURATION_RANGE,
					Thingy.Attribute.DURATION_RANGE_CURRENT
				]
				and Book.is_category_additive(category)
			):
				return details.get_description() % tp.quick_parse(
					(modifier.get_value() + modifier_add) * modifier_multiply,
					false
				)
			return details.get_description() % Big.get_float_text(
				(modifier.get_value() + modifier_add) * modifier_multiply
			)
		if times_purchased.full.is_false():
			var text = details.get_description() % "%s -> %s"
			if thingy_attribute != Thingy.Attribute.NONE:
				if (
					thingy_attribute in [
						Thingy.Attribute.DURATION_RANGE,
						Thingy.Attribute.DURATION_RANGE_CURRENT
					]
					and Book.is_category_additive(category)
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
					if thingy_attribute in [
						Thingy.Attribute.CRIT,
						Thingy.Attribute.CRIT_CRIT,
					]:
						text = details.get_description() % "%s -> %s%"
			return text % [
				modifier.get_text(),
				Big.get_float_text(
					(modifier.get_value() + modifier_add) * modifier_multiply
				)
			]
		if (
			thingy_attribute in [
				Thingy.Attribute.DURATION_RANGE,
				Thingy.Attribute.DURATION_RANGE_CURRENT
			] and Book.is_category_additive(category)
		):
			return details.get_description() % tp.quick_parse(modifier.get_value(), false)
		return details.get_description() % modifier.get_text()
	return details.get_description()
