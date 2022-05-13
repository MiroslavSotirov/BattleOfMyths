extends Node

static func _callOn(object, method: String, paramether, i, use_index = false):
		if (paramether && use_index):
			return object.call(method, paramether, i);
		elif (paramether && !use_index):
			return object.call(method, paramether);
		elif (!paramether && use_index):
			return object.call(method, i);
		else:
			return object.call(method);
	
static func map(elements: Array, object: Object, method: String, use_index = false):
	var result = [];

	for i in range(elements.size()):
		var element = elements[i];
		result.push_back(_callOn(object, method, null, i, use_index));
#		result.push_back(object.call(method, element, i));

	return result;
	
static func callOnElements(elements: Array, method: String, paramethers = null, use_index = false):
	var result = [];
	for i in range(elements.size()):
		var p = paramethers[i] if paramethers && paramethers[i] else null;
#		elements[i].call(method, p)
#		result.push_back(elements[i].call(method, p))
		result.push_back(_callOn(elements[i], method, p, i, use_index))
#		result.push(_callOn(elements[i], method, p, i, use_index));

	return result;
