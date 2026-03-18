extends Control
class_name BattleScreen

const CardButton = preload("res://scripts/ui/card_button.gd")

@onready var turn_label: Label = %TurnLabel
@onready var intent_label: Label = %IntentLabel
@onready var player_stats: Label = %PlayerStats
@onready var enemy_stats: Label = %EnemyStats
@onready var hand_cards: HBoxContainer = %HandCards
@onready var log_text: RichTextLabel = %LogText
@onready var end_turn_button: Button = %EndTurnButton
@onready var reset_button: Button = %ResetButton

var game_state: GameState

func setup(state_node: GameState) -> void:
	game_state = state_node
	game_state.battle_state_changed.connect(_render)
	end_turn_button.pressed.connect(game_state.end_turn)
	reset_button.pressed.connect(game_state.reset_battle)
	_render(game_state.get_state())

func _render(state: Dictionary) -> void:
	turn_label.text = "Turn %d" % state.turn
	intent_label.text = "Enemy intent: %s | %d dmg | %d block" % [state.intent.label, state.intent.damage, state.intent.block]
	player_stats.text = "HP %d/%d | Block %d | Energy %d/%d | Draw %d | Discard %d" % [
		state.player.hp, state.player.max_hp, state.player.block, state.player.energy, state.player.max_energy, state.draw_size, state.discard_size
	]
	enemy_stats.text = "HP %d/%d | Block %d" % [state.enemy.hp, state.enemy.max_hp, state.enemy.block]
	_render_hand(state.hand, state.player.energy)
	log_text.text = "[color=#f4d58d]%s[/color]" % "\n".join(state.log)
	end_turn_button.disabled = state.enemy.hp <= 0 or state.player.hp <= 0

func _render_hand(cards: Array, available_energy: int) -> void:
	for child in hand_cards.get_children():
		child.queue_free()
	for i in range(cards.size()):
		var button := CardButton.new()
		button.custom_minimum_size = Vector2(180, 120)
		button.configure(i, cards[i], cards[i].cost <= available_energy)
		button.card_selected.connect(_on_card_selected)
		hand_cards.add_child(button)

func _on_card_selected(card_index: int) -> void:
	if game_state:
		game_state.play_card(card_index)
