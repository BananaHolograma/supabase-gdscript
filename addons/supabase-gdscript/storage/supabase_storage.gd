class_name GodotSupabaseStorage extends Node

signal created_bucket(result)
signal error(error: GodotSupabaseError)


class BucketActions:
	const CREATE_BUCKET = "CREATE_BUCKET"
	
	
var storage_url: String
var current_action: String

func _init(url: String):
	storage_url = url
	

func create_bucket(_name: String, options: Dictionary = { public = false, file_size_limit = "1024", allowed_mime_types = ["*/*"] }):
	current_action = BucketActions.CREATE_BUCKET
	
	options.merge({"name": _name, "id": _name})
	
	GodotSupabase.http_request(on_request_completed).request(
		storage_url,
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_POST,
		JSON.stringify(options)
	)


func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, http_handler: HTTPRequest) -> void:
	var data: String = body.get_string_from_utf8()
	var content = {} if data.is_empty() else JSON.parse_string(data)

	print(content)

	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201, 204]:
		match(current_action):
			BucketActions.CREATE_BUCKET:
				created_bucket.emit(content)
			
	else:
		var supabase_error = GodotSupabaseError.new(content, current_action)
		push_error(supabase_error)
		error.emit(supabase_error)

