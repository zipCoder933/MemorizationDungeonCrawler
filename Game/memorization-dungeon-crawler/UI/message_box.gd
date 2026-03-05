extends Node
class_name MessageBox

@onready var message_title: Label = %message_title
@onready var message_body: Label = %message_body
@onready var cancel_button: Button = %cancel_button
@onready var ok_button: Button = %ok_button

func _ready():
	self.visible = false
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	ok_button.pressed.connect(_on_ok_button_pressed)

func show_message(title:String, body:String, yes: Callable = Callable()):
	self.visible=true
	cancel_button.visible = false
	message_title.text = title
	message_body.text = body
	
var _yes_confirmation:Callable
var _no_confirmation:Callable

func show_confirmation(title:String,body:String, \
			yes: Callable, no: Callable = Callable()):
	self.visible=true
	self._yes_confirmation = yes
	self._no_confirmation = no
	cancel_button.visible=true
	message_title.text = title
	message_body.text = body

func _on_ok_button_pressed() -> void:
	if _yes_confirmation != null and !_yes_confirmation.is_null():
		_yes_confirmation.call()
		_yes_confirmation = Callable()
	self.visible = false

func _on_cancel_button_pressed() -> void:
	if _no_confirmation != null and !_no_confirmation.is_null():
		_no_confirmation.call()
		_no_confirmation = Callable()
	self.visible = false
