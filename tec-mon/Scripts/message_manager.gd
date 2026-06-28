extends CanvasLayer

@export_category("Components")
@export var box: NinePatchRect
@export var label: RichTextLabel
@export_category("Variables")
@export var is_scrolling: bool = false
@export_multiline() var Messages: Array[String] = []

@onready var control: Control = $Control

signal advanced

var _waiting_for_input: bool = false
var _closing: bool = false
var normal_position: Vector2
var normal_size: Vector2
var battle_mode: bool = false

func _ready() -> void:
	visible = false
	normal_position = box.position
	normal_size = box.size
	process_mode = Node.PROCESS_MODE_DISABLED

	box.visible = false
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	MessageBus.register(self)
	MessageBus.message_requested.connect(_on_message_requested)
	BattleSystem.battle_started.connect(_on_battle_started)
	BattleSystem.battle_ended.connect(_on_battle_ended)
	
func _on_battle_started():
	battle_mode = true
	switch_mode()

func _on_battle_ended(outcome: BattleSystem.BattleOutcome):
	var msg: String = ""
	match outcome:
		BattleSystem.BattleOutcome.PLAYER_WIN:
			msg = "You won!"
		BattleSystem.BattleOutcome.PLAYER_FLED:
			msg = "Got away safely!"
		BattleSystem.BattleOutcome.PLAYER_LOST:
			msg = "You blacked out..."
	
	play_text([msg], 30)
	battle_mode = false
	await MessageBus.message_box_closed
	switch_mode()
	
func switch_mode():
	if battle_mode == true:
		box.position = Vector2(0, 112)
		box.size = Vector2(208, 48)
	else:
		box.position = normal_position
		box.size = normal_size

func _unhandled_input(event: InputEvent) -> void:
	if not is_reading() or _closing:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx("select")

		if is_scrolling:
			label.visible_characters = -1
		elif _waiting_for_input:
			_waiting_for_input = false
			advanced.emit()

func _on_message_requested(messages: Array[String], speed: int) -> void:
	play_text(messages, speed)

func play_text(payload: Array[String], speed: int) -> void:
	if is_reading() or payload.is_empty():
		return

	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

	Messages = payload
	box.visible = true

	while not Messages.is_empty(): #goes through all the messages
		is_scrolling = true
		label.visible_characters = 0
		label.text = Messages[0]

		for i in Messages[0].length():
			if label.visible_characters == -1:
				break
			label.visible_characters = i + 1
			await get_tree().create_timer(1.0 / speed).timeout

		label.visible_characters = -1
		is_scrolling = false
		Messages.remove_at(0)

		# Wait for interact before next message or closing
		_waiting_for_input = true
		await advanced

	# Close with a brief cooldown
	_closing = true
	box.visible = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.1).timeout
	_closing = false
	MessageBus.notify_closed()
	
func is_reading() -> bool:
	return visible and box.visible

func scrolling() -> bool:
	return is_scrolling

func get_messages() -> Array[String]:
	return Messages
