extends KinematicBody2D

var speed = 32
var playerChase = false
var player = null

var health = BossHealth.bossHealth #Sets the health of the boss to be the global health script of the boss
var PlayerAttackZone = false
var CanTakeDamage = true

var canMove = true

func _ready():
	#Ensures removal of the boss when dead
	RemoveEnemySingleton.connect("removeEnemy", self, "removeBossEnemy")

func _physics_process(delta):
	playerAttack()
	
	if playerChase:
		position += (player.position - position)/speed #Gets the position of the boss relative to the player position. This is divided by speed to scale down the vector
		$AnimatedSprite.play("walk")
		if player.position.x - position.x < 0:
			$AnimatedSprite.flip_h = true #Checks if the player is going to the left to play left animation (flip)
		else:
			$AnimatedSprite.flip_h = false #Checks if the player is going to the right to play right animation
	else:
		$AnimatedSprite.play("idle") #If the enemy is not chasing, idle plays

func _on_Detection_body_entered(body):
	player = body #Sets the player, which entered the area of the boss, to the body
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
			canMove = false
			BossReductionSingleton.bossHealthReduction() #Makes sure the boss reduces hp once it is attakced by the player
			$AnimationPlayer.play("Damage") #Makes sure the boss changes color once attacked
			$TakeDamageCoolDown.start() #Cool down of the enemy starts so they do not take consecutive damage
			CanTakeDamage = false

func _on_TakeDamageCoolDown_timeout():
	CanTakeDamage = true #Once the timer runs out, damage returns back to normal (can get attacked again)

func removeBossEnemy(): #Removes the boss once dead
	self.queue_free()
