extends Node

signal removeCoin

func coinRemoval():
	emit_signal("removeCoin")
