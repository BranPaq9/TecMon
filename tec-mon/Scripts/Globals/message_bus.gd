extends Node

signal message_requested(messages: Array[String], speed: int) ## Signal for when a message is requested from the messagebus
signal message_box_closed ## Signal for when a message box is closed

var _message_box: Node

func register(box: Node) -> void:
	_message_box = box

func send(messages: Array[String], speed: int = 30) -> void:
	message_requested.emit(messages, speed) #Signal to the message box
	Global.set_movement_blocked(true)
	
func is_reading() -> bool:
	if _message_box == null:
		return false
	return _message_box.is_reading()
	
func notify_closed() -> void:
	if !_message_box.battle_mode:
		Global.set_movement_blocked(false)
	message_box_closed.emit()
	
