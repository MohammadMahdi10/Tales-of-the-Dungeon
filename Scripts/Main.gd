extends Node2D

#-----CONSTANTS-----

#Preloaded scenes to be used for randomisation of spawns
const EnemyScene = preload("res://Scenes/Enemy.tscn")
const CoinScene = preload("res://Scenes/Coin.tscn")
const LadderScene = preload("res://Scenes/Ladder.tscn")
const SpeedScene = preload("res://Scenes/Speed.tscn")
const RegenScene = preload("res://Scenes/Regeneration.tscn")
const StrengthScene = preload("res://Scenes/Strength.tscn")
const BossScene = preload("res://Scenes/Boss.tscn")

#Creating a tile map reference to be used throughout program
onready var tileMap = $TileMap

#Sizes of the tiles and levels
const tileSize = 32 #Sets the default tile size to 32
const levelSizes = [Vector2(35,35), Vector2(35,35),Vector2(35, 35),Vector2(35, 35)] #Sets the x,y of the levels per floor of entire map

#Number of enities per room with the 0th position being first floor
const numberOfRooms = [1, 1, 1, 1] #Number of rooms per floor
const numberOfEnemies = [11, 12, 13, 0] #Number of enemies per floor
const numberOfBoss = [0, 0, 0, 1] #Number of bosses per floor
const numberOfLadders = [1, 1, 1, 0] #Number of ladders per floor
const numberOfCoins = [9, 10, 11, 0] #Number of items per floor
const numberOfSpeed = [1, 1, 3, 5] #Number of speed potions per floor
const numberOfRegen = [0, 2, 2, 6] #Number of regeneration potions per floor
const numberOfStrength = [0, 1, 1, 4] #Number of strength potions per floor

#How small/large per room of the floors
const minimumDimension = 30
const maximumDimension = 50

#Setting the Tile to respective names. These are the tiles to be called using Tile. Sets tiles of the room
enum Tile {Wall, Door, Floor, Ladder, Stone} #Sets values in the enum to be called by using Tile (These are the tiles in the game)

#-----VARIABLES-----

#Item Attributes (variables)
var coins = [] #Creates an empty list of coins
var coin = 0
var enemyCount = 0
var bossCount = 0
var speedList = [] #Creates an empty list of speed potions
var regenList = [] #Creates an empty list of regeneration potions
var strengthList = [] #Creates an empty list of strength potions

#Enemy Attributes
var enemies = [] #Creates an empty list of enemies
var bosses = [] #Creates an empty list of bosses

#Item Conditions
var enemiesDefeated = false
var bossDefeated = false
var strengthBossActive = false
var coinsCollected = false

#Floor/room attributes
var floorNumber = 0
var sizeOfLevel #Creates a variable to be manipulated later. Determines the size per level
var map = [] #Creates an empty list of map
var rooms = [] #Creates an empty list of rooms
var ladders = [] #Creates an empty list of ladders

#-----MAIN PROGRAM-----

func _ready():
	#Setting the background coins to automatically play and the title screen music
	$Background/CoinAnimated.play("CoinSpin")
	$Background/CoinAnimated2.play("CoinSpin")
	$TitleMusic.play()
	
	#All singletons to connect various parts of the program to the main user interface of the game
	CoinSingleton.connect("coinIncrement", self, "coinConfigure")
	HealthSingleton.connect("HealthDamage", self, "onDamageTaken")
	BossReductionSingleton.connect("bossHealth", self, "onBossDamage")
	LadderSingleton.connect("ladderEnter", self, "onLadderStep")
	CoinCounter.connect("enemyCoinIncrement", self, "enemyCoinIncrement")
	SpeedSingleton.connect("speedIncrement", self, "speedUpdateVisible")
	SpeedUpdateVisibility.connect("speedVisibility", self, "speedUpdateInvisible")
	BossCoinCounter.connect("bossCoin", self, "bossCoinIncrement")
	RegenerationSingleton.connect("regenerationIncrement", self, "toPlayerRegenPotion")
	StrengthSingleton.connect("strengthIncrement", self, "toStrengthVisibility")
	StrengthInvisibilitySingleton.connect("strengthInvisibility", self, "toStrengthInvisibility")
	StrengthSingleton.connect("strengthIncrement", self, "toStrengthActivate")
	
	$Player.queue_free() #Ensures that the screen automatically fills the screen without the player shifting the screen to a random position
	OS.set_window_size(Vector2(1280, 720)) #Sets the window size of the program
	randomize() #Sets up random number generator so that "randi()" and other random functions can be called

