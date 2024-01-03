class_name TimeParser
extends Node



class TimeUnit:
	enum Type {
		SECOND,
		MINUTE,
		HOUR,
		DAY,
		YEAR,
		DECADE,
		CENTURY,
		MILLENIUM,
		EON,
		EXASECOND,
		QUETTASECOND,
		BLACK_HOLE,
	}
	const DIVISION := {
		Type.SECOND: 60,
		Type.MINUTE: 60,
		Type.HOUR: 24,
		Type.DAY: 365,
		Type.YEAR: 10,
		Type.DECADE: 10,
		Type.CENTURY: 10,
		Type.MILLENIUM: "1e6",
		Type.EON: "1e9",
		Type.EXASECOND: "1e12",
		Type.QUETTASECOND: "6e43",
		Type.BLACK_HOLE: 1,
	}
	const WORD := {
		Type.SECOND: {"SINGULAR": "second", "PLURAL": "seconds", "SHORT": "s"},
		Type.MINUTE: {"SINGULAR": "minute", "PLURAL": "minutes", "SHORT": "m"},
		Type.HOUR: {"SINGULAR": "hour", "PLURAL": "hours", "SHORT": "h"},
		Type.DAY: {"SINGULAR": "day", "PLURAL": "days", "SHORT": "d"},
		Type.YEAR: {"SINGULAR": "year", "PLURAL": "years", "SHORT": "y"},
		Type.DECADE: {"SINGULAR": "decade", "PLURAL": "decades", "SHORT": "dec"},
		Type.CENTURY: {"SINGULAR": "century", "PLURAL": "centuries", "SHORT": "cen"},
		Type.MILLENIUM: {"SINGULAR": "millenium", "PLURAL": "millenia", "SHORT": "mil"},
		Type.EON: {"SINGULAR": "eon", "PLURAL": "eons", "SHORT": "eon"},
		Type.EXASECOND: {"SINGULAR": "exasecond", "PLURAL": "exaseconds", "SHORT": "es"},
		Type.QUETTASECOND: {"SINGULAR": "quettasecond", "PLURAL": "quettaseconds", "SHORT": "qs"},
		Type.BLACK_HOLE: {"SINGULAR": "black hole life span", "PLURAL": "black hole lives", "SHORT": "bh"},
	}
	
	static func get_text(amount: Big, brief: bool) -> String:
		var type = Type.SECOND
		while type < Type.size() - 1:
			var division = Big.new(DIVISION[type])
			if amount.less(division):
				break
			amount.d(division)
			type = Type.values()[type + 1]
		if brief:
			return amount.roundDown().text + " " + WORD[type]["SHORT"]
		return amount.roundDown().text + " " + unit_text(type, amount)
	
	static func unit_text(type: int, amount: Big) -> String:
		if amount.equal(1):
			return WORD[type]["SINGULAR"]
		return WORD[type]["PLURAL"]


func quick_parse(duration, brief: bool) -> String:
	if is_equal_approx(0.0, duration):
		return "0s" if brief else "0 seconds"
	if duration is float:
		if duration < 1:
			return str(duration).pad_decimals(2) + ("s" if brief else " seconds")
		if duration < 10:
			return str(duration).pad_decimals(1) + ("s" if brief else " seconds")
	if duration < 60:
		return str(roundi(duration)) + ("s" if brief else " seconds")
	duration /= 60
	if duration < 60:
		return str(roundi(duration)) + ("m" if brief else " minutes")
	duration /= 60
	if duration < 24:
		return str(roundi(duration)) + ("h" if brief else " hours")
	duration /= 24
	if duration < 365:
		return str(roundi(duration)) + ("d" if brief else " days")
	duration /= 365
	return str(roundi(duration)) + ("y" if brief else " years")



func brief_parse_big(duration: Big) -> String:
	duration = Big.new(duration)
	if duration.less(60):
		return quick_parse(duration.toFloat(), true)
	return TimeUnit.get_text(duration, true)



func full_parse_big(duration: Big) -> String:
	duration = Big.new(duration)
	if duration.less(60):
		return quick_parse(duration.toFloat(), false)
	return TimeUnit.get_text(duration, false)




func full_parse_int(duration: int) -> String:
	return get_time_text_from_dict(get_time_dict(duration))


