extends Node

signal strengthIncrement

func strength():
	emit_signal("strengthIncrement")
