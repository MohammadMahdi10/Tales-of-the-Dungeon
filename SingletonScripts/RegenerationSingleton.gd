extends Node

signal regenerationIncrement

func regeneration():
	emit_signal("regenerationIncrement")