func build_level():
	#If the floor is on the boss floor, play another music and change various other things
	if floorNumber >= 3:
		$BackgroundMusic.stop()
		$BossMusic.play()
	$CanvasLayer/ColorRect/Floor.text = str(floorNumber) + "F"
	$CanvasLayer/ColorRect/Coin.text = str(coin)
	$CanvasLayer/ColorRect/EnemyCounter.text = str(enemyCount)
	$CanvasLayer/ColorRect2/Strength2.visible = false
	
	#Makes sure everything is empty before the level generation begins
	rooms.clear()
	map.clear()
	tileMap.clear()
	
	RemoveEnemySingleton.enemyRemoval()
	RemoveCoinSingleton.coinRemoval()
	RemoveSpeedSingleton.speedRemoval()
	RemoveRegenSingleton.regenRemoval()
	RemoveLadderSingleton.ladderRemoval()
	RemoveStrengthSingleton.strengthRemoval()
	
	sizeOfLevel = levelSizes[floorNumber] #Sets the size of the level respective to the level size of the floor number. Example: If floor number = 1, then item position in levelSizes 1 is formed
	map = [] #New map list created
	for x in range(sizeOfLevel.x): #Loop through the rows of the entire map
		var row = [] #New row list created for stone tiles
		for y in range(sizeOfLevel.y): #Loop through the column of the entire map
			row.append(Tile.Stone) #Sets them as stone tiles
		map.append(row) #Adds the row to the map
		for y in range(sizeOfLevel.y):
			tileMap.set_cell(x, y, Tile.Stone) #Sets the cells (like tiles/pixel) on the tile map to stone
	
	#Amount of free space in the level and creating a retangular region to be filled
	var startingPosition = Vector2(2, 2) #Sets the position of rectangular space near the top left corner
	var amountOfFreeSpace = levelSizes[floorNumber] - Vector2(4, 4) #Calculates amount of free space by subtracting from fixed x,y
	var newRectSpace = Rect2(startingPosition, amountOfFreeSpace) #Making a free rectangular space by taking the startingPosition in the left corner and the size
	var freeRegions = [newRectSpace] #Storing this into a free regions variable which conatins all free spaces in the floor

	#Placing the rooms of the floor
	var numberRooms = numberOfRooms[floorNumber] #This line retrieves the number of rooms to add to the level
	for i in range(numberRooms): #Iterates through numberRooms to then add a new room to the level
		addToRoom(freeRegions) #This function is responsible to add the rooms 
		if freeRegions.empty(): #If there are no more free rectangular space, stop adding
			break

	#Placing the enemies on the floor randomly
	var numberOfEnemiesFloor = numberOfEnemies[floorNumber] #Sets the amount of enemies with the respective floor number
	for i in range(numberOfEnemiesFloor): #Amount of enemies that it will process
		var enemyRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the enemy in the relative x,y of the room sizes
		var xEnemy = enemyRoom.position.x + 1 + randi() % int(enemyRoom.size.x - 2)
		var yEnemy = enemyRoom.position.y + 1 + randi() % int(enemyRoom.size.y - 2)
		
		#Checks if enemies are both spawning in the same location. If so, no enemy spawns
		var checkBlocked = false
		for enemy in enemies:
			if enemy.tile.x == xEnemy and enemy.tile.y == yEnemy:
				checkBlocked = true
				break
		
		#If there are no enemies in the same location, sends it to a class to create enemy instance. Then appends that enemy to the list
		if checkBlocked == false:
			var enemy = Enemy.new(self, xEnemy, yEnemy)
			enemies.append(enemy)
	
	#Placing the coins on the floor randomly
	var numberOfCoinsFloor = numberOfCoins[floorNumber] #Sets the amount of coins with the respective floor number
	for i in range(numberOfCoinsFloor): #Amount of coins that it will process
		var coinRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the coins in the relative x,y of the room sizes
		var xCoin = coinRoom.position.x + 1 + randi() % int(coinRoom.size.x - 2)
		var yCoin = coinRoom.position.y + 1 + randi() % int(coinRoom.size.y - 2)
		
		#Checks if coins are both spawning in the same location. If so, no coin spawns
		var coinBlocked = false
		for coin in coins:
			if coin.tile.x == xCoin and coin.tile.y == yCoin:
				coinBlocked = true
				break
				
		#If there are no coins in the same location, sends it to a class to create coin instance. Then appends that coin to the list
		if coinBlocked == false:
			var coin = Coin.new(self, xCoin, yCoin)
			coins.append(coin)
	
	#Placing the ladders on the floor randomly
	var numberOfLaddersFloor = numberOfLadders[floorNumber] #Sets the amount of ladders with the respective floor number
	for i in range(numberOfLaddersFloor): #Amount of ladders that it will process
		var ladderRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the ladders in the relative x,y of the room sizes
		var xLadder = ladderRoom.position.x + 1 + randi() % int(ladderRoom.size.x - 2)
		var yLadder = ladderRoom.position.y + 1 + randi() % int(ladderRoom.size.y - 2)
		
		#Checks if ladders are both spawning in the same location. If so, no ladder spawns
		var ladderBlocked = false
		for ladder in ladders:
			if ladder.tile.x == xLadder and ladder.tile.y == yLadder:
				ladderBlocked = true
				break
				
		#If there are no ladders in the same location, sends it to a class to create ladder instance. Then appends that ladder to the list
		if ladderBlocked == false:
			var ladder = Ladder.new(self, xLadder, yLadder)
			ladders.append(ladder)
	
	#Placing the speed potions on the floor randomly
	var numberOfSpeedFloor = numberOfSpeed[floorNumber] #Sets the amount of speed potions with the respective floor number
	for i in range(numberOfSpeedFloor): #Amount of speed potions that it will process
		var speedRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the speed potions in the relative x,y of the room sizes
		var xSpeed = speedRoom.position.x + 1 + randi() % int(speedRoom.size.x - 2)
		var ySpeed = speedRoom.position.y + 1 + randi() % int(speedRoom.size.y - 2)
		
		#Checks if speed potions are both spawning in the same location. If so, no speed potion spawns
		var speedBlocked = false
		for swift in speedList:
			if swift.tile.x == xSpeed and swift.tile.y == ySpeed:
				speedBlocked = true
				break
		
		#If there are no speed potions in the same location, sends it to a class to create speed potion instance. Then appends that speed potion to the list
		if speedBlocked == false:
			var speed = Speed.new(self, xSpeed, ySpeed)
			speedList.append(speed)
	
	#Placing the regeneration potions on the floor randomly
	var numberOfRegenFloor = numberOfRegen[floorNumber] #Sets the amount of regeneration potions with the respective floor number
	for i in range(numberOfRegenFloor): #Amount of regeneration potions that it will process
		var regenRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the regeneration potions in the relative x,y of the room sizes
		var xRegen = regenRoom.position.x + 1 + randi() % int(regenRoom.size.x - 2)
		var yRegen = regenRoom.position.y + 1 + randi() % int(regenRoom.size.y - 2)
		
		#Checks if regeneration potions are both spawning in the same location. If so, no regeneration potion spawns
		var regenBlocked = false
		for heal in regenList:
			if heal.tile.x == xRegen and heal.tile.y == yRegen:
				regenBlocked = true
				break
		
		#If there are no regeneration potions in the same location, sends it to a class to create regeneration potion instance. Then appends that regeneration potion to the list
		if regenBlocked == false:
			var healing = Regeneration.new(self, xRegen, yRegen)
			regenList.append(healing)
	
	#Placing the strength potions on the floor randomly
	var numberOfStrengthFloor = numberOfStrength[floorNumber] #Sets the amount of strength potions with the respective floor number
	for i in range(numberOfStrengthFloor): #Amount of strength potions that it will process
		var strengthRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the strength potions in the relative x,y of the room sizes
		var xStrength = strengthRoom.position.x + 1 + randi() % int(strengthRoom.size.x - 2)
		var yStrength = strengthRoom.position.y + 1 + randi() % int(strengthRoom.size.y - 2)
		
		#Checks if strength potions are both spawning in the same location. If so, no strength potion spawns
		var strengthBlocked = false
		for strength in strengthList:
			if strength.tile.x == xStrength and strength.tile.y == yStrength:
				strengthBlocked = true
				break
		
		#If there are no strength potions in the same location, sends it to a class to create strength potion instance. Then appends that strength potion to the list
		if strengthBlocked == false:
			var strengthen = Strength.new(self, xStrength, yStrength)
			strengthList.append(strengthen)
	
	#Placing the boss on the floor randomly
	var numberOfBossFloor = numberOfBoss[floorNumber] #Sets the amount of bosses with the respective floor number
	for i in range(numberOfBossFloor): #Amount of bosses that it will process
		var bossRoom = rooms.front() #Gets the first element of the rooms list
		#Sets the random position of the bosses in the relative x,y of the room sizes
		var xBoss = bossRoom.position.x + 1 + randi() % int(bossRoom.size.x - 2)
		var yBoss = bossRoom.position.y + 1 + randi() % int(bossRoom.size.y - 2)
		
		#Checks if bosses are both spawning in the same location. If so, no boss spawns
		var bossBlocked = false
		for boss in bosses:
			if boss.tile.x == xBoss and boss.tile.y == yBoss:
				bossBlocked = true
				break
		
		#If there are no bosses in the same location, sends it to a class to create boss instance. Then appends that boss to the list
		if bossBlocked == false:
			var boss = Boss.new(self, xBoss, yBoss)
			bosses.append(boss)

