extends Node3D

var active_item = null # peer isolated

func can_accept_item(item):
	return active_item == null
