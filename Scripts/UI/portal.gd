extends Area2D

var sprite: Sprite2D

func _ready():
    sprite = $Sprite2D
    self.visible = false
    # Signal is now connected from DungeonGenerator when portal activates
    # so we don't connect it here anymore

# func _on_body_entered(body):
#     if body.is_in_group("Player"):
#         print("Player entered the portal!")