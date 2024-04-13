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
	
	JUICER,
	LUCKY_CRIT2,
	CRITS_AFFECT_COIN_GAIN2,
	CRITS_AFFECT_NEXT_DURATION,
	CRITS_AFFECT_ALL_OUTPUT,
	JUICE_OUT_INC_TOT,
	COIN_INC_TOT,
	WILL_POW_LEVELS,
}

static var data: Dictionary

@export var times_purchased := LoudIntPair.new(0, 1)
@export var purchased := LoudBool.new(false)
@export var price: Price
@export var applied := LoudBool.new(false)

var type: Type
var key: String
var details := Details.new()
var category: Book.Category
var unlocked := LoudBool.new(true)
var persist := Persist.new()


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
var modifier_change: float
var discord_state := ""
var tree: UpgradeTree.Type

var unlocked_tree: UpgradeTree.Type



func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	if not data.has(key):
		return
	var my_data: Dictionary = data.get(key)
	details.set_name(my_data.get("Name"))
	tree = UpgradeTree.Type[my_data.get("Tree").to_upper()]
	set_price(my_data.get("Cost"))
	if my_data.get("Cost Increase"):
		price.increase_modifier.set_to(float(my_data.get("Cost Increase")))
	if my_data.get("Thingy Attribute"):
		thingy_attribute = Thingy.Attribute[my_data.get("Thingy Attribute")]
	if my_data.get("Icon"):
		details.set_icon(bag.get_icon(my_data.get("Icon")))
	if my_data.get("Color"):
		details.set_color(wa.get_color(Currency.Type[my_data.get("Color").to_upper()]))
	if my_data.get("Discord State"):
		discord_state = my_data.get("Discord State")
	if my_data.get("Limit"):
		times_purchased.total.set_default_value(my_data.get("Limit"))
		times_purchased.total.reset()
	if my_data.get("Required Upgrade"):
		required_upgrade = Type[my_data.get("Required Upgrade")]
	
	if my_data.get("Category"):
		category = Book.Category[my_data.get("Category").to_upper()]
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
		Thingy.Attribute.COIN_INCREASE:
			details.set_description("%s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.COIN).get_icon_and_name(),
				operator + "%s",
			])
			thingy_attributes_to_edit.append(th.coin_increase.current)
			thingy_attributes_to_edit.append(th.coin_increase.total)
		Thingy.Attribute.COIN_INCREASE_CURRENT:
			details.set_description("Minimum %s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.COIN).get_icon_and_name(),
				operator + "%s",
			])
			thingy_attributes_to_edit.append(th.coin_increase.current)
		Thingy.Attribute.COIN_INCREASE_TOTAL:
			details.set_description("Maximum %s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.COIN).get_icon_and_name(),
				operator + "%s",
			])
			thingy_attributes_to_edit.append(th.coin_increase.total)
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
			details.set_description("Duration [u]increase[/u] [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_increase_range.current)
			thingy_attributes_to_edit.append(th.duration_increase_range.total)
		Thingy.Attribute.DURATION_INCREASE_RANGE_CURRENT:
			details.set_description("Minimum duration [u]increase[/u] [b]%s[/b]." % (operator + "%s"))
			thingy_attributes_to_edit.append(th.duration_increase_range.current)
		Thingy.Attribute.DURATION_INCREASE_RANGE_TOTAL:
			details.set_description("Maximum duration [u]increase[/u] [b]%s[/b]." % (operator + "%s"))
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
			details.set_description("%s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_increase_range.current)
			thingy_attributes_to_edit.append(th.output_increase_range.total)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE_CURRENT:
			details.set_description("Minimum %s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.output_increase_range.current)
		Thingy.Attribute.OUTPUT_INCREASE_RANGE_TOTAL:
			details.set_description("Maximum %s output [u]increase[/u] [b]%s[/b]." % [
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
			details.set_description("Minimum %s [u]increase[/u] [b]%s[/b]." % [
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
			details.set_description("%s multiplier [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_multiplier_range.current)
			thingy_attributes_to_edit.append(th.juice_multiplier_range.total)
		Thingy.Attribute.JUICE_MULTIPLIER_RANGE_CURRENT:
			details.set_description("Minimum %s multiplier [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_multiplier_range.current)
		Thingy.Attribute.JUICE_MULTIPLIER_RANGE_TOTAL:
			details.set_description("Maximum %s multiplier [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_multiplier_range.total)
		Thingy.Attribute.JUICE_INPUT_RANGE:
			details.set_description("%s input [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_input_range.current)
			thingy_attributes_to_edit.append(th.juice_input_range.total)
		Thingy.Attribute.JUICE_INPUT_RANGE_CURRENT:
			details.set_description("Minimum %s input [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_input_range.current)
		Thingy.Attribute.JUICE_INPUT_RANGE_TOTAL:
			details.set_description("Maximum %s input [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_input_range.total)
		Thingy.Attribute.JUICE_INPUT_INCREASE_RANGE:
			details.set_description("%s input [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_input_increase_range.current)
			thingy_attributes_to_edit.append(th.juice_input_increase_range.total)
		Thingy.Attribute.JUICE_INPUT_INCREASE_RANGE_CURRENT:
			details.set_description("Minimum %s input [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_input_increase_range.current)
		Thingy.Attribute.JUICE_INPUT_INCREASE_RANGE_TOTAL:
			details.set_description("Maximum %s input [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
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
			details.set_description("%s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_output_increase_range.current)
			thingy_attributes_to_edit.append(th.juice_output_increase_range.total)
		Thingy.Attribute.JUICE_OUTPUT_INCREASE_RANGE_CURRENT:
			details.set_description("Minimum %s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_output_increase_range.current)
		Thingy.Attribute.JUICE_OUTPUT_INCREASE_RANGE_TOTAL:
			details.set_description("Maximum %s output [u]increase[/u] [b]%s[/b]." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				(operator + "%s")
			])
			thingy_attributes_to_edit.append(th.juice_output_increase_range.total)
	
	match type:
		Type.TOTAL_OUTPUT_RANGE01:
			details.set_description("Maximum %s output [b]%s[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name(),
				(operator + "%s")
			] + (
				"\n%s Additive upgrades apply [i]before[/i] multiplicative upgrades." % (
					bag.get_icon_text("Info")
				)
			))
		Type.WILL_POW_LEVELS:
			details.set_description("%s output [b]x1.01 ^ total Thingy levels[/b]." % [
				wa.get_details(Currency.Type.WILL).get_icon_and_name()
			])
		Type.UNLOCK_CRIT:
			details.set_description("Crit chance [b]+%s%%[/b]." + "\n%s Crits multiply %s output by the Thingy's [i]crit multiplier[/i]." % [
				bag.get_icon_text("Info"),
				wa.get_details(Currency.Type.WILL).get_icon_and_name()
			])
		Type.THINGY_AUTOBUYER:
			details.set_description("Automatically purchases Thingies.")
			th.autobuyer_unlocked.copycat(applied)
		Type.WILL_FROM_JUICE:
			details.set_description("You gain 100%% of your current %s as %s per second." % [
				wa.get_details(Currency.Type.JUICE).get_icon_and_name(),
				wa.get_details(Currency.Type.WILL).get_icon_and_name()
			])
			wa.will_from_juice.copycat(applied)
		Type.CRITS_AFFECT_XP_GAIN:
			details.set_description("Crits multiply %s output." % (
				wa.get_details(Currency.Type.XP).get_icon_and_name()
			))
			th.crits_apply_to_xp.copycat(applied)
		Type.CRITS_AFFECT_COIN_GAIN:
			details.set_description("Crits multiply %s output." % (
				wa.get_details(Currency.Type.COIN).get_icon_and_name()
			))
			th.crits_apply_to_coin.copycat(applied)
		Type.CRITS_AFFECT_COIN_GAIN2:
			details.set_description("Crits multiply %s output twice." % (
				wa.get_details(Currency.Type.COIN).get_icon_and_name()
			))
			th.crits_apply_to_coin_twice.copycat(applied)
		Type.CRITS_AFFECT_ALL_OUTPUT:
			details.set_description("Global output multiplier +0.01 per crit.")
			th.crits_add_to_all_output.copycat(applied)
		Type.UNLOCK_UPGRADES:
			details.set_color(up.upgrade_color)
			unlocked_tree = UpgradeTree.Type.FIRESTARTER
			persist.through_tier(4)
		Type.UNLOCK_XP:
			details.set_description("Unlocks %s and Thingy levels.\n%s Thingies will be able to level up, increasing their stats! The %s icon represents the change upon level up." % [
				wa.get_details(Currency.Type.XP).get_icon_and_colored_name(),
				bag.get_icon_text("Info"),
				bag.get_icon_text("Arrow Up Fill")
			])
			wa.get_unlocked(Currency.Type.XP).copycat(applied)
		Type.UNLOCK_VOYAGER:
			persist.through_tier(1)
			unlocked_tree = UpgradeTree.Type.VOYAGER
			wa.get_unlocked(Currency.Type.SOUL).copycat(applied)
		Type.CRITS_GIVE_GOLD:
			details.set_description("All crits produce up to [b]%s[/b] " + wa.get_details(
				Currency.Type.COIN
			).get_icon_and_colored_name() + ".")
			wa.get_unlocked(Currency.Type.COIN).copycat(applied)
		Type.CRITS_AFFECT_NEXT_DURATION:
			details.set_description("Crits divide the next job's duration.")
		Type.UNLOCK_JUICE:
			details.set_description("Thingies may produce and consume %s to become [i][wave amp=20 freq=2]juiced![/wave][/i], halving duration and doubling primary output. If none is available to drink, they will produce it." % (
				wa.get_details(Currency.Type.JUICE).get_icon_and_name()
			))
			wa.get_unlocked(Currency.Type.JUICE).copycat(applied)
		Type.SMART_JUICE:
			details.set_description("Thingies produce %s more intelligently, resulting in Thingies remaining juiced for every task." % (
				wa.get_details(Currency.Type.JUICE).get_icon_and_name()
			))
			th.smart_juice.copycat(applied)
		Type.DURATION_AFFECTS_XP_OUTPUT:
			details.set_description("Duration multiplies %s output." % (
				wa.get_details(Currency.Type.XP).get_icon_and_name()
			))
			th.duration_affects_xp_output.copycat(applied)
		Type.CRITS_AFFECT_DURATION:
			details.set_description("Crits divide duration.")
			th.crits_apply_to_duration.copycat(applied)
		Type.UNLOCK_LUCKY_CRIT:
			details.set_description("Successful crits and lucky crits have a chance to roll for another crit, called a [i][wave amp=20 freq=2]lucky crit![/wave][/i] Crit multiplier will stack. Lucky crit chance [b]+%s%%[/b].")
	
	
	times_purchased.total.reset()
	price.owner_purchased.copycat(purchased)
	persist.failed_persist_check.connect(reset)
	
	if unlocked_tree != UpgradeTree.Type.NONE:
		var _tree = up.get_upgrade_tree(unlocked_tree)
		_tree.unlocked.copycat(applied)
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
	
	if my_data.get("Mod"):
		modifier_change = my_data.get("Mod")
		if Book.is_category_additive(category):
			modifier = LoudFloat.new(0)
			for att in thingy_attributes_to_edit:
				match category:
					Book.Category.ADDED:
						att.book.add_adder(modifier)
					Book.Category.SUBTRACTED:
						att.book.add_subtracter(modifier)
		else:
			modifier = LoudFloat.new(1)
			for att in thingy_attributes_to_edit:
				match category:
					Book.Category.MULTIPLIED:
						att.book.add_multiplier(modifier)
					Book.Category.DIVIDED:
						att.book.add_divider(modifier)
	times_purchased.current.changed.connect(times_purchased_changed)
	if not details.is_color_set():
		details.set_color(gv.get_random_nondark_color())


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
	purchased.set_to(times_purchased.full.is_true())
	if times_purchased.current.equal(1):
		if discord_state != "":
			gv.update_discord_state(discord_state)
	if times_purchased.current.greater(0):
		sync_modifier()
	elif times_purchased.current.equal(0):
		remove()



#region Action


func apply():
	if applied.is_true():
		return
	applied.set_to(true)
	sync_modifier()


func remove():
	if applied.is_false():
		return
	applied.set_to(false)
	if modifier:
		modifier.reset()
	match type:
		Type.CRITS_AFFECT_ALL_OUTPUT:
			th.all_output.reset()


func sync_modifier() -> void:
	if not modifier:
		return
	if Book.is_category_additive(category):
		modifier.set_to(modifier_change * times_purchased.get_value())
	else:
		modifier.set_to(pow(modifier_change, times_purchased.get_value()))


func reset() -> void:
	times_purchased.reset()
	price.reset()


func purchase() -> void:
	if times_purchased.is_full():
		return
	price.purchase()
	times_purchased.add(1)
	apply()


#endregion


# - Get


func can_afford() -> bool:
	return price.can_afford() or gv.dev_mode


func can_purchase() -> bool:
	return unlocked.is_true() and purchased.is_false() and can_afford()


func get_purchase_limit() -> int:
	return times_purchased.get_total()


func get_description() -> String:
	if modifier:
		return get_modifier_description()
	return details.get_description()


func get_modifier_description() -> String:
	if (
		Thingy.is_attribute_duration_related(thingy_attribute)
		and Book.is_category_additive(category)
	):
		return get_duration_description()
	if times_purchased.current.equal(0):
		return details.get_description() % Big.get_float_text(
			get_next_modifier_value()
		)
	if times_purchased.full.is_false():
		var text = details.get_description() % "%s -> %s"
		if thingy_attribute in [
			Thingy.Attribute.CRIT,
			Thingy.Attribute.CRIT_CRIT,
		]:
			text = details.get_description() % "%s -> %s%"
		return text % [
			modifier.get_text(),
			Big.get_float_text(
				get_next_modifier_value()
			)
		]
	return details.get_description() % modifier.get_text()


func get_duration_description() -> String:
	if times_purchased.current.equal(0):
		return details.get_description() % tp.quick_parse(
			get_next_modifier_value(),
			false
		)
	if times_purchased.full.is_false():
		var text = details.get_description() % "%s -> %s"
		return text % [
			tp.quick_parse(modifier.get_value(), true),
			tp.quick_parse(
				get_next_modifier_value(),
				true
			)
		]
	return details.get_description() % tp.quick_parse(modifier.get_value(), false)


func get_next_modifier_value() -> float:
	if Book.is_category_additive(category):
		if applied.is_false():
			return modifier_change * (times_purchased.get_value() + 1)
		return modifier.get_value() + modifier_change
	else:
		if applied.is_false():
			return pow(modifier_change, times_purchased.get_value() + 1)
		return modifier.get_value() * modifier_change



#region Dev


func report() -> void:
	printt("Report for Upgrade", key)
	printt("-", "Purchased:", purchased.get_value())
	printt("-", "Applied:", applied.get_value())
	printt("-", "Times purchased:", times_purchased.get_text())
	if modifier:
		printt("-", "Modifier:", modifier.get_text())
		printt("-", "Modifier change:", modifier_change)
#endregion
