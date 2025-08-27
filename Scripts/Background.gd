extends ParallaxBackground

var scrollingSpeed = 100 #Sets the initial scroll speed

func _ready():
	#Ensures that the sprites all play their moving animations
	$AnimatedSprite.play("playerRight")
	$AnimatedSprite2.play("default")
	$AnimatedSprite3.play("default")
	
func _process(delta):
	#This ensures that the background moves in the x direction
	scroll_offset.x -= scrollingSpeed * delta