#Function to determine the free regions, then add rooms where regions are free
func addToRoom(freeRegions):
	var region = freeRegions[randi() % freeRegions.size()] #Selects random region from list of free regions
	
	#Determine the dimensions of the new room
	var xWidth = minimumDimension #Sets the width of the rectangle
	if region.size.x > minimumDimension: #This line checks if the width of the region is greater than the minimumDimension. Checks if the width needs adjustment
		xWidth += randi() % int(region.size.x - minimumDimension) #If so, sets random width in between values of the region size taken from minimum dimension 
		
	var yHeight = minimumDimension #Sets the height of the rectangle
	if region.size.y > minimumDimension:  #This line checks if the height of the region is greater than the minimumDimension. Checks if the height needs adjustment
		yHeight += randi() % int(region.size.y - minimumDimension) #If so, sets random height in between values of the region size taken from minimum dimension 
		
	#Ensure that both the width and height does not go above the maximum dimension, hence min used
	xWidth = min(xWidth, maximumDimension)
	yHeight = min(yHeight, maximumDimension)
	
	#Determining starting positions of the room
	var xStart = region.position.x #Retrieves the x-coordinate of the region. Represents starting x position
	if region.size.x > xWidth: #Checks if the width of the region is bigger than the width of the smallest dimension
		xStart += randi() % int(region.size.x - xWidth) #Randomly generates a number between 0 and taken value of the region size and width for random starting x position for the room 
		
	var yStart = region.position.y #Retrieves the y-coordinate of the region. Represents starting y position
	if region.size.y > yHeight: #Checks if the height of the region is bigger than the height of the smallest dimension
		yStart += randi() % int(region.size.y - yHeight) #Randomly generates a number between 0 and taken value of the region size and height for random starting y position for the room
			
	var room = Rect2(xStart, yStart, xWidth, yHeight) #This creates the room using the calculations to define the positions and dimensions of the room. Room variable contains all information to make a rectangular room
	rooms.append(room) #Appending all the newly created rooms into a list
	
	#Sets the tile of the floor to either a wall or a floor
	for x in range(xStart, xStart + xWidth): #Loops through every tile from left and right of the room
		tileSet(x, yStart, Tile.Wall) #Sets the top tile to a wall
		tileSet(x, yStart + yHeight - 1, Tile.Wall) #Sets the bottom tile to a wall
		
		for y in range(yStart + 1, yStart + yHeight - 1): #Iterates over every from top to bottom
			tileSet(xStart, y, Tile.Wall) #Sets the left side of the room to become a wall
			tileSet(xStart + xWidth - 1, y, Tile.Wall) #Sets the right side of the room to become a wall
			
			#This represents the horizontal ranges of the room
			for newX in range(xStart + 1, xStart + xWidth - 1):
				tileSet(newX, y, Tile.Floor) #Lastly, sets the canvas of the room to become the floor

	deleteRegions(freeRegions, room)

