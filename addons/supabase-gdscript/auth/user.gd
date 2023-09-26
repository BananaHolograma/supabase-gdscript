class_name GodotSupabaseUser extends Node

## AUTH ##
var access_token: String
var token_type: String
var refresh_token: String
var expires_in: int
var expires_at: int 

## USER ##
var id: String
var aud: String
var role: String
var email: String
var email_confirmed_at
var phone: String = ""
var last_sign_in_at: String

## METADATA ##
var app_metadata: Dictionary = {}
var user_metadata: Dictionary = {}

## IDENTITIES ##
var identities: Array = []

## DATES ##
var created_at: String
var updated_at: String


func initialize(params: Dictionary) -> void:
	for key in params.keys():
		self[key] = params[key]

### JSON STRUCTURE EXAMPLE FROM SUPABASE ###
#{
#  "access_token": "eyJhbGciOiJIUzI1NiIsImtpZCI6Ik...",
#  "token_type": "bearer",
#  "expires_in": 3600,
#  "expires_at": 1695748607,
#  "refresh_token": "0gBpB_8I7ct4lOp87iQqQg",
#  "user": {
#    "id": "8fbe56af-90fe-4631-9a31-6b7bf725679d",
#    "aud": "authenticated",
#    "role": "authenticated",
#    "email": "hello@friend.com",
#    "email_confirmed_at": "2023-09-26T16:16:47.538174267Z",
#    "phone": "",
#    "last_sign_in_at": "2023-09-26T16:16:47.540227213Z",
#    "app_metadata": {
#      "provider": "email",
#      "providers": [
#        "email"
#      ]
#    },
#    "user_metadata": {
#      "username": "mr.robot"
#    },
#    "identities": [
#      {
#        "id": "8fbe56af-90fe-4631-9a31-6b7bf725679d",
#        "user_id": "8fbe56af-90fe-4631-9a31-6b7bf725679d",
#        "identity_data": {
#          "email": "hello@friend.com",
#          "sub": "8fbe56af-90fe-4631-9a31-6b7bf725679d"
#        },
#        "provider": "email",
#        "last_sign_in_at": "2023-09-26T16:16:47.536613956Z",
#        "created_at": "2023-09-26T16:16:47.536664Z",
#        "updated_at": "2023-09-26T16:16:47.536664Z"
#      }
#    ],
#    "created_at": "2023-09-26T16:16:47.530522Z",
#    "updated_at": "2023-09-26T16:16:47.541805Z"
#  }
#}