func get_time_dict(time) -> Dictionary:
	var dict := {"days": 0, "years": 0, "hours": 0, "minutes": 0, "seconds": 0}
	if time >= 31536000:
		dict["years"] = time / 31536000
		time = time % 31536000
	if time >= 86400:
		dict["days"] = time / 86400
		time = time % 86400
	if time >= 3600:
		dict["hours"] = time / 3600
		time = time % 3600
	if time >= 60:
		dict["minutes"] = time / 60
		time = time % 60
	dict["seconds"] = time
	return dict


func get_time_text_from_dict(dict: Dictionary) -> String:
	var years = dict["years"]
	var days = dict["days"]
	var hours = dict["hours"]
	var minutes = dict["minutes"]
	var seconds = dict["seconds"]
	
	var number_of_above_zero_elements := 0
	if years > 0:
		number_of_above_zero_elements += 1
	if days > 0:
		number_of_above_zero_elements += 1
	if hours > 0:
		number_of_above_zero_elements += 1
	if minutes > 0:
		number_of_above_zero_elements += 1
	if seconds > 0:
		number_of_above_zero_elements += 1
	
	var a: String
	var b: String
	var c: String
	var d: String
	
	match number_of_above_zero_elements:
		5:
			return str(years) + " years, " + str(days) + " days, " + str(hours) + " hours, " + str(minutes) + " minutes, and " + str(seconds) + " seconds"
		4:
			if years > 0:
				a = str(years) + " years"
				if days > 0:
					b = str(days) + " days"
					if hours > 0:
						c = str(hours) + " hours"
						if minutes > 0:
							d = str(minutes) + " minutes"
						else:
							d = str(seconds) + " seconds"
					else:
						c = str(minutes) + " minutes"
						d = str(seconds) + " seconds"
				else:
					b = str(hours) + " hours"
					c = str(minutes) + " minutes"
					d = str(seconds) + " seconds"
			else:
				a = str(days) + " days"
				b = str(hours) + " hours"
				c = str(minutes) + " minutes"
				d = str(seconds) + " seconds"
			return "%s, %s, %s, and %s" % [a, b, c, d]
		3:
			if years > 0:
				a = str(years) + " years"
				if days > 0:
					b = str(days) + " days"
					if hours > 0:
						c = str(hours) + " hours"
					elif minutes > 0:
						c = str(minutes) + " minutes"
					else:
						c = str(seconds) + " seconds"
				elif hours > 0:
					b = str(hours) + " hours"
					if minutes > 0:
						c = str(minutes) + " minutes"
					else:
						c = str(seconds) + " seconds"
				else:
					b = str(minutes) + " minutes"
					c = str(seconds) + " seconds"
			elif days > 0:
				a = str(days) + " days"
				if hours > 0:
					b = str(hours) + " hours"
					if minutes > 0:
						c = str(minutes) + " minutes"
					else:
						c = str(seconds) + " seconds"
				else:
					b = str(minutes) + " minutes"
					c = str(seconds) + " seconds"
			else:
				a = str(hours) + " hours"
				b = str(minutes) + " minutes"
				c = str(seconds) + " seconds"
			return "%s, %s, and %s" % [a, b, c]
		2:
			if years > 0:
				a = str(years) + " years"
				if days > 0:
					b = str(days) + " days"
				elif hours > 0:
					b = str(hours) + " hours"
				elif minutes > 0:
					b = str(minutes) + " minutes"
				else:
					b = str(seconds) + " seconds"
			elif days > 0:
				a = str(days) + " days"
				if hours > 0:
					b = str(hours) + " hours"
				elif minutes > 0:
					b = str(minutes) + " minutes"
				else:
					b = str(seconds) + " seconds"
			elif hours > 0:
				a = str(hours) + " hours"
				if minutes > 0:
					b = str(minutes) + " minutes"
				else:
					b = str(seconds) + " seconds"
			else:
				a = str(minutes) + " minutes"
				b = str(seconds) + " seconds"
			return "%s and %s" % [a, b]
		1:
			if years > 0:
				return str(years) + " years"
			elif days > 0:
				return str(days) + " days"
			elif hours > 0:
				return str(hours) + " hours"
			elif minutes > 0:
				return str(minutes) + " minutes"
	return str(seconds) + " seconds"

