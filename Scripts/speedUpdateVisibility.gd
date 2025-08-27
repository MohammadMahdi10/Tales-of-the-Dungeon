extends Node

signal speedVisibility

func visible():
	emit_signal("speedVisibility")
