extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
#	await GodotSupabase.auth.sign_in_with_email("hola4@amigos.com", "password").signed_in_with_email
#	GodotSupabase.database.from("countries").select(["id"]).Not("name", "is", null).exec()
#	GodotSupabase.database.from("countries").select(["id"]).Or('id.eq.3,name.eq.Algeria').exec()
#	GodotSupabase.database.query("countries").select(["name", "cities!inner(name)"]).Or('country_id.eq.1,name.eq.Beijing', 'cities').exec()
## THE SELECT ALLOW RETURN ON UPDATE
#	GodotSupabase.database.query("countries").select().update({"name": "ESPANA"}).eq("id", "1").exec()
#	GodotSupabase.database.query("rooms").select().eq("private", "false").neq("waiting_for_players", "false").exec()
#	GodotSupabase.database.query("issues").select(["title"]).contains("tags", ["is:open", "severity:low"]).exec()
#	GodotSupabase.database.query("clowns").select(["name"]).contains("address", {"postcode": 90210}).exec()
#	GodotSupabase.database.query("issues").select(["title"]).overlaps("tags", ['is:closed', 'severity:high']).exec()
#	GodotSupabase.database.query("issues").select(["title"]).text_search("title", "'Cache' & 'cat'", {"type": "plain", "config": "english"}).exec()
#	GodotSupabase.database.query("rooms").select(["code", "host"]).Match({"host": "godgamedev", "scenario": "Dungeon", "server_name": "POLITOXICOMANO"}).exec()
#	GodotSupabase.database.query("reservations").select(["room_name"]).range_gt("during", "[2000-01-01 13:00, 2000-01-01 13:30)").exec()
#	GodotSupabase.database.query("rooms").select(["code"]).In("host", ["AMIYO"]).exec()
#	GodotSupabase.database.query("classes").select(["name"]).contained_by("days", ['monday', 'tuesday', 'wednesday', 'friday']).exec()
#	GodotSupabase.database.query("rooms").select().filters([
#		{"column": "private", "type": "eq", "value": false },
#		{"column": "host", "type": "eq", "value": "AMIYO" },
#		{"column": "max_players", "type": "gt", "value": 14 }
#	]).exec()
#	GodotSupabase.database.query("rooms").insert([{
#		"code": "AAAA",
#		"host":"AMIYO",
#		"server_name": "urologos retirados",
#		"max_players": 13,
#		"players_count": 1,
#		"players": [{"username": "amiyo", "is_host": true}],
#		"rounds": 5,
#		"round_time": 15,
#		"action_queue_limit": 3,
#		"scenario": "Dungeon",
#		"mode": "all_vs_all",
#		"private":  false
#	}]).exec()
##
#	await get_tree().create_timer(1.5).timeout
#
#	GodotSupabase.auth.sign_out()


