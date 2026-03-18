extends Control

@onready var game_state: GameState = $GameState
@onready var battle_screen: BattleScreen = %BattleScreen

func _ready() -> void:
	battle_screen.setup(game_state)
