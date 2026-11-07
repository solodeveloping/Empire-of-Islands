## This is for the UI
## Try not to use it for other things
## And let's not over use it
extends Node
class_name StaticFactions

# Such system won't work for multiplayer for instance
# (server side)

# FIXME: use Global instead?
const BELONGS_TO_LOCAL_PLAYER_META: String = "belongs_to_local_player_faction"
static var local_player_faction_id: int = 0
