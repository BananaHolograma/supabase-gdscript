class_name GodotSupabaseStorage extends Node

signal listed_buckets(result)
signal retrieved_bucket(result)
signal created_bucket(result)
signal updated_bucket(result)
signal deleted_bucket(result)
signal emptied_bucket(result)
signal uploaded_file(result)
signal downloaded_file(result)
signal error(error: GodotSupabaseError)

class BucketActions:
	const LIST_BUCKETS = "LIST_BUCKETS"
	const GET_BUCKET = "GET_BUCKET"
	const CREATE_BUCKET = "CREATE_BUCKET"
	const UPDATE_BUCKET = "UPDATE_BUCKET"
	const DELETE_BUCKET = "DELETE_BUCKET"
	const EMPTY_BUCKET = "EMPTY_BUCKET"
	const UPLOAD_FILE = "UPLOAD_FILE"
	const DOWNLOAD_FILE = "DOWNLOAD_FILE"


const DEFAULT_FILE_OPTIONS: Dictionary = {
  "cache_control": '3600',
  "content_type": 'text/plain;charset=UTF-8',
  "content_length": 102400,
  "upsert": false,
}

const DEFAULT_DOWNLOAD_OPTIONS: Dictionary = {
	"wants_transformation": false, 
	"public": false
}

var storage_url: String
var bucket_url: String
var object_url: String
var current_action: String

func _init(url: String):
	storage_url = url
	bucket_url =  url + "/bucket"
	object_url = url + "/object"
	

# RLS policy permissions required:
# buckets table permissions: select
#o bjects table permissions: none
func list_buckets() -> GodotSupabaseStorage:
	current_action = BucketActions.LIST_BUCKETS
	
	GodotSupabase.http_request(on_request_completed).request(
		bucket_url,
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_GET
	)
	
	return self

# RLS policy permissions required:
# buckets table permissions: select
# objects table permissions: none
func get_bucket(id: String) -> GodotSupabaseStorage:
	current_action = BucketActions.GET_BUCKET
	
	GodotSupabase.http_request(on_request_completed).request(
		bucket_url + "/" + id,
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_GET
	)
	
	return self
## RLS policy permissions required:
# buckets table permissions: insert
# objects table permissions: none
## File size formats  20GB / 20MB / 30KB / 3B
func create_bucket(_name: String, options: Dictionary = { public = false, file_size_limit = "50MB", allowed_mime_types = [""] }) -> GodotSupabaseStorage:
	current_action = BucketActions.CREATE_BUCKET
	
	options.merge({"name": _name, "id": _name})
	
	GodotSupabase.http_request(on_request_completed).request(
		bucket_url,
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_POST,
		JSON.stringify(options)
	)
	
	return self


# RLS policy permissions required:
# buckets table permissions: select and update
# objects table permissions: none
func update_bucket(id: String, options: Dictionary) -> GodotSupabaseStorage:
	current_action = BucketActions.UPDATE_BUCKET

	GodotSupabase.http_request(on_request_completed).request(
		bucket_url + "/" + id,
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_PUT,
		JSON.stringify(options)
	)
	
	return self

## RLS policy permissions required:
# buckets table permissions: select and delete
# objects table permissions: none
## A bucket can't be deleted with existing objects inside it. You must first empty() the bucket
## This endpoint does not return errors when the policies are not defined, the message is { "message": "Successfully deleted" }
func delete_bucket(id: String) -> GodotSupabaseStorage:
	if current_action == BucketActions.EMPTY_BUCKET:
		await emptied_bucket
		
	current_action = BucketActions.DELETE_BUCKET
	
	GodotSupabase.http_request(on_request_completed).request(
		bucket_url + "/" + id,
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_DELETE,
		JSON.stringify({})
	)
	
	return self

#RLS policy permissions required:
#buckets table permissions: select
#objects table permissions: select and delete
func empty_bucket(id: String) -> GodotSupabaseStorage:
	current_action = BucketActions.EMPTY_BUCKET
	
	GodotSupabase.http_request(on_request_completed).request(
		bucket_url + "/" + id + "/empty",
		GodotSupabase["CONFIGURATION"]["global"]["headers"],
		HTTPClient.METHOD_POST,
		JSON.stringify({})
	)
	
	return self

