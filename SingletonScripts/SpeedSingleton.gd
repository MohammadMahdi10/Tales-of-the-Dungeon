extends Node

signal speedIncrement

func speed():
	emit_signal("speedIncrement")
