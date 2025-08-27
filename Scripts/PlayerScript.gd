extends KinematicBody2D

#-----CONSTANTS-----

const speed = 130

#-----VARIABLES-----

var health = PlayerHealthSingleton.health #Sets the health of the player to the global script
var playerAlive = true #Checks if the player is alive
var attackInput = false #Checks if the player is attacking

var enemyInRange = false #Checks if the enemy is in the range of the player
var enemyCooldown = true #After enemy attacks, player does not take any damage

var velocity = Vector2.ZERO #Sets the x,y components to zero in both directions
var currentDirection = "none" #Sets the direction player is facing to nothing

var speedRate = false #Checks if the speed potion is active

func _ready():
	$Trail.visible = false #Ensures that the players speed trail not visible to start the game
	$AnimatedSprite.play("front_idle") #When the player is not moving, idle animation plays
	#Connecting respective items to their respective functions
	SpeedSingleton.connect("speedIncrement", self, "speedMovement")
	RegenerationSingleton.connect("regenerationIncrement", self, "RegenShow")
	StrengthSingleton.connect("strengthIncrement", self, "StrengthShow")
	CoinSingleton.connect("coinIncrement", self, "CoinShow")

func _physics_process(delta):
	playerMovement(delta) #Makes sure the player movement activates instantly in use
	enemyAttack() #Makes sure the enemy attacks activates instantly in use
	attack() #Makes sure the player attacks activates instantly in use
	
func playerMovement(delta):
	#Checks if speed rate is false. If so, normal speed activates
	if speedRate == false:
		if Input.is_action_pressed("Right"):
			currentDirection = "right" #Checks the direction of the player movement
			playAnimation(1) #Feeds in a number to a function to let the respective animation play
			velocity.x = speed
			velocity.y = 0
		elif Input.is_action_pressed("Left"):
			currentDirection = "left" #Checks the direction of the player movement
			playAnimation(1) #Feeds in a number to a function to let the respective animation play
			velocity.x = -speed
			velocity.y = 0
		elif Input.is_action_pressed("Down"):
			currentDirection = "down" #Checks the direction of the player movement
			playAnimation(1) #Feeds in a number to a function to let the respective animation play
			velocity.y = speed
			velocity.x = 0
		elif Input.is_action_pressed("Up"):
			currentDirection = "up" #Checks the direction of the player movement
			playAnimation(1) #Feeds in a number to a function to let the respective animation play
			velocity.y = -speed
			velocity.x = 0
		else:
			playAnimation(0) #Feeds in a number to a function to let the respective animation play
			velocity.x = 0
			velocity.y = 0
	else: #If the speed rate is true, then the speed of the player increases as speed potion active
		if Input.is_action_pressed("Right"):
			currentDirection = "right"
			playAnimation(1)
			velocity.x = 200
			velocity.y = 0
		elif Input.is_action_pressed("Left"):
			currentDirection = "left"
			playAnimation(1)
			velocity.x = -200
			velocity.y = 0
		elif Input.is_action_pressed("Down"):
			currentDirection = "down"
			playAnimation(1)
			velocity.y = 200
			velocity.x = 0
		elif Input.is_action_pressed("Up"):
			currentDirection = "up"
			playAnimation(1)
			velocity.y = -200
			velocity.x = 0
		else:
			playAnimation(0)
			velocity.x = 0
			velocity.y = 0
	
	move_and_slide(velocity) #Allows the movement to actually be done

