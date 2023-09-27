class_name GodotSupabaseDatabase extends Node

signal selected(query: Dictionary)
signal inserted(query: Dictionary)
signal updated(query: Dictionary)
signal deleted(query: Dictionary)
signal error


## https://supabase.com/docs/reference/javascript/using-filters
enum TYPES {
	SELECT,
	INSERT,
	UPDATE,
	UPSERT,
	DELETE
}

var QUERY_TYPES = {
	TYPES.SELECT: "SELECT",
	TYPES.INSERT: "INSERT",
	TYPES.UPDATE: "UPDATE",
	TYPES.UPSERT: "UPSERT",
	TYPES.DELETE: "DELETE",
}

var endpoint: String = "{base}/rest/{version}/".format({
	"base": GodotSupabase.CONFIGURATION["url"],
	"version": GodotSupabase.current_api_version
})

var current_query: Dictionary = {
	"query": "",
	"type": "",
	"verb": "",
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


func filter(column: String, value, type: String, parameters: Dictionary = {}) -> GodotSupabaseDatabase:
	type = type.to_lower().strip_edges()
	
	match(type):
		"eq":
			eq(column, str(value))
		"match":
			Match(parameters)
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
		"not":
			Not(column, parameters["operator"], value)
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
	
## Shorthand for multiple eq
func Match(entries: Dictionary) -> GodotSupabaseDatabase:
	for column in entries.keys():
		eq(column, entries[column])
		
	return self
	
## Using the eq() filter doesn't work when filtering for null.
## Instead, you need to use is().
func Is(column: String, value) -> GodotSupabaseDatabase:
	if value == null:
		value = "null"
	
	current_query["filters"] += "&{column}=is.{value}".format({"column": column, "value": value})
	
	return self

func In(column: String, values: PackedStringArray) -> GodotSupabaseDatabase:
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

func Not(column: String, operator: String, value) -> GodotSupabaseDatabase:
	if value == null:
		value = "null"
	
	current_query["filters"] += "&{column}=not.{operator}.{value}".format({"column": column, "operator": operator, "value": value})
	
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

func Or(filters: String, foreign_table: String = "") -> GodotSupabaseDatabase:
	var column: String = "or" if foreign_table.is_empty() else foreign_table + ".or"
	current_query["filters"] += "&{column}=({filters})".format({"column": column, "filters": filters})
	current_query["filters"].replacen(" ", "%20")
	return self
	

func query(table: String) -> GodotSupabaseDatabase:
	reset_query()
	current_query["query"] = endpoint + table + "?"
	
	return self


func from(table: String) -> GodotSupabaseDatabase:
	return query(table)

## https://supabase.com/docs/guides/api/joins-and-nesting
func select(columns : PackedStringArray = PackedStringArray(["*"])) -> GodotSupabaseDatabase:
	current_query["query"] += "select=" + ",".join(columns)
	current_query["type"] = TYPES.SELECT
	current_query["verb"] = QUERY_TYPES[TYPES.SELECT]
	current_query["method"] = HTTPClient.METHOD_GET
	current_query["headers"].append_array(read_headers)
	
	return self
	
	
func insert(fields: Array, upsert: bool = false) -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.INSERT
	current_query["verb"] = QUERY_TYPES[TYPES.INSERT]
	current_query["method"] = HTTPClient.METHOD_POST
	current_query["payload"] = fields
	
	if upsert:
		current_query["headers"].append_array(upsert_headers)
		
	return self

## update() should always be combined with Filters to target the item(s) you wish to update
func update(fields: Dictionary) -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.UPDATE
	current_query["verb"] = QUERY_TYPES[TYPES.UPDATE]
	current_query["method"] = HTTPClient.METHOD_PUT
	current_query["payload"] = fields
	
	
	return self 

## Primary keys must be included in values to use upsert.
## https://www.cockroachlabs.com/blog/sql-upsert/
func upsert(fields) -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.UPSERT
	current_query["verb"] = QUERY_TYPES[TYPES.UPSERT]
	current_query["method"] = HTTPClient.METHOD_PUT
	current_query["payload"] = fields
	
	return self 

## delete() should always be combined with filters to target the item(s) you wish to delete
func delete() -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.DELETE
	current_query["verb"] = QUERY_TYPES[TYPES.DELETE]
	current_query["method"] = HTTPClient.METHOD_DELETE
	
	return self

func exec():
	if current_query["query"].is_empty():
		return
	
	if current_query["type"] in [QUERY_TYPES.UPDATE, QUERY_TYPES.DELETE] and current_query["filters"].is_empty():
		push_error("GodotSupabaseDatabase: You cannot {action} without applying any filters to the query".format({"action": current_query["verb"]}))
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
	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201, 204]:
		match(current_query["type"]):
			TYPES.SELECT:
				selected.emit(current_query)
			TYPES.INSERT:
				inserted.emit(current_query)
			TYPES.UPDATE:
				updated.emit(current_query)
			TYPES.DELETE:
				deleted.emit(current_query)
	else:
		var supabase_error = GodotSupabaseError.new(content, current_query["verb"])
		error.emit(supabase_error)
		push_error(supabase_error)

	reset_query()
	http_handler.queue_free()