func deleteRegions(freeRegions, roomRemoval): #Function to check any free regions to add or remove
	var roomRemovalList = [] #List to store all removed rooms
	var roomAddedList = [] #List to store all added rooms
	
	for rooms in freeRegions: #Looping over each of the rooms object in the freeRegions list
		if rooms.intersects(roomRemoval): #Checks if the current rooms overlaps with the roomRemoval
			roomRemovalList.append(rooms) #If an intersection is found, it is added to the room removal list
			
			#These are calculating all the space that are free from relative positons of the roomRemoval and the rooms (all free rooms in free region)
			var freeSpaceLeft = roomRemoval.position.x - rooms.position.x - 1 #Calculates amount of available space on the left side of the roomRemoval region. Then it subtracts the x-position of the rooms from the x-position of the roomRemoval. It then subtracts an additional 1 because there is a wall.
			var freeSpaceRight = rooms.end.x - roomRemoval.end.x - 1 ##Calculates amount of available space on the right side of the roomRemoval region. Then it subtracts the x-position of the rooms from the x-position of the roomRemoval. It then subtracts an additional 1 because there is a wall.
			var freeSpaceUp = roomRemoval.position.y - rooms.position.y - 1 #Calculates amount of available space on the top side of the roomRemoval region. Then it subtracts the y-position of the rooms from the y-position of the roomRemoval. It then subtracts an additional 1 because there is a wall.
			var freeSpaceDown = rooms.end.y - roomRemoval.end.y - 1 #Calculates amount of available space on the bottom side of the roomRemoval region. Then it subtracts the y-position of the rooms from the y-position of the roomRemoval. It then subtracts an additional 1 because there is a wall.
			
			if freeSpaceLeft >= minimumDimension: #Checking if there is available space on the left is greater than or equal to the minimum dimension required
				var newPositionRoom = rooms.position #Calculate new position to be equal to current position
				var newSize = Vector2(freeSpaceLeft, rooms.size.y) #Calculate size of the new region to be the width of the available space on the left and the same height as the current region
				var newRoom = Rect2(newPositionRoom, newSize) #Create new rectangle with new position and size
				roomAddedList.append(newRoom) #Add this new room to the list
				
			if freeSpaceRight >= minimumDimension: #Checking if there is available space on the right is greater than or equal to the minimum dimension required
				var newPositionRoom = Vector2(roomRemoval.end.x + 1, rooms.position.y) #Calculate new position to be equal to current position
				var newSize = Vector2(freeSpaceRight, rooms.size.y) #Calculate size of the new region to be the width of the available space on the right and the same height as the current region
				var newRoom = Rect2(newPositionRoom, newSize) #Create new rectangle with new position and size
				roomAddedList.append(newRoom) #Add this new room to the list
				
			if freeSpaceUp >= minimumDimension: #Checking if there is available space above is greater than or equal to the minimum dimension required
				var newPositionRoom = rooms.position #Calculate new position to be equal to current position
				var newSize = Vector2(rooms.size.x, freeSpaceUp) #Calculate size of the new region to be the height of the available space on the top and the same width as the current region
				var newRoom = Rect2(newPositionRoom, newSize) #Create new rectangle with new position and size
				roomAddedList.append(newRoom) #Add this new room to the list
				
			if freeSpaceDown >= minimumDimension: #Checking if there is available space below is greater than or equal to the minimum dimension required
				var newPositionRoom = Vector2(rooms.position.x, roomRemoval.end.y + 1) #Calculate new position to be equal to current position
				var newSize = Vector2(rooms.size.x, freeSpaceDown) #Calculate size of the new region to be the height of the available space at the bottom and the same width as the current region
				var newRoom = Rect2(newPositionRoom, newSize) #Create new rectangle with new position and size
				roomAddedList.append(newRoom) #Add this new room to the list
	
	#Remove regions in the roomRemovalList from the free regions list
	for region in roomRemovalList:
		freeRegions.erase(region)
	
	#Add all new regions to the free regions list
	freeRegions += roomAddedList

