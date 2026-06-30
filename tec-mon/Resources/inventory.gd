extends Resource
class_name Inventory

signal item_added(item: ItemData, new_qty: int)
signal item_removed(item: ItemData, new_qty: int)

var _items: Dictionary = {}  ## ItemData -> int (quantity)

func add(item: ItemData, qty: int = 1) -> void:
	_items[item] = _items.get(item, 0) + qty
	item_added.emit(item, _items[item])

func remove(item: ItemData, qty: int = 1) -> bool:
	if not has(item, qty):
		return false
	_items[item] -= qty
	var new_qty: int = _items[item]
	if new_qty <= 0:
		_items.erase(item)
	item_removed.emit(item, new_qty)
	return true

func has(item: ItemData, qty: int = 1) -> bool:
	return _items.get(item, 0) >= qty

func quantity(item: ItemData) -> int:
	return _items.get(item, 0)

func all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for key in _items:
		result.append(key)
	return result

func items_in_category(category: ItemData.Category) -> Array[ItemData]:
	return all_items().filter(func(i): return i.category == category)

func is_empty() -> bool:
	return _items.is_empty()
	
