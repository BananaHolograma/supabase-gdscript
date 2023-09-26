class_name GodotSupabaseDatabase extends Node


var endpoint: String = "{base}/rest/{version}/".format({
	"base": GodotSupabase.CONFIGURATION["url"],
	"version": GodotSupabase.current_api_version
})

var current_query: Dictionary = {
	"query": "",
	"method": "", 
	"filters": ""
}


func query(table: String) -> GodotSupabaseDatabase:
	current_query["query"] = endpoint + table + "?"
	
	return self


func select(columns : PackedStringArray = PackedStringArray(["*"])) -> GodotSupabaseDatabase:
	current_query["query"] += "select=" + ",".join(columns)
	current_query["method"] = HTTPClient.METHOD_GET
	
	return self


func exec():
	if current_query["query"].is_empty():
		return
	
	GodotSupabase.http_request(on_request_completed).request(
		current_query["query"], 
		GodotSupabase.CONFIGURATION["global"]["headers"], 
		current_query["method"]
	)


func reset_query() -> void:
	current_query = {
	"query": "",
	"method": "", 
	"filters": ""
}

func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, http_handler: HTTPRequest) -> void:
	var data: String = body.get_string_from_utf8()
	var content = {} if data.is_empty() else JSON.parse_string(data)
	
	print(content)
	
	reset_query()
	http_handler.queue_free()
