extends Node

signal HealthDamage

func reduceHealth():
	emit_signal("HealthDamage")
