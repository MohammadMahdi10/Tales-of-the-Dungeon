extends KinematicBody2D

#-----VARIABLES-----

var health = randi() % 201 + 100
var speed = 31

var PlayerAttackZone = false
var CanTakeDamage = true

var playerChase = false
var player = null
var strengthEffect = false

func _ready():
	#Connects the respective items to their respective functions
	RemoveEnemySingleton.connect("removeEnemy", self, "removalOfEnemyFloor")
	RemoveEnemySingleton.connect("removeEnemy", self, "removalOfEnemyFloor")
	StrengthSingleton.connect("strengthIncrement", self, "toStrengthEffect")

func _physics_process(delta):
	playerAttack()
	UpdateHealth()
	
	if playerChase:
		position += (player.position - position)/speed #Gets the position of the enemy relative to the player position. This is divided by speed to scale down the vector
		$AnimatedSprite.play("walk")
		if player.position.x - position.x < 0:
			$AnimatedSprite.flip_h = true #Checks if the player is going to the left to play left animation (flip)
		else:
			$AnimatedSprite.flip_h = false #Checks if the player is going to the right to play right animation
	else:
		$AnimatedSprite.play("idle") #If the enemy is not chasing, idle plays

func _on_Detection_body_entered(body):
	player = body #Sets the player, which entered the area of the enemy, to the body
	playerChase = true #This allows the enemy to chase the player

func _on_Detection_body_exited(body): #Once the player has left the body, returns it back to normal state
	player = null
	playerChase = false
	
func enemy():
	pass

func _on_EnemyHitbox_body_entered(body): #Ensures that the player can attack once entered
	if body.has_method("player"):
		PlayerAttackZone = true

func _on_EnemyHitbox_body_exited(body): #Ensures that the player cannot attack once left
	if body.has_method("player"):
		PlayerAttackZone = false

func playerAttack():
	if PlayerAttackZone and Global.playerCurrentAttack == true: #If the attack of the player is true and the player is in the attack zone
		if CanTakeDamage == true:
			if strengthEffect == false:
				$AnimationPlayer.play("Damage")
				health -= 50 #If player does not have strength, damage normal
			else:
				$AnimationPlayer.play("Damage")
				health -= 100 #If player has strength, damage increases
			$TakeDamageCoolDown.start() #Cool down of the enemy starts so they do not take consecutive damage
			CanTakeDamage = false
			if health <= 0: #Removes the enemy once their health is zero
				CoinCounter.emitEnemyCoin() #Increment the coin of the enemy once they have died
				self.queue_free()
				

func _on_TakeDamageCoolDown_timeout():
	CanTakeDamage = true #Once the timer runs out, damage returns back to normal (can get attacked again)

func UpdateHealth(): #Setting the enemy health bar's value to the health of the enemy
	var EnemyHealthBar = $EnemyHealthBar
	EnemyHealthBar.value = health

func removalOfEnemyFloor(): #Removes the enemy per floor once a new floor is generated
	self.queue_free()

func toStrengthEffect(): #Once the strength effect is in action, ensures that the enemy takes strength respective damage
	$StrengthTimer.start()
	strengthEffect = true

func _on_StrengthTimer_timeout(): #Once the strength effect is over, returns damage back to normal and sets the symbol of strength to be black
	strengthEffect = false
	StrengthInvisibilitySingleton.toStrengthInvisibility()