#RLS policy permissions required:
#buckets table permissions: none
#objects table permissions: only insert when you are uploading new files and select, insert and update when you are upserting files
func upload_file(bucket_id: String, object: String, filepath: String, options: Dictionary = DEFAULT_FILE_OPTIONS.duplicate()) -> GodotSupabaseStorage:
	current_action = BucketActions.UPLOAD_FILE
	
	var file := FileAccess.open(filepath, FileAccess.READ)
	if not file:
		var supabase_error = GodotSupabaseError.new(
			{"message": "GodotSupabaseError: The file on path {path} cannot be accessed, an error happened -> {error}".format({"path": filepath, "error": file.get_open_error()})}, 
			current_action
		)
		push_error(supabase_error)
		error.emit(supabase_error)
		
		return self
		
	options.merge({
		"content_type": MimeTypes.list[filepath.get_extension()], 
		"content_length": file.get_length()
	},
	true)
	
	var file_content := file.get_buffer(options["content_length"])
	file.close()

	GodotSupabase.http_request(on_request_completed).request_raw(
		object_url + "/" + bucket_id + "/" + object,
		_file_headers(options),
		HTTPClient.METHOD_POST,
		file_content
	)
	
	return self
	
# Downloads a file from a private bucket
func download_file(bucket_id: String, filepath: String, options: Dictionary = DEFAULT_DOWNLOAD_OPTIONS.duplicate()) -> GodotSupabaseStorage:
	var wants_tranformation = options["wants_transformation"] if options.has("wants_transformation") else false
	var render_path: String =  "render/image/authenticated" if wants_tranformation else "object"
	var transform_options = _transform_options_to_query_string(options)
	

	var endpoint = "{url}/{render_path}/{id}/{path}{transform_query}".format({
		"url": storage_url,
		"render_path": render_path, 
		"id": bucket_id, 
		"path": filepath,
		"transform_query": "" if transform_options.is_empty() else "?" + transform_options
	})
	print("endpoint ", endpoint)
	GodotSupabase.http_request(on_request_completed).request(
		endpoint,
		_file_headers(options),
		HTTPClient.METHOD_GET,
		JSON.stringify({})
	)
	
	return self

func _file_headers(options: Dictionary) -> PackedStringArray:
	var global_headers = GodotSupabase.CONFIGURATION["global"]["headers"].duplicate()
#	global_headers.remove_at(global_headers.find("Accept: application/json"))
	global_headers.remove_at(global_headers.find("Content-Type: application/json"))

	var headers := PackedStringArray(
	["x-upsert: {upsert}".format({"upsert": str(options["upsert"]) if options.has("upsert") else str(DEFAULT_FILE_OPTIONS["upsert"])}),
	"Content-length: {length}".format({"length": options["content_length"] if options.has("content_length") else DEFAULT_FILE_OPTIONS["content_length"]}),
	"Content-Type: {content_type}".format({"content_type": options["content_type"] if options.has("content_type") else DEFAULT_FILE_OPTIONS["content_type"]}),
	"Content-Disposition: attachment",
	"Cache-control: max-age={age}".format({"age": options["cache_control"] if options.has("cache_control") else DEFAULT_FILE_OPTIONS["cache_control"]})
	])
	
	return global_headers + headers

## format: origin
## height and width numbers
## quality: 0 to 100
## resize: cover | contain | fill
func _transform_options_to_query_string(transform: Dictionary) -> String:
	const params := []
	
	if transform.has("width"):
		params.append("width=" + transform["width"])
		
	if transform.has("height"):
		params.append("height=" + transform["height"])
		
	if transform.has("resize") and transform["resize"] in ["cover", "contain", "fill"]:
		params.append("resize=" + transform["resize"])
		
	if transform.has("format"):
		params.append("format=" + transform["format"])
		
	if transform.has("quality"):
		params.append("quality=" + transform["quality"])
	
	
	return "&".join(params)
	
func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, http_handler: HTTPRequest) -> void:
	var data: String = body.get_string_from_utf8()
	var content = {} if data.is_empty() else JSON.parse_string(data)

	print(content)
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201, 204]:
		match(current_action):
			BucketActions.LIST_BUCKETS:
				listed_buckets.emit(content)
			BucketActions.GET_BUCKET:
				retrieved_bucket.emit(content)
			BucketActions.CREATE_BUCKET:
				created_bucket.emit(content)
			BucketActions.UPDATE_BUCKET:
				updated_bucket.emit(content)
			BucketActions.DELETE_BUCKET:
				deleted_bucket.emit(content)
			BucketActions.EMPTY_BUCKET:
				emptied_bucket.emit(content)
			BucketActions.UPLOAD_FILE:
				uploaded_file.emit(content)
			BucketActions.DOWNLOAD_FILE:
				downloaded_file.emit(content)
			
	else:
		var supabase_error = GodotSupabaseError.new(content, current_action)
		push_error(supabase_error)
		error.emit(supabase_error)

