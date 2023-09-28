class_name GodotSupabaseDatabase extends Node

signal selected(query: Dictionary)
signal inserted(query: Dictionary)
signal updated(query: Dictionary)
signal upserted(query: Dictionary)
signal deleted(query: Dictionary)
signal error(error: GodotSupabaseError)


## https://supabase.com/docs/reference/javascript/using-filters
enum TYPES {
	SELECT,
	INSERT,
	UPDATE,
	UPSERT,
	DELETE,
	RPC
}

var QUERY_TYPES = {
	TYPES.SELECT: "SELECT",
	TYPES.INSERT: "INSERT",
	TYPES.UPDATE: "UPDATE",
	TYPES.UPSERT: "UPSERT",
	TYPES.DELETE: "DELETE",
	TYPES.RPC: "RPC"
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
	
## You can order foreign tables, but it doesn't affect the ordering of the current table
## You can call this method multiple times to order by multiple columns.
func order(column: String, config: Dictionary = {"ascending": false}) -> GodotSupabaseDatabase:
	var direction: String = "asc" if config["ascending"] else "desc"
	var nulls: String = ""

	if config.has("nulls_first"):
		nulls = ".nullsfirst" if config["nulls_first"] else ".nullslast"
		
	var key: String = "{foreign_table}.order".format({"foreign_table": config["foreign_table"]}) if config.has("foreign_table") else "order"

	current_query["filters"] += "&{key}={column}.{direction}{nulls}".format({"key": key, "column": column, "direction": direction, "nulls": nulls})
	
	return self


func limit(count: int, foreign_table: String = "") -> GodotSupabaseDatabase:
	var key: String = "limit" if foreign_table.is_empty() else "{foreign_table}.limit".format({"foreign_table": foreign_table})
	current_query["filters"] += "&{key}={count}".format({"key": key, "count": count})
	
	return self


func limit_range(from: int, to: int, foreign_table: String = "") -> GodotSupabaseDatabase:
	var key_offset: String = "offset" if foreign_table.is_empty() else "{foreign_table}.offset"
	var key_limit: String = "limit" if foreign_table.is_empty() else "{foreign_table}.limit"
	
	current_query["filters"] += "&{key_offset}={from}&{key_limit}={to}".format({"key_offset": key_offset, "from": from, "key_limit": key_limit, "to": (to - from + 1)})
	
	return self
	
func Rpc(function_name: String, arguments: Dictionary = {}, config: Dictionary = {}) -> GodotSupabaseDatabase:
	reset_query(["filters"])

	current_query["query"] = endpoint + "rpc/" + function_name
	current_query["type"] = TYPES.RPC
	current_query["verb"] = QUERY_TYPES[TYPES.RPC]
	
	if config.has("count") and config["count"] in ["exact","planned","estimated"]:
		current_query["headers"].append_array(PackedStringArray(["Prefer: count=" + config["count"] ]))
	
	if config.has("head") and config["head"]:
		current_query["query"] += "?"
		current_query["method"] = HTTPClient.METHOD_HEAD
		for key in arguments.keys():
			current_query["filters"] += "&{key}={value}".format({"key": key, "value": arguments[key]})
	else:
		current_query["method"] = HTTPClient.METHOD_POST
		current_query["payload"] = arguments

	print(current_query)
	return self


## https://supabase.com/docs/guides/api/joins-and-nesting
func select(columns : PackedStringArray = PackedStringArray(["*"])) -> GodotSupabaseDatabase:
	current_query["query"] += "select=" + ",".join(columns)
	current_query["type"] = TYPES.SELECT
	current_query["verb"] = QUERY_TYPES[TYPES.SELECT]
	current_query["method"] = HTTPClient.METHOD_GET
	current_query["headers"].append_array(read_headers)
	
	return self
	
	
func insert(fields: Array, config: Dictionary = {}) -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.INSERT
	current_query["verb"] = QUERY_TYPES[TYPES.INSERT]
	current_query["method"] = HTTPClient.METHOD_POST
	current_query["payload"] = fields
	current_query["headers"].append_array( _build_prefer_headers(config))
	
	return self


## Primary keys must be included in values to use upsert.
## fields can be both,array for bulk and dictionary for individual
## https://www.cockroachlabs.com/blog/sql-upsert/
func upsert(fields: Array, config: Dictionary = {}) -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.UPSERT
	current_query["verb"] = QUERY_TYPES[TYPES.UPSERT]
	current_query["method"] = HTTPClient.METHOD_POST
	current_query["payload"] = fields
	current_query["headers"].append_array( _build_prefer_headers(config))
	
	if config.has("on_conflict"):
		current_query["filters"] = "&on-conflict={column}".format({"column": config["on_conflict"]})

	return self 

## update() should always be combined with Filters to target the item(s) you wish to update
## fields can be both, array for bulk and dictionary for individual
## count value can be "exact","planned","estimated"
func update(fields: Dictionary, count: String = "") -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.UPDATE
	current_query["verb"] = QUERY_TYPES[TYPES.UPDATE]
	current_query["method"] = HTTPClient.METHOD_PATCH
	current_query["payload"] = fields
	
	if count in ["exact","planned","estimated"]:
		current_query["headers"].append_array(PackedStringArray(["Prefer: count=" + count]))
	else:
		if not count.is_empty():
			push_error("GodotSupabaseDatabase: The value count {count} on UPDATE is not allowed, allowed values are 'exact','planned', 'estimated'")
	
	return self 


## delete() should always be combined with filters to target the item(s) you wish to delete
func delete(count: String = "") -> GodotSupabaseDatabase:
	current_query["type"] = TYPES.DELETE
	current_query["verb"] = QUERY_TYPES[TYPES.DELETE]
	current_query["method"] = HTTPClient.METHOD_DELETE
	
	if count in ["exact","planned","estimated"]:
		current_query["headers"].append_array(PackedStringArray(["Prefer: count=" + count]))
	else:
		if not count.is_empty():
			push_error("GodotSupabaseDatabase: The value count {count} on DELETE is not allowed, allowed values are 'exact','planned', 'estimated'")
	
	return self


func exec():
	if current_query["query"].is_empty():
		return
	
	if current_query["type"] in [TYPES.UPDATE, TYPES.DELETE] and current_query["filters"].is_empty():
		push_error("GodotSupabaseDatabase: You cannot {action} without applying any filters to the query".format({"action": current_query["verb"]}))
		return
	
	print(current_query["query"] + current_query["filters"])
	var query: String = _sanitize_query()

	print(query)
	GodotSupabase.http_request(on_request_completed).request(
		query, 
		current_query["headers"], 
		current_query["method"],
		JSON.stringify(current_query["payload"])
	)


func reset_query(except: Array[String] = []) -> void:
	var backup = current_query.duplicate()
	
	current_query = {
		"query": "",
		"type": "",
		"verb": "",
		"method": "", 
		"filters": "",
		"payload": [],
		"headers": GodotSupabase.CONFIGURATION["global"]["headers"]
	}
	
	for key in except:
		if current_query.has(key):
			current_query[key] = backup[key]


func _build_prefer_headers(config: Dictionary) -> PackedStringArray:
	var prefer_headers = "Prefer: resolution={type}-duplicates".format({"type": "ignore" if config.has("ignore_duplicates") else "merge"})
	
	if config.has("count") and config["count"] in ["exact","planned","estimated"]:
		prefer_headers += ",count=" + config["count"]
	if config.has("default_to_null") and not config["default_to_null"]:
		prefer_headers += ",missing=default"
	
	return PackedStringArray([prefer_headers])
	
func _sanitize_query() -> String:
	var query: String = current_query["query"] + current_query["filters"]
	
	if not current_query["filters"].is_empty():
		if current_query["query"].ends_with("?") and current_query["filters"].begins_with("&"):
			current_query["filters"] = current_query["filters"].substr(1)
			query = current_query["query"] + current_query["filters"]
		
	return query
	
	
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
			TYPES.UPSERT:
				upserted.emit(current_query)
			TYPES.UPDATE:
				updated.emit(current_query)
			TYPES.DELETE:
				deleted.emit(current_query)
	else:
		var supabase_error = GodotSupabaseError.new(content, current_query["verb"])
		push_error(supabase_error)
		error.emit(supabase_error)

	reset_query()
	http_handler.queue_free()