func tileSet(x, y, typeOfTile):
	map[x][y] = typeOfTile #Sets the x,y to the array of map to the type of tile
	tileMap.set_cell(x, y, typeOfTile) #Sets the tile at specified positions
	
#-----CLASSES TO INSTANTIATE ENTITIES-----

class Enemy: #Holds all enemy attributes and methods
	var enemyNode
	var tile #Enemy position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the enemy
		enemyNode = EnemyScene.instance() #Creating instance of the enemy scene
		enemyNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(enemyNode) #Adding it as a child node

class Coin: #Holds all coin attributes and methods
	var coinNode 
	var tile #Coin position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the coin
		coinNode = CoinScene.instance() #Creating instance of the coin scene
		coinNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(coinNode) #Adding it as a child node

class Ladder: #Holds all ladder attributes and methods
	var ladderNode
	var tile #Ladder position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the ladder
		ladderNode = LadderScene.instance() #Creating instance of the ladder scene
		ladderNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(ladderNode) #Adding it as a child node

class Speed: #Holds all speed potion attributes and methods
	var speedNode
	var tile #Speed potion position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the speed potion
		speedNode = SpeedScene.instance() #Creating instance of the speed potion scene
		speedNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(speedNode) #Adding it as a child node

class Regeneration: #Holds all regeneration potion attributes and methods
	var regenNode
	var tile #regeneration potion position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the regeneration potion
		regenNode = RegenScene.instance() #Creating instance of the regeneration potion scene
		regenNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(regenNode) #Adding it as a child node

class Strength: #Holds all strength potion attributes and methods
	var strengthNode
	var tile #strength potion position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the strength potion
		strengthNode = StrengthScene.instance() #Creating instance of the strength potion scene
		strengthNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(strengthNode) #Adding it as a child node

class Boss: #Holds all boss attributes and methods
	var bossNode
	var tile #Boss position

	func _init(game, x, y):
		tile = Vector2(x, y) #Setting the tile location of the boss
		bossNode = BossScene.instance() #Creating instance of the boss scene
		bossNode.position = tile * tileSize #Setting the tile to coordinates of the map
		game.add_child(bossNode) #Adding it as a child node

#-----FUNCTIONS THAT MAKE NODES WORK AND CONNECT SINGLETONS-----

