extends SubViewport

@export var player : Node3D
@export var world_extents : Rect2

func _Draw(): 
	$Background.modulate = Color(1,1,1,0);

func _process(delta):
	var half_world_extents = world_extents.size * 0.5
	var player_pos = Vector2(player.position.x, player.position.z)
	
	player_pos += half_world_extents
	var paintbrush_position = player_pos / world_extents.size
	
	$SnowPaintbrush.position = paintbrush_position * Vector2(self.size)
