class_name GodotSupabaseDatabase extends Node

## https://supabase.com/docs/reference/javascript/using-filters

var endpoint: String = "{base}/rest/{version}/".format({
	"base": GodotSupabase.CONFIGURATION["url"],
	"version": GodotSupabase.current_api_version
})

var current_query: Dictionary = {
	"query": "",
	"method": "", 
	"filters": "",
	"payload": [],
	"headers": GodotSupabase.CONFIGURATION["global"]["headers"]
}

var read_headers = PackedStringArray(["Prefer: return=representation"])
var upsert_headers = PackedStringArray(["Prefer: resolution=merge-duplicates"])


func filters(filters: Array[Dictionary]) -> GodotSupabaseDatabase:
	for filter_data in filters:
		filter(
			filter_data["column"], 
			filter_data["type"], 
			filter_data["value"],
			filter_data["parameters"]
		)
		
	return self


func filter(column: String, type: String, value, parameters: Dictionary = {}) -> GodotSupabaseDatabase:
	type = type.to_lower().strip_edges()
	
	match(type):
		"eq":
			eq(column, str(value))
		"is":
			Is(column, value)
		"in":
			In(column, value)
		"neq":
			neq(column, str(value))
		"gt":
			gt(column, value)
		"gte":
			gte(column, value)			
		"lt":
			lt(column, value)
		"lte":
			lte(column, value)
		"like":
			like(column, value)	
		"ilike":
			ilike(column, value)
		"contains":
			contains(column, value)
		"contained_by":
			contained_by(column, value)
		"range_gt":
			range_gt(column, value)
		"range_gte":
			range_gte(column, value)
		"range_lt":
			range_lt(column, value)
		"range_lte":
			range_lte(column, value)
		"range_adjacent":
			range_adjacent(column, value)
		"overlaps":
			overlaps(column, value)
		"text_search":
			text_search(column, value, parameters)
	return self 


func eq(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=eq.{value}".format({"column": column, "value": value})
 
	return self
	
## Using the eq() filter doesn't work when filtering for null.
## Instead, you need to use is().
func Is(column: String, value:):
	current_query["filters"] += "&{column}=is.{value}".format({"column": column, "value": value})
	
	return self

func In(column: String, values: PackedStringArray):
	current_query["filters"] += "&{column}=in.({values})".format({"column": column, "values": ",".join(values)})
	
	return self


func neq(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=neq.{value}".format({"column": column, "value": value})
	
	return self

func gt(column: String, value) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=gt.{value}".format({"column": column, "value": value})

	return self

func gte(column: String, value) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=gte.{value}".format({"column": column, "value": value})

	return self

func lt(column: String, value) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=lt.{value}".format({"column": column, "value": value})

	return self

func lte(column: String, value) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=lte.{value}".format({"column": column, "value": value})

	return self

func like(column: String, pattern: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=like.{pattern}".format({"column": column, "pattern": pattern})
	
	return self

func ilike(column: String, pattern: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=ilike.{pattern}".format({"column": column, "pattern": pattern})
	
	return self


## range types can be inclusive '[', ']' or exclusive '(', ')' so just
## keep it simple and accept a string
func contains(column: String, value) -> GodotSupabaseDatabase:
	if typeof(value) == TYPE_STRING:
		current_query["filters"] += "&{column}=cs.{value}".format({"column": column, "value": value})
	elif value is Array:
		current_query["filters"] += "&{column}=cs.{{value}}".format({"column": column, "value": ",".join(value)})
	else:
		current_query["filters"] += "&{column}=cs.{value}".format({"column": column, "value": JSON.stringify(value)})
	
	return self

func contained_by(column: String, value) -> GodotSupabaseDatabase:
	if typeof(value) == TYPE_STRING:
		current_query["filters"] += "&{column}=cd.{value}".format({"column": column, "value": value})
	elif value is Array:
		current_query["filters"] += "&{column}=cd.{{value}}".format({"column": column, "value": ",".join(value)})
	else:
		current_query["filters"] += "&{column}=cd.{value}".format({"column": column, "value": JSON.stringify(value)})
	
	return self


func range_gt(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=sr.{value}".format({"column": column, "value": value})

	return self

func range_gte(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=nxl.{value}".format({"column": column, "value": value})

	return self

func range_lt(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=sl.{value}".format({"column": column, "value": value})

	return self

func range_lte(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=nxr.{value}".format({"column": column, "value": value})

	return self

func range_adjacent(column: String, value: String) -> GodotSupabaseDatabase:
	current_query["filters"] += "&{column}=adj.{value}".format({"column": column, "value": value})

	return self

func overlaps(column: String, value) -> GodotSupabaseDatabase:
	if typeof(value) == TYPE_STRING:
		current_query["filters"] += "&{column}=ov.{value}".format({"column": column, "value": value})
	elif value is Array:
		current_query["filters"] += "&{column}=ov.{{value}}".format({"column": column, "value": ",".join(value)})
		
	return self

func text_search(column: String, query: String, parameters: Dictionary = {}) -> GodotSupabaseDatabase:
	var type: String = ""
	var config = "(" + parameters["config"] + ")" if parameters.has("config") else ""
	
	if parameters.has("type"):
		match(parameters["type"]):
			"plain":
				type = "pl"
			"phrase":
				type = "ph"
			"websearch":
				type = "w"
				
	current_query["filters"] += "&{column}={type}fts{config}.{query}".format({"column": column, "type": type, "config": config, "query": query})			
			
	return self

func query(table: String) -> GodotSupabaseDatabase:
	reset_query()
	current_query["query"] = endpoint + table + "?"
	
	return self


func select(columns : PackedStringArray = PackedStringArray(["*"])) -> GodotSupabaseDatabase:
	current_query["query"] += "select=" + ",".join(columns)
	current_query["method"] = HTTPClient.METHOD_GET
	current_query["headers"].append_array(read_headers)
	
	return self
	
	
func insert(fields: Array, upsert: bool = false) -> GodotSupabaseDatabase:
	current_query["method"] = HTTPClient.METHOD_POST
	current_query["payload"] = fields
	
	if upsert:
		current_query["headers"].append_array(upsert_headers)
		
	return self


func exec():
	if current_query["query"].is_empty():
		return
	
	print(current_query["query"] + current_query["filters"])

	GodotSupabase.http_request(on_request_completed).request(
		current_query["query"] + current_query["filters"], 
		current_query["headers"], 
		current_query["method"],
		JSON.stringify(current_query["payload"])
	)


func reset_query() -> void:
	current_query = {
	"query": "",
	"method": "", 
	"filters": "",
	"payload": [],
	"headers": GodotSupabase.CONFIGURATION["global"]["headers"]
}

func on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, http_handler: HTTPRequest) -> void:
	var data: String = body.get_string_from_utf8()
	var content = {} if data.is_empty() else JSON.parse_string(data)
	
	print(content)
	
	reset_query()
	http_handler.queue_free()
