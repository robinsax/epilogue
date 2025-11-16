class_name AnimChain extends Object

var _chain: Array[Callable] = []
var next: Callable = Callable()

func _init():
	next = Callable(self, "_call_next")

func add(callable: Callable):
	_chain.push_back(callable)

func _call_next():
	if _chain.size() == 0:
		return

	_chain.pop_front().call()
