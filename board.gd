extends Panel

const TILE = preload("res://Tile.tscn")
const tile_width = 32;
export var ROWS = 12;
export var COLUMNS = 12;
var tileArray = []
var quadrant_roll
var color_roll

signal roll_dice()
signal place_building()

# Called when the node enters the scene tree for the first time.
func _ready():
	draw_board_tiles()
	center_on_screen()
	position_roll_btn()


func center_on_screen():
	var x_offset = COLUMNS * tile_width * -1 / 2
	rect_position = rect_position + Vector2(x_offset, 0)


func position_roll_btn():
	var roll_box = get_node("RollVBox")
	var pos = roll_box.get_position()
	roll_box.set_position(Vector2(pos.x + ROWS * tile_width / 2 - 55, pos.y + COLUMNS * tile_width + 25))


func getAdjacentTiles(x, y):
	var adjacent = []
	if x > 1:
		adjacent.append(tileArray[x-1][y])
	if x < COLUMNS-1:
		adjacent.append(tileArray[x+1][y])
	if y > 1:
		adjacent.append(tileArray[x][y+1])
	if y < ROWS-1:
		adjacent.append(tileArray[x][y-1])
	return adjacent
		

master func request_place_building(x, y, color):
	print("x: " + str(x) + " y: " + str(y))
	var tile = tileArray[x][y]
	if tile.quadrant != quadrant_roll:
		print("quadrant wrong " + str(tile.quadrant) + " " + str("quadrant roll: ") + str(quadrant_roll))
		return
	if tile.color != null:
		print("already has building")
		return		
	var adjacent = getAdjacentTiles(x, y)
	for adj in adjacent:
		if adj.color != null and adj.color != color:
			print("adjacent has building")
			return
	rpc("building_placed", x, y, color)


func get_building_chain(x, y, color):
	var seen = [Vector2(x,y)]
	var chain = [Vector2(x,y)]
	var tile = tileArray[x][y]
	


remotesync func building_placed(x, y, color):
	print("building placed: " + str(color))
	tileArray[x][y].set_color(color)


func tile_clicked(x, y):
	emit_signal("place_building", x, y, color_roll)


func draw_board_tiles():
	for i in range(ROWS):
		tileArray.append([])
		for j in range(COLUMNS):
			var corner = false
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
			if j >= 3 && j < 9 && i >= 3 && i < 9:
				if (i == 3 && j == 3) || (i == 3 && j == 8) || (i == 8 && j == 3) || (i == 8 && j == 8):
					corner = true
				if corner == false:
					quadrant = 5
			var tile_instance = TILE.instance()
			tile_instance.init(quadrant)
			tile_instance.set_position(Vector2(i*tile_width, j*tile_width))
			tile_instance.x = i
			tile_instance.y = j
			$Tiles_Container.add_child(tile_instance)
			tileArray[i].append(tile_instance)
			tile_instance.connect("on_tile_clicked", self, "tile_clicked")


func _on_Roll_button_up():
	emit_signal("roll_dice")

func get_color_from_num(color_num):
	#1 red 2 yellow 3 green 4 blue 5 & 6 white
	if color_num == 1:
		return gamestate.Stock_Color.RED
	if color_num == 2:
		return gamestate.Stock_Color.YELLOW
	if color_num == 3:
		return gamestate.Stock_Color.GREEN				
	if color_num == 4:
		return gamestate.Stock_Color.BLUE		


remotesync func dice_rolled(quadrant, color_num):
	$RollVBox/DiceRoll.play()
	$RollVBox/StockChoices.hide()	
	quadrant_roll = quadrant
	color_roll = get_color_from_num(color_num)
	var frame = 0
	#1 red 2 yellow 3 green 4 blue 5 & 6 white
	if color_num <= 4:
		frame = quadrant_roll + color_num * 6 - 1
	else:
		frame = quadrant_roll - 1
		$RollVBox/StockChoices.show()	
	$RollVBox/Dice.frame = frame
	

func set_dice_image(quadrant, color_num):
	var frame = 0
	#1 red 2 yellow 3 green 4 blue 5 & 6 white
	if color_num <= 4:
		frame = quadrant + color_num * 6 - 1
	else:
		frame = quadrant_roll - 1
	$RollVBox/Dice.frame = frame


func _on_StockChoices_stock_picked(color):
	var color_num = 0
	if quadrant_roll == 0:
		return
	if color == gamestate.Stock_Color.RED:
		color_num = 1
	elif color == gamestate.Stock_Color.YELLOW:
		color_num = 2		
	elif color == gamestate.Stock_Color.GREEN:
		color_num = 3		
	elif color == gamestate.Stock_Color.BLUE:
		color_num = 4
	set_dice_image(quadrant_roll, color_num)
	color_roll = color				
