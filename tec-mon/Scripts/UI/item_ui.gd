extends Control

signal item_used(item: ItemData, target: TecmonInstance)
signal back_pressed

@onready var key_item_container: VBoxContainer = %KeyItemContainer
@onready var battle_item_container: VBoxContainer = %BattleItemContainer
@onready var heal_item_container: VBoxContainer = %HealItemContainer
@onready var swap_texture: TextureRect = %ItemSwapTexture
@onready var desc: RichTextLabel = %ItemDesc
@onready var back_button: Button = %BackButton

@export var details_template: PackedScene

var _all_buttons: Array[Button] = []
var containers: Array[VBoxContainer] = []

func _ready() -> void:
	back_button.pressed.connect(func(): back_pressed.emit())
	containers = [key_item_container, battle_item_container, heal_item_container]
	
func open() -> void:
	_populate()
	show()

func _populate() -> void:
	_clear_containers()
	_all_buttons.clear()

	var inventory: Inventory = Global.player.inventory
	var items := inventory.all_items()
	if items.is_empty():
		desc.text = "No items."
		return

	for item: ItemData in items:
		var details := details_template.instantiate() as Button
		details.item = item
		details.item_amount = inventory.quantity(item)

		_container_for(item.category).add_child(details)
		_all_buttons.append(details)

		details.get_node("%ItemName").text = item.item_name
		details.get_node("%ItemCount").text = "x" + str(inventory.quantity(item))
		details.selected.connect(_on_item_selected)
		details.unselected.connect(_on_item_unselected)
		details.hovered.connect(_on_item_hovered)
		details.used.connect(_on_item_used)

	_on_item_hovered(items[0])

func _clear_containers() -> void:
	for container in containers:
		for child in container.get_children():
			child.queue_free()

func _container_for(category: ItemData.Category) -> VBoxContainer:
	match category:
		ItemData.Category.KEY: return key_item_container
		ItemData.Category.BATTLE: return battle_item_container
		ItemData.Category.HEALING: return heal_item_container
	return battle_item_container

func _on_item_used(item: ItemData) -> void:
	var target: TecmonInstance = (
		BattleSystem.enemy_participant.current_mon
		if item.effect == ItemData.Effect.CAPTURE
		else Global.player.tecmon_party[0]
	)
	item_used.emit(item, target)

func _on_item_selected() -> void:
	for btn in _all_buttons:
		btn.disabled = true

func _on_item_unselected() -> void:
	for btn in _all_buttons:
		btn.disabled = false

func _on_item_hovered(item: ItemData) -> void:
	swap_texture.texture = item.icon
	desc.text = "%s\n%s" % [item.item_name, item.description]

func _on_tab_container_tab_changed(tab: int) -> void:
	var container: VBoxContainer = containers.get(tab)
	if container.get_child_count() > 0:
		var button: Button = container.get_child(0)
		var item: ItemData = button.item
		_on_item_hovered(item)