func playAnimation(movement):
	var setDirection = currentDirection
	var animation = $AnimatedSprite
	
	#1. Checks the direction of the player and sets that animation
	#2. If the movement is 1, plays a walking animation. Else, does an idle animation
	#3. Also, checks if the attacking input is true as this will change the way the player moves
	#4. The "animation.flip_h" just flips character in the horizonal direction
	if setDirection == "right":
		animation.flip_h = false
		if movement == 1:
			animation.play("side_walk")
		elif movement == 0:
			if attackInput == false:
				animation.play("side_idle")
	if setDirection == "left":
		animation.flip_h = true
		if movement == 1:
			animation.play("side_walk")
		elif movement == 0:
			if attackInput == false:
				animation.play("side_idle")
	if setDirection == "down":
		animation.flip_h = false
		if movement == 1:
			animation.play("front_walk")
		elif movement == 0:
			if attackInput == false:
				animation.play("front_idle")
	if setDirection == "up":
		animation.flip_h = false
		if movement == 1:
			animation.play("back_walk")
		elif movement == 0:
			if attackInput == false:
				animation.play("back_idle")

func player():
	pass

func _on_PlayerHitbox_body_entered(body):
	if body.has_method("enemy"):
		enemyInRange = true #If the enemy has entered the collision shape of the player, set the enemy range to true

func _on_PlayerHitbox_body_exited(body):
	if body.has_method("enemy"):
		enemyInRange = false #If the enemy has exited the collision shape of the player, set the enemy range to false

func enemyAttack():
	if enemyInRange and enemyCooldown == true: #Checks if both enemy in range and cool down is true, if so the player hp reduces, cool down now is false and enemy attack cool down starts
		$AnimationPlayer.play("Damage") #Changes the color of the player when taking damage
		HealthSingleton.reduceHealth() #Sends a health signal to update healh bar
		enemyCooldown = false #Makes sure the player does not take consecutive damage
		$AttackCooldown.start() #Starts this timer to ensures above

func _on_AttackCooldown_timeout():
	enemyCooldown = true #If the enemy has attacked, they have their own cool down

func attack():
	#1. Checks the direction of the player and plays respective attack animations when active
	#2. Deal attack timer is a cool down for the player
	var setDirection = currentDirection
	if Input.is_action_just_pressed("Attack"):
		Global.playerCurrentAttack = true
		attackInput = true
		if setDirection == "right":
			$AnimatedSprite.flip_h = false
			$AnimatedSprite.play("side_attack")
			$DealAttackTimer.start()
		if setDirection == "left":
			$AnimatedSprite.flip_h = true
			$AnimatedSprite.play("side_attack")
			$DealAttackTimer.start()
		if setDirection == "down":
			$AnimatedSprite.play("front_attack")
			$DealAttackTimer.start()
		if setDirection == "up":
			$AnimatedSprite.play("back_attack")
			$DealAttackTimer.start()

func _on_DealAttackTimer_timeout():
	$DealAttackTimer.stop() #After active, it stops
	Global.playerCurrentAttack = false #Player stops current attack
	attackInput = false #Player stops attacking

func _on_TimeOfSpeed_timeout():
	speedRate = false #After the speed potion expires, the speed of the player is false
	$Trail.visible = false #Speed trail invisible
	SpeedUpdateVisibility.visible() #Ensures the speed symbol goes black

func speedMovement():
	$AnimationPlayer.play("Speed") #Changes the color of the play to blue when speed potion picked up
	$Trail.visible = true #So the speed trail can be seen
	speedRate = true #If the speed potion picked up, speed rate set to true so player moves faster
	$TimeOfSpeed.start() #How long the speed lasts for

func RegenShow():
	$AnimationPlayer.play("Regen") #Changes the color of the play to green when regeneration potion picked up
	$Particles2D2.emitting = true #So the hearts can be seen
	$RegenTimerEffect.start()

func StrengthShow():
	$AnimationPlayer.play("Strength") #Changes the color of the play to pink-ish when strength potion picked up

func CoinShow():
	$Particles2D.emitting = true #So the coin animation can be seen

func _on_RegenTimerEffect_timeout(): #Ensures that after the regeneration symbol goes black, the heart particles stop poping out
	$RegenTimerEffect.start()
	$Particles2D2.emitting = true
	if HealthCheck.healthOn == true:
		HealthCheck.healthOn = false
		$Particles2D2.emitting = false
		$RegenTimerEffect.stop()
