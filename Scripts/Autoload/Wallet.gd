extends Node



enum RateMode {
	MINIMUM,
	LIVE,
}

@export var currencies_by_name := {}

var currencies := {}
var will_from_juice := LoudBool.new(false)



func _ready() -> void:
	set_physics_process(false)
	for cur in Currency.Type.values():
		currencies[cur] = Currency.new(cur)
		currencies_by_name[currencies[cur].key] = currencies[cur]
	get_currency(Currency.Type.WILL).amount.changed.connect(will_changed)
	get_currency(Currency.Type.WILL).amount.changed.connect(update_soul_gain_rate)
	get_currency(Currency.Type.JUICE).amount.changed.connect(juice_changed)
	gv.one_second.connect(update_soul_gain_rate)
	will_from_juice.changed.connect(will_from_juice_changed)



#region Signals


func _physics_process(_delta):
	add(Currency.Type.WILL, Big.new(get_amount(Currency.Type.JUICE)).d(60))


func will_from_juice_changed() -> void:
	set_physics_process(will_from_juice.get_value())


func will_changed() -> void:
	var new_amount = Big.new(
		maxf(
			0,
			pow(get_amount(Currency.Type.WILL).logN(15), 1.5) - 8
		)
	).roundDown()
	wa.get_pending_amount(Currency.Type.SOUL).set_to(new_amount)


func juice_changed() -> void:
	if wa.will_from_juice.is_true():
		var rate = Big.new(wa.get_amount(Currency.Type.JUICE)).d(60)
		wa.get_currency(Currency.Type.WILL).gain_rate.edit_added(
			wa.get_currency(Currency.Type.JUICE), rate
		)


func update_soul_gain_rate() -> void:
	wa.get_currency(Currency.Type.SOUL).gain_rate.edit_added(
		self, Big.new(wa.get_pending_amount(Currency.Type.SOUL)).d(
			up.get_upgrade_tree(
				UpgradeTree.Type.FIRESTARTER
			).get_run_duration()
		)
	)


#endregion


# - Action


func collect_reset_currency(_tier: int) -> void:
	match _tier:
		1:
			add(Currency.Type.SOUL, wa.get_pending_amount(Currency.Type.SOUL))


func add(cur: Currency.Type, amount) -> void:
	get_currency(cur).add(amount)


func subtract(cur: Currency.Type, amount) -> void:
	get_currency(cur).subtract(amount)


func unlock(cur: Currency.Type) -> void:
	get_currency(cur).unlocked.set_to(true)


func lock(cur: Currency.Type) -> void:
	get_currency(cur).unlocked.set_to(false)



# - Get


func get_currency(cur: Currency.Type) -> Currency:
	return currencies[cur]


func get_amount(cur: Currency.Type) -> Big:
	return get_currency(cur).get_amount()


func get_pending_amount(cur: Currency.Type) -> Big:
	return get_currency(cur).amount.pending


func get_effective_amount(cur: Currency.Type) -> Big:
	return get_currency(cur).get_effective_amount()


func get_net_rate(cur: Currency.Type) -> Big:
	return get_currency(cur).net_rate


func get_details(cur: Currency.Type) -> Details:
	return get_currency(cur).details


func get_amount_text(cur: Currency.Type) -> String:
	return get_currency(cur).amount.get_text()


func get_currency_name(cur: Currency.Type) -> String:
	return get_details(cur).get_name()


func get_color_text(cur: Currency.Type) -> Color:
	return get_details(cur).get_color_text()


func get_color(cur: Currency.Type) -> Color:
	return get_details(cur).get_color()


func is_unlocked(cur: Currency.Type) -> bool:
	return get_currency(cur).unlocked.get_value()


func get_unlocked(cur: Currency.Type) -> LoudBool:
	return get_currency(cur).unlocked
