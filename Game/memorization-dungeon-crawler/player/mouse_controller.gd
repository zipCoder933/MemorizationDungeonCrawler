extends Node
class_name MouseController

var mouse_delta := Vector2.ZERO      # mouse movement this frame
var sensitivity := 0.1
var mouse_locked := false
var letGoOfMouse = false

func unlock_mouse_forever():
	unlock_mouse()
	letGoOfMouse = true

func _ready():
	print("Mouse controller ready 😎")
	lock_mouse()

func _process(delta):
	# Accumulate total mouse movement BEFORE resetting	
	# Reset after using it this frame
	mouse_delta = Vector2.ZERO

func _input(event):
	# Capture mouse motion (like Minecraft)
	if event is InputEventMouseMotion and mouse_locked:
		mouse_delta = event.relative * sensitivity
		#print(mouse_delta)

	# ESC → release mouse
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		unlock_mouse()

	# recapture mouse on click
	if event is InputEventMouseButton and event.pressed and not mouse_locked:
		if(!letGoOfMouse):
			lock_mouse()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if mouse_locked:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func lock_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_locked = true
	print("🟢 Mouse locked")

func unlock_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_locked = false
	print("🔴 Mouse unlocked")
