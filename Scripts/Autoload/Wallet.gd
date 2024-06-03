extends Node



enum RateMode {
	MINIMUM,
	LIVE,
}

@export var currencies_by_name := {}

var currencies := {} # TODO make this the one that is exported. the other is useless
var will_from_juice := LoudBool.new(false)
var tier_0_currencies: Array[Currency]
var tier_1_currencies: Array[Currency]
var tier_2_currencies: Array[Currency]
var tier_3_currencies: Array[Currency]


#region Init


func _ready() -> void:
	set_physics_process(false)
	for cur in Currency.data.keys():
		currencies[cur] = Currency.new(cur)
		currencies_by_name[currencies[cur].key] = currencies[cur]
	get_currency("WILL").amount.changed.connect(will_changed)
	get_currency("WILL").amount.changed.connect(update_soul_gain_rate)
	get_currency("JUICE").amount.changed.connect(juice_changed)
	setup_lists()
	#gv.one_second.connect(update_soul_gain_rate)
	gv.reset.connect(reset)
	will_from_juice.changed.connect(will_from_juice_changed)


func setup_lists() -> void:
	for x in currencies.values():
		x = x as Currency
		match x.persist.get_highest_tier_can_persist_through():
			0:
				tier_0_currencies.append(x)
			1:
				tier_1_currencies.append(x)
			2:
				tier_2_currencies.append(x)
			3:
				tier_3_currencies.append(x)


#endregion


#region Private


func _physics_process(_delta):
	add("WILL", Big.new(get_amount("JUICE")).d(60))


func reset(tier: int) -> void:
	for x in range(tier, -1, -1):
		var currencies: Array[Currency]
		match x:
			0: currencies = tier_0_currencies
			1: currencies = tier_1_currencies
			2: currencies = tier_2_currencies
			3: currencies = tier_3_currencies
		var condition = get("s%s_reset" % str(x))
		var has_condition = condition != null
		if (
			tier > x
			or not has_condition
			or (has_condition and condition.call())
		):
			for currency in currencies:
				currency.reset(tier)


func will_from_juice_changed() -> void:
	set_physics_process(will_from_juice.get_value())


func will_changed() -> void:
	var new_amount = Big.new(
		maxf(
			0,
			pow(get_amount("WILL").logN(15), 1.5) - 8
		)
	).roundDown()
	wa.get_currency("SOUL").edit_pending(self, new_amount)


func juice_changed() -> void:
	if wa.will_from_juice.is_true():
		var rate = Big.new(wa.get_amount("JUICE")).d(60)
		wa.get_currency("WILL").gain_rate.edit_added(
			wa.get_currency("JUICE"), rate
		)


func update_soul_gain_rate() -> void:
	wa.get_currency("SOUL").gain_rate.edit_added(
		self,
		Big.new(wa.get_pending_amount("SOUL")).d(
			up.get_upgrade_tree(
				UpgradeTree.Type.FIRESTARTER
			).get_run_duration()
		)
	)


#endregion


#region Public


func collect_reset_currency(_tier: int) -> void:
	match _tier:
		1:
			add("SOUL", wa.get_pending_amount("SOUL"))


func add(key: String, amount) -> void:
	get_currency(key).add(amount)


func subtract(key: String, amount) -> void:
	get_currency(key).subtract(amount)


func unlock(key: String) -> void:
	get_currency(key).unlocked.set_to(true)


func lock(key: String) -> void:
	get_currency(key).unlocked.set_to(false)


# Get


func get_currency(key: String) -> Currency:
	return currencies[key]


func get_amount(key: String) -> Big:
	return get_currency(key).get_amount()


func can_afford(key: String, _amount) -> bool:
	return get_amount(key).greater_equal(_amount)


func get_pending_amount(key: String) -> Big:
	return get_currency(key).amount.book.get_pending()


func get_effective_amount(key: String) -> Big:
	return get_currency(key).get_effective_amount()


func get_net_rate(key: String) -> Big:
	return get_currency(key).net_rate


func get_details(key: String) -> Details:
	return get_currency(key).details


func get_amount_text(key: String) -> String:
	return get_currency(key).amount.get_text()


func get_currency_name(key: String) -> String:
	return get_details(key).get_name()


func get_color_text(key: String) -> Color:
	return get_details(key).get_color_text()


func get_color(key: String) -> Color:
	return get_details(key).get_color()


func is_unlocked(key: String) -> bool:
	return get_currency(key).unlocked.get_value()


func get_unlocked(key: String) -> LoudBool:
	return get_currency(key).unlocked
