class_name FormatUtils

static func abbreviate(amount: float) -> String:
	var abs_amount: float = abs(amount)
	if abs_amount < 1_000.0:
		return "%d" % int(amount)
	if abs_amount < 1_000_000.0:
		return "%.1fK" % (amount / 1_000.0)
	if abs_amount < 1_000_000_000.0:
		return "%.1fM" % (amount / 1_000_000.0)
	if abs_amount < 1_000_000_000_000.0:
		return "%.1fB" % (amount / 1_000_000_000.0)
	return "%.1fT" % (amount / 1_000_000_000_000.0)