func onLadderStep():	
	floorNum() #When the player steps on the ladder, the floor number increments by one
	build_level() #Runs the build level function so that after stepping on the ladder, a new level is generated

func floorNum():
	floorNumber += 1 #Increments the floor level by one
	#If the floor number is the boss level, make the boss health bar visible and it's head (on the rect)
	if floorNumber == 3:
		$CanvasLayer/ColorRect/BossHealthBar.visible = true #If the floor number is the third floor, the boss health bar is visible
		$CanvasLayer/ColorRect/BossHead.visible = true #When you reach the third floor, boss head visible

#Player Node Functions
func updateHealth():
	var healthBar = $CanvasLayer/ColorRect/HealthBar #Sets the variable to the health bar node
	healthBar.value = PlayerHealthSingleton.health #Sets the value of the health bar to be the health
	
	if PlayerHealthSingleton.health >= 75:
		healthBar.modulate = Color(0, 1, 0) #If the player health is above 75, the colour green is dark
	
	if PlayerHealthSingleton.health < 75:
		healthBar.modulate = Color(0, 2, 0) #If the player health is below 75, the colour green is brighter
	
	if PlayerHealthSingleton.health < 50:
		healthBar.modulate = Color(2, 2, 0) #If the player health is below 50, the colour changes to yellow	
		
	if PlayerHealthSingleton.health < 25:
		healthBar.modulate = Color(2, 0, 0) #If the player health is below 25, the colour changes to red

func _on_RegenerationTimer_timeout():
	if PlayerHealthSingleton.health < 100: 
		PlayerHealthSingleton.health += 2 #After every 12 seconds, if health of player below 100, increases by 2 hp
		updateHealth() #Updates the health bar so visually can see change
	if PlayerHealthSingleton.health > 100:
		PlayerHealthSingleton.health = 100 #Sets the player health to be 100 if it goes past 100. This ensures no excess health
	if PlayerHealthSingleton.health <= 0:
		PlayerHealthSingleton.health = 0 #Sets the player health to be 0 if it goes below 0. This ensures the player hp is not negative

func onDamageTaken():
	if floorNumber == 3:
		PlayerHealthSingleton.health -= 5 #This only applies to the boss. If the player is on the third floor, the boss does 5 hp worth of damage
		updateHealth() #Updates the health bar accordingly due to hp damage taken by the player from the boss
	else:
		PlayerHealthSingleton.health -= randi() % 2 + 1 #This applies to the other enemies. If floor number below 3, random number generated between 1 and 2 to do damage to player
		updateHealth() #Updates the health bar accordingly due to hp damage taken by the player from the enemies
	
	if PlayerHealthSingleton.health <= 0:
		PlayerHealthSingleton.health = 0 #This ensures that the player does not take any excess damage and goes to negative numbers. Stays at zero
		$Player.queue_free() #Remove the player from the node tree
		#Makes sure the entire rects are gone. This is to enable the lose screen
		$CanvasLayer/ColorRect.visible = false
		$CanvasLayer/ColorRect2.visible = false
		$CanvasLayer/ColorRect3.visible = false
		$CanvasLayer/Lose.visible = true #Show the lose screen
		$CanvasLayer/Lose/CoinText.text = "Coins Collected: " + str(coin)
		$CanvasLayer/Lose/EnemyText.text = "Enemies Defeated: " + str(enemyCount)
		$CanvasLayer/Lose/BossText.text = "Bosses Defeated: " + str(bossCount) 
		$CanvasLayer/RegenerationTimer.stop() #Stop increasing the the regeneration timer as when the player dies, the hp bar is static
		$BackgroundMusic.stop() #When player dies, the music stops
		$BossMusic.stop() #Boss music also stops (in case they die in the boss floor)

#Enemy Functions
func enemyCoinIncrement():
	coin += 5 #Adds 5 coins to the total counter if enemies killed
	$CanvasLayer/ColorRect/Coin.text = str(coin) #Updates the coin counter accordingly
	checkCoins() #Checks if the coins are above 250. If so, tick the box on the right of the screen
	enemyCount += 1
	$CanvasLayer/ColorRect/EnemyCounter.text = str(enemyCount)
	checkEnemy() #Checks if the enemy count is above 25. If so, tick the box on the right of the screen

func checkEnemy():
	#Checks if the amount of enemy kills is above a certain number
	if enemyCount >= 25:
		$CanvasLayer/ColorRect3/Tick2.visible = true
		enemiesDefeated = true

#Boss Node Functions
func bossUpdateHealth():
	#Connects the health bar of the boss to the health of the boss
	var enemyHealthBar = $CanvasLayer/ColorRect/BossHealthBar #Sets a variable to the boss health bar on the tree
	enemyHealthBar.value = BossHealth.bossHealth #Sets the value of the enemy health bar to equal max hp of the boss

