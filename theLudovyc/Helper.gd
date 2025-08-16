extends Object
class_name Helper


static func get_string_from_signed_int(i: int):
	return ("+" if i >= 0 else "") + str(i)

static func sum(accum: int, number: int):
	return accum + number

static func add_each(arr1: Array[int], arr2: Array[int]):
	for i in range(arr1.size()):
		arr1[i] += arr2[i]

static func sub_each(arr1: Array[int], arr2: Array[int]):
	for i in range(arr1.size()):
		arr1[i] -= arr2[i]
