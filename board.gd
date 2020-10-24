extends Node2D

const TILE = preload("res://tile.tscn")
const tile_width = 40;
var ROWS = 5;
var COLUMNS = 5;

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_board_tiles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func draw_board_tiles():
	for i in range(ROWS):
		for j in range(COLUMNS):
			var tile_instance = TILE.instance()
			tile_instance.position = Vector2(i*tile_width, j*tile_width);
			add_child(tile_instance)
