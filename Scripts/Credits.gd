extends ParallaxBackground

var scrollingSpeed = 100
	
func _process(delta):
	scroll_offset.y -= scrollingSpeed * delta
