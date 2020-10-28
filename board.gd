extends Panel

const TILE = preload("res://Tile.tscn")
const tile_width = 32;
export var ROWS = 12;
export var COLUMNS = 12;
var tileArray = []

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_board_tiles()
	#center_on_screen()


func center_on_screen():
	var x_offset = COLUMNS * tile_width * -1
	var y_offset = ROWS * tile_width * -1
	print(x_offset)
	print(y_offset)
	print(rect_position)
	rect_position = rect_position + Vector2(x_offset, y_offset)
	print(rect_position)

func tile_clicked():
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
			tile_instance.set_position(Vector2(i*tile_width, j*tile_width))
			add_child(tile_instance)
			tileArray[i].append(tile_instance)
			tile_instance.connect("on_tile_clicked", self, "tile_clicked")
