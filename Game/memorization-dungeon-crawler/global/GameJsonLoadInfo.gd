extends Node
class_name GameJsonLoadInfo

func write(out:String):
	print(out)
	message += out+"\n"

var message:String = ""

#func _init(message:String, success:bool):
	#self.message = message
	#self.success = success
