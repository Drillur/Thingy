class_name UpgradeTree
extends Resource



enum Type {
	NONE,
	FIRESTARTER,
	VOYAGER,
}

@export var run_begin_clock: float = Time.get_unix_time_from_system()
@export var run_count := LoudInt.new(0)

var type: Type
var key: String
var unlocked := LoudBool.new(false)
var details := Details.new()
var persist := Persist.new()


func _init(_type: Type) -> void:
	type = _type
	key = Type.keys()[type]
	unlocked.changed.connect(unlocked_changed)
	details.set_name(Type.keys()[type].capitalize())
	persist.failed_persist_check.connect(reset)
	match type:
		Type.FIRESTARTER:
			details.set_color(Color(0.89, 0.118, 0.263))
			details.set_icon(bag.get_resource("Fire"))
		Type.VOYAGER:
			details.set_color(Color(0.118, 0.725, 0.89))
			details.set_icon(bag.get_resource("Map"))
			persist.through_tier(1)


func reset() -> void:
	run_begin_clock = Time.get_unix_time_from_system()
	run_count.add(1)


func get_run_duration() -> float:
	return Time.get_unix_time_from_system() - run_begin_clock


func unlocked_changed() -> void:
	up.container.tab_container.set_tab_hidden(int(type) - 1, not unlocked.get_value())
