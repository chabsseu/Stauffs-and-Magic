extends Node

var floor : int = 1

# Health & Armor (from PlayerState)
var current_health : int = 5
var max_health : int = 5
var current_armor : int = 5
var max_armor : int = 5

# Mana (from PlayerState)
var current_mana : int = 100
var max_mana : int = 100

# Movement (from PlayerState)
var base_speed : float = 300.0

# Weapons (from Player hotbar)
var hotbar_data : Array = []
var current_slot : int = -1
var cooldown : Array = []
var max_cooldown : Array = []

# Currency
var coins: int = 0
var food: int = 0
# --------------------------------------------------
# SAVE
# --------------------------------------------------
func save_from_player_state(player_state: Node, player: CharacterBody2D):
    # Stats
    current_health = player_state.current_health
    max_health = player_state.max_health
    current_armor = player_state.current_armor
    max_armor = player_state.max_armor
    current_mana = player_state.current_mana
    max_mana = player_state.max_mana
    base_speed = player_state.base_speed
    
    # Weapons
    hotbar_data = player.hotbar_data.duplicate(true)
    current_slot = player.current_slot
    cooldown = player.cooldown.duplicate()
    max_cooldown = player.max_cooldown.duplicate()
    
    print("GameData saved! floor: ", floor, " HP: ", current_health, "/", max_health)

# --------------------------------------------------
# RESTORE
# --------------------------------------------------
func restore_to_player_state(player_state: Node, player: CharacterBody2D):
    # Stats
    player_state.current_health = current_health
    player_state.max_health = max_health
    player_state.current_armor = current_armor
    player_state.max_armor = max_armor
    player_state.current_mana = current_mana
    player_state.max_mana = max_mana
    player_state.base_speed = base_speed
    player_state.speed = base_speed
    
    # Emit signals so UI updates
    player_state.healthChanged.emit()
    player_state.armorChanged.emit()
    player_state.manaChanged.emit()
    
    # Weapons
    player.hotbar_data = hotbar_data.duplicate(true)
    player.current_slot = current_slot
    player.cooldown = cooldown.duplicate()
    player.max_cooldown = max_cooldown.duplicate()
    
    # Re-equip current weapon if there was one
    if current_slot != -1 and player.hotbar_data[current_slot]["scene"] != null:
        player.equip(current_slot)
    
    player.update_hotbar_ui()
    
    print("GameData restored! floor: ", floor, " HP: ", current_health, "/", max_health)

func add_coins(amount:int):
    coins += amount

func add_foods(amount:int):
    food += amount