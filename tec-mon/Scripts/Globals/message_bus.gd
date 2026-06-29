extends Node

signal message_requested(messages: Array[String], speed: int)
signal message_box_closed

var _message_box: Node

func register(box: Node) -> void:
	_message_box = box

## Standard send: shows text, waits for player to press E, then closes.
func send(messages: Array[String], speed: int = 30) -> void:
	message_requested.emit(messages, speed)
	Global.set_movement_blocked(true)

## Passive send: shows text in the box but doesnt wait for input and doesnt block movement
func send_passive(text: String, speed: int = 30) -> void:
	if _message_box == null:
		return
	_message_box.show_passive(text, speed)

func switch_message_box_mode(battle: bool):
	_message_box.battle_mode = battle

## Await this to pause until the player has dismissed the current message.
## Safe to call even if nothing is currently showing.
func wait_for_close() -> void:
	if not is_reading():
		return
	await message_box_closed

func is_reading() -> bool:
	if _message_box == null:
		return false
	return _message_box.is_reading()

func notify_closed() -> void:
	if not _message_box.battle_mode:
		Global.set_movement_blocked(false)
	message_box_closed.emit()
