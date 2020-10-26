extends Control

const TILE = preload("res://Tile.tscn")
const tile_width = 32;
export var ROWS = 12;
export var COLUMNS = 12;
var tileArray = []

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_board_tiles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func tile_clicked(tile):
	print('tile clicked')

func draw_board_tiles():
	for i in range(ROWS):
		tileArray.append([])
		for j in range(COLUMNS):
			var quadrant = 0
			if j < COLUMNS/2:
				if i < ROWS/2:
					quadrant = 1
				else:
					quadrant = 2
			else:
				if i < ROWS/2:
					quadrant = 3
				else:
					quadrant = 4
			var tile_instance = TILE.instance()
			tile_instance.init(quadrant)
			tile_instance.connect("on_tile_clicked", self, "tile_clicked")
			tile_instance.set_position(Vector2(i*tile_width, j*tile_width))
			add_child(tile_instance)
			tileArray[i].append(tile_instance)