func onBossDamage():
	if strengthBossActive == false: #Checks if the strength potion is active for the player. Does respective damages if turned on or off
		BossHealth.bossHealth -= 10 #When the player does damage to the boss, the boss health is reduced by 10
		bossUpdateHealth() #Updates the health of the boss so can visually see change
	else:
		BossHealth.bossHealth -= 22 #When the player does damage to the boss and strength potion is active, the boss health is reduced by 22
		bossUpdateHealth() #Updates the health of the boss so can visually see change
	
	if BossHealth.bossHealth <= 0:
		bossDefeated = true
		bossCount += 1
		BossHealth.bossHealth = 0 #Sets the boss hp to 0 so it does not go below 0
		BossCoinCounter.bossCoinEmit() #Sends a signal so that then the boss dies, it makes it so the boss increments the coin counter
		RemoveEnemySingleton.enemyRemoval() #Removes the boss from the floor
		$CanvasLayer/ColorRect3/Tick3.visible = true
		if bossDefeated == true and coinsCollected == true and enemiesDefeated == true: #Conditions to play respective end screens
			#If the player wins the game properly by completing all objectives
			$Player.queue_free()
			$CanvasLayer/ColorRect.visible = false
			$CanvasLayer/ColorRect2.visible = false
			$CanvasLayer/ColorRect3.visible = false
			$CanvasLayer/WinGame.visible = true
			$CanvasLayer/WinGame/CoinAnimated.play("CoinSpin")
			$CanvasLayer/WinGame/CoinAnimated2.play("CoinSpin")
			$CanvasLayer/WinGame/CoinText.text = "Coins Collected: " + str(coin)
			$CanvasLayer/WinGame/EnemyText.text = "Enemies Defeated: " + str(enemyCount)
			$CanvasLayer/WinGame/BossText.text = "Bosses Defeated: " + str(bossCount)
		else:
			#If the player beats the boss only without completing the objectives
			$Player.queue_free()
			$CanvasLayer/ColorRect.visible = false
			$CanvasLayer/ColorRect2.visible = false
			$CanvasLayer/ColorRect3.visible = false
			$CanvasLayer/BossDefeat.visible = true
			$CanvasLayer/BossDefeat/CoinText.text = "Coins Collected: " + str(coin)
			$CanvasLayer/BossDefeat/EnemyText.text = "Enemies Defeated: " + str(enemyCount)
			$CanvasLayer/BossDefeat/BossText.text = "Bosses Defeated: " + str(bossCount)

func bossCoinIncrement():
	coin += 100 #Adds 100 coins to the total counter if boss killed
	$CanvasLayer/ColorRect/Coin.text = str(coin) #Updates the coin counter accordingly
	checkCoins() #Checks if the coins are above 250. If so, tick the box on the right of the screen

#Coin Functions
func coinConfigure():
	coin += 1 #Increments the coins by one if the coins are collected
	$CanvasLayer/ColorRect/Coin.text = str(coin) #Updates the coin text accordingly
	checkCoins() #Checks if the coins are above 250. If so, tick the box on the right of the screen

func checkCoins():
	#Checks if the amount of coins collected is above a certain number
	if coin >= 250:
		$CanvasLayer/ColorRect3/Tick.visible = true
		coinsCollected = true

#Potion Functions
func speedUpdateVisible():
	$CanvasLayer/ColorRect2/Speed2.visible = true #So you can see the speed symbol. This shows if speed activated

func speedUpdateInvisible():
	$CanvasLayer/ColorRect2/Speed2.visible = false #So you can not see the speed symbol. This shows if speed deactivated

func toPlayerRegenPotion():
	#Starts both timers, one of the duration of the regeneration potion and one for the potion increment
	$CanvasLayer/RegenTimer.start() #Amount of health gained per 0.4 seconds
	$CanvasLayer/RegenStopTimer.start() #To stop the whole duration of the regeneration potion
	$CanvasLayer/ColorRect2/Heal2.visible = true

func _on_RegenTimer_timeout():
	#After every 0.4 seconds, increment health by one
	PlayerHealthSingleton.health += 1
	updateHealth()

func _on_RegenStopTimer_timeout():
	#After 10 seconds is done, the regeneration potion stops
	HealthCheck.healthOn = true #This is to ensure that the hearts that come out of the player during the regeneration potion stops coming out
	$CanvasLayer/ColorRect2/Heal2.visible = false
	$CanvasLayer/RegenTimer.stop()

func toStrengthActivate(): #Checks if the strength is activated and starts duration
	strengthBossActive = true #So the boss can take 22 damage from the player
	$CanvasLayer/StrengthTimer.start()

