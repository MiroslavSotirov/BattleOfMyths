extends Node;

var awaiting_count = 0;
var results = [];

signal completed;

static func resolve(res = null):
	var promise = Promise.duplicate();
	promise.call_deferred("_resolve", res);

	return promise;

static func race(coroutines: Array):
	var promise = Promise.duplicate();
	for coroutine in coroutines:
		if coroutine.is_valid():
			coroutine.connect("completed", promise, "_resolve");
			
	return promise;

static func all(coroutines: Array):
	var promise = Promise.duplicate();

	for i in range(coroutines.size()):
		var coroutine = coroutines[i];
		promise.awaiting_count += 1;
		
		if coroutine.is_valid():
			promise.results.append(null);
			
			coroutine.connect("completed", promise, "_resolve_all", [i]);
		else:
			promise._all_coroutine_completed(coroutine, i);

	return promise;

func _resolve(res = null):
	emit_signal("completed", res);

func _resolve_all(res = null, pos = 0):
	awaiting_count -= 1;
	results[pos] = res;

	if(awaiting_count == 0): 
		emit_signal("completed", results);
