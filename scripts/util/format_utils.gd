class_name FormatUtils
## Static utility functions for display formatting.


static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
