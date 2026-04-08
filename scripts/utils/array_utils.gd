class_name ArrayUtils
extends RefCounted
## Shared array utility functions.

static func shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[j]
		arr[j] = arr[i]
		arr[i] = tmp