func _on_StrengthTimer_timeout(): #After it runs out, boss damage returns back to normal
	strengthBossActive = false
	toStrengthInvisibility()

func toStrengthVisibility():
	$CanvasLayer/ColorRect2/Strength2.visible = true #So you can see the strength symbol. This shows if strength activated

func toStrengthInvisibility():
	$CanvasLayer/ColorRect2/Strength2.visible = false #So you can not see the strength symbol. This shows if strength deactivated

#-----PLAYER DEATH-----

func spawnPlayer():
	var playerScene = preload("res://Scenes/Player.tscn") #Reloads the player so can spawn again on the main screen
	var player = playerScene.instance() #Creating an instance of the scene
	add_child(player) #Adding the player back to the tree
	#Sets the default player position
	$Player.position.x = 430
	$Player.position.y = 331
	#There was a bug in the game that made the player very small. Incrementing the scale of x and y of the player by 1 so it looks normal again
	$Player.scale.x = 1
	$Player.scale.y = 1

func _on_Restart_pressed():
	#Ensures that the whole game restarts as a whole
	$BossMusic.stop()
	$CanvasLayer/ColorRect.visible = true
	$CanvasLayer/ColorRect2.visible = true
	$CanvasLayer/ColorRect3.visible = true
	$CanvasLayer/ColorRect/BossHealthBar.visible = false #As you go back to first floor, boss is not there therefore you should not be able to see its health bar
	$CanvasLayer/ColorRect/BossHead.visible = false #When you go back to the first floor, the boss head disappears
	$BackgroundMusic.play() #Once restart button pressed, background music plays
	PlayerHealthSingleton.health = 100 #Sets the health of the player back to 100
	updateHealth() #Updates the health so can visually see the change in the players health
	BossHealth.bossHealth = 1000 #Sets the health of the enemy back to 500
	bossUpdateHealth() #Update the health so can see it visually
	floorNumber = 0 #Sets the floor number back to zero
	coin = 0 #Sets the coin counter back to zero
	enemyCount = 0
	build_level() #Building level again because it is generating a whole new "level"
	#If potions symbols were ever activated, sets them all to invisible
	$CanvasLayer/ColorRect2/Speed2.visible = false
	$CanvasLayer/ColorRect2/Heal2.visible = false
	$CanvasLayer/ColorRect2/Strength2.visible = false
	$CanvasLayer/WinGame.visible = false #So you can not see the win screen anymore
	$CanvasLayer/BossDefeat.visible = false #So you can not see the win screen (2) anymore
	$CanvasLayer/Lose.visible = false #So you can not see the lose screen anymore
	$CanvasLayer/RegenerationTimer.start() #So the player can regenerate health again
	#Ensures all the objectives are not checked
	$CanvasLayer/ColorRect3/Tick.visible = false
	$CanvasLayer/ColorRect3/Tick2.visible = false
	$CanvasLayer/ColorRect3/Tick3.visible = false
	spawnPlayer() #The player spawns back into the game

func _on_Start_pressed():
	if floorNumber == 0:
		$BackgroundMusic.play() #Checks if the floor is zero, If so, the song automatically plays
		$TitleMusic.stop()
	#Ensures starting screen not visible and sets rects to visible
	$Background.visible = false
	$CanvasLayer.visible = true
	spawnPlayer()
	build_level() #Calls the build level so that the level generation can be formed instantly

func _on_Controls_pressed():
	#Makes a blank canvas for only buttons to show, nothing else
	$Background/CoinAnimated.visible = false
	$Background/CoinAnimated2.visible = false
	$Background/Label.visible = false
	$Background/Start.visible = false
	$Background/Controls.visible = false
	$Background/Quit.visible = false
	$Background/Credits.visible = false
	$Background/ControlsInterface.visible = true

func _on_BackButton_pressed():
	#Ensures whole start screen is back to normal
	$Background/CoinAnimated.visible = true
	$Background/CoinAnimated2.visible = true
	$Background/Label.visible = true
	$Background/Start.visible = true
	$Background/Controls.visible = true
	$Background/Quit.visible = true
	$Background/Credits.visible = true
	$Background/ControlsInterface.visible = false

func _on_Quit_pressed(): #Closes the application
	get_tree().quit()

func _on_Credits_pressed():
	#So the credits can be seen
	$Credits.visible = true
	$Credits.scroll_offset = Vector2(0,0) #Ensures that the credits will always play from the top
	$Background.visible = false

func _on_BackButton2_pressed():
	#Returns the main screen again
	$Credits.visible = false
	$Credits.scroll_offset = Vector2(0,0)
	$Background.visible = true
