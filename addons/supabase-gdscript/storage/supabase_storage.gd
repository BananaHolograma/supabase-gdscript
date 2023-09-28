class_name GodotSupabaseStorage extends Node

signal created_bucket


var storage_url: String
var bucket_url: String

func _init(url: String):
	storage_url = url
	bucket_url = storage_url + "/bucket"
	


