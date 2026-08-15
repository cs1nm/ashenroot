extends Node
class_name NetworkSession

## ENet session used by listen servers, dedicated servers and clients.
## The game remains fully playable with multiplayer_peer == null (offline).

signal status_changed(message: String)
signal roster_changed()
signal session_started()
signal session_stopped(reason: String)

const PROTOCOL_VERSION := 2
const MAX_PLAYERS := 8
const IDENTITY_PATH := "user://network_identity.txt"
const IDENTITY_SEPARATOR := "|#|"
const DEFAULT_PORT := 24567
const MAX_WORLD_BYTES := 32 * 1024 * 1024
const PLAYER_SYNC_INTERVAL := 1.0 / 20.0
const ENTITY_SYNC_INTERVAL := 1.0 / 8.0
const MAX_PLAYER_SPEED := 720.0
const TELEPORT_GRACE := 96.0

enum Mode { OFFLINE, LISTEN_SERVER, CLIENT, DEDICATED_SERVER }

var game: Node
var mode := Mode.OFFLINE
var peer: ENetMultiplayerPeer
var players: Dictionary = {}
var authenticated_peers: Dictionary = {}
var peer_profile_ids: Dictionary = {}
var local_profile_id := ""
var server_name := "Shadowgrove Server"
var server_password_hash := ""
var pvp_enabled := false
var local_player_name := "Wanderer"
var joined := false
var last_error := ""
var listen_port := DEFAULT_PORT

var _join_password := ""
var _player_sync_timer := 0.0
var _entity_sync_timer := 0.0
var _last_state_msec: Dictionary = {}
var _last_damage_msec: Dictionary = {}
var _applying_remote_tile := false


func setup(owner_game: Node) -> void:
	game = owner_game
	local_profile_id = _load_or_create_identity()
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_active() -> bool:
	return mode != Mode.OFFLINE


func is_server() -> bool:
	return mode == Mode.LISTEN_SERVER or mode == Mode.DEDICATED_SERVER


func is_client() -> bool:
	return mode == Mode.CLIENT


func is_dedicated() -> bool:
	return mode == Mode.DEDICATED_SERVER


func local_peer_id() -> int:
	return multiplayer.get_unique_id() if is_active() else 1


func player_count() -> int:
	return players.size()


func profile_id_for_peer(peer_id: int) -> String:
	return str(peer_profile_ids.get(peer_id, "host" if peer_id == 1 and mode == Mode.LISTEN_SERVER else ""))


func request_game_action(action: String, payload := {}) -> void:
	if not joined:
		return
	var safe_action := action.substr(0, 32)
	var safe_payload: Dictionary = payload if payload is Dictionary else {}
	if is_server():
		_apply_game_action(local_peer_id(), safe_action, safe_payload)
	else:
		_request_game_action.rpc_id(1, safe_action, safe_payload)


func send_player_profile(target_peer: int, profile: Dictionary, message := "") -> void:
	if not is_server() or target_peer <= 1 or not players.has(target_peer) or target_peer not in multiplayer.get_peers():
		return
	_receive_player_profile.rpc_id(target_peer, profile, message.substr(0, 160))


func send_chest_state(target_peer: int, chest_key: String, loot: Dictionary, message := "") -> void:
	if not is_server() or target_peer <= 1 or not players.has(target_peer) or target_peer not in multiplayer.get_peers():
		return
	_receive_chest_state.rpc_id(target_peer, chest_key.substr(0, 32), loot, message.substr(0, 160))


func send_authoritative_damage(target_peer: int, new_health: int, damage: int, direction: Vector2, damage_type: String, status: String, attacker_name: String) -> void:
	if not is_server() or not players.has(target_peer):
		return
	if target_peer == 1 and mode == Mode.LISTEN_SERVER:
		if game != null and game.has_method("_network_receive_authoritative_damage"):
			game.call("_network_receive_authoritative_damage", new_health, damage, direction, _safe_damage_type(damage_type), _safe_status(status), attacker_name)
	else:
		_receive_authoritative_damage.rpc_id(target_peer, maxi(0, new_health), clampi(damage, 0, 200), direction, _safe_damage_type(damage_type), _safe_status(status), attacker_name.substr(0, 32))


func send_respawn(target_peer: int, spawn: Vector2, restored_health: int) -> void:
	if not is_server() or target_peer <= 1 or not players.has(target_peer) or target_peer not in multiplayer.get_peers():
		return
	_receive_respawn.rpc_id(target_peer, spawn, maxi(1, restored_health))


func host_server(port: int, password: String, display_name: String, player_name: String, enable_pvp: bool, dedicated := false) -> Error:
	shutdown("")
	listen_port = clampi(port, 1, 65535)
	server_name = _sanitize_server_name(display_name)
	server_password_hash = password.sha256_text() if password != "" else ""
	pvp_enabled = enable_pvp
	local_player_name = _sanitize_player_name(player_name)
	peer = ENetMultiplayerPeer.new()
	var client_slots := MAX_PLAYERS if dedicated else MAX_PLAYERS - 1
	var result := peer.create_server(listen_port, client_slots)
	if result != OK:
		peer = null
		_set_error("Cannot open UDP port %d (%s)." % [listen_port, error_string(result)])
		return result
	multiplayer.multiplayer_peer = peer
	mode = Mode.DEDICATED_SERVER if dedicated else Mode.LISTEN_SERVER
	joined = true
	authenticated_peers.clear()
	players.clear()
	peer_profile_ids.clear()
	if not dedicated:
		authenticated_peers[1] = true
		peer_profile_ids[1] = "host"
		players[1] = _local_state(local_player_name)
	_last_state_msec[1] = Time.get_ticks_msec()
	_emit_status("Server ready on UDP %d — %s" % [listen_port, "PvP" if pvp_enabled else "PvE"])
	session_started.emit()
	roster_changed.emit()
	return OK


func join_server(address: String, port: int, password: String, player_name: String) -> Error:
	shutdown("")
	var clean_address := address.strip_edges()
	if clean_address == "":
		clean_address = "127.0.0.1"
	listen_port = clampi(port, 1, 65535)
	local_player_name = _sanitize_player_name(player_name)
	_join_password = password
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_client(clean_address, listen_port)
	if result != OK:
		peer = null
		_set_error("Cannot connect to %s:%d (%s)." % [clean_address, listen_port, error_string(result)])
		return result
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	joined = false
	players.clear()
	authenticated_peers.clear()
	peer_profile_ids.clear()
	_emit_status("Connecting to %s:%d…" % [clean_address, listen_port])
	return OK


func shutdown(reason := "Disconnected.") -> void:
	var was_active := is_active()
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	mode = Mode.OFFLINE
	joined = false
	players.clear()
	authenticated_peers.clear()
	peer_profile_ids.clear()
	_last_state_msec.clear()
	_last_damage_msec.clear()
	_player_sync_timer = 0.0
	_entity_sync_timer = 0.0
	_join_password = ""
	if was_active:
		roster_changed.emit()
		session_stopped.emit(reason)
		if reason != "":
			_emit_status(reason)


func tick(delta: float) -> void:
	if not is_active() or not joined:
		return
	_update_render_positions(delta)
	_player_sync_timer -= delta
	if _player_sync_timer <= 0.0:
		_player_sync_timer = PLAYER_SYNC_INTERVAL
		var state := _local_state(local_player_name)
		if mode == Mode.CLIENT:
			_submit_player_state.rpc_id(1, state)
		elif mode == Mode.LISTEN_SERVER:
			players[1] = state
			_last_state_msec[1] = Time.get_ticks_msec()
			_receive_player_state.rpc(1, state)
	_entity_sync_timer -= delta
	if is_server() and _entity_sync_timer <= 0.0:
		_entity_sync_timer = ENTITY_SYNC_INTERVAL
		if not multiplayer.get_peers().is_empty() and game != null and game.has_method("_network_build_entity_snapshot"):
			_receive_entity_snapshot.rpc(game.call("_network_build_entity_snapshot"))


func request_enemy_damage(enemy_id: int, damage: int, knockback: Vector2, damage_type: String, status: String) -> void:
	if not joined:
		return
	if is_server():
		_apply_enemy_damage(local_peer_id(), enemy_id, damage, knockback, damage_type, status)
	else:
		_request_enemy_damage.rpc_id(1, enemy_id, damage, knockback, damage_type, status)


func request_projectile(pos: Vector2, velocity: Vector2, damage: int, kind: String, color: Color, life: float, damage_type: String, status: String) -> void:
	if not joined:
		return
	if is_server():
		_apply_projectile_request(local_peer_id(), pos, velocity, damage, kind, color, life, damage_type, status)
	else:
		_request_projectile.rpc_id(1, pos, velocity, damage, kind, color, life, damage_type, status)


func request_pvp_melee(range_px: float, damage: int, facing: int, damage_type: String) -> void:
	if not joined or not pvp_enabled:
		return
	if is_server():
		_apply_pvp_melee(local_peer_id(), range_px, damage, facing, damage_type)
	else:
		_request_pvp_melee.rpc_id(1, range_px, damage, facing, damage_type)


func damage_player_from_enemy(target_peer: int, raw_damage: int, direction: Vector2, damage_type: String, status: String) -> void:
	if not is_server() or not players.has(target_peer):
		return
	if target_peer == 1 and mode == Mode.LISTEN_SERVER:
		if game != null and game.has_method("_network_receive_enemy_hit"):
			game.call("_network_receive_enemy_hit", raw_damage, direction, _safe_damage_type(damage_type), _safe_status(status))
		return
	if game != null and game.has_method("_network_server_apply_player_damage"):
		var result: Dictionary = game.call("_network_server_apply_player_damage", target_peer, clampi(raw_damage, 1, 200), _safe_damage_type(damage_type), _safe_status(status))
		if not result.is_empty():
			send_authoritative_damage(target_peer, int(result.get("health", 0)), int(result.get("damage", raw_damage)), direction, damage_type, status, "Creature")


func damage_player_from_pvp(attacker_peer: int, target_peer: int, damage: int, direction: Vector2, damage_type: String) -> void:
	if not is_server() or not pvp_enabled or not players.has(attacker_peer) or not players.has(target_peer):
		return
	var safe_damage := clampi(damage, 1, 120)
	var attacker_name := str((players[attacker_peer] as Dictionary).get("name", "Player"))
	if target_peer == 1 and mode == Mode.LISTEN_SERVER:
		if game != null and game.has_method("_network_receive_player_damage"):
			game.call("_network_receive_player_damage", safe_damage, direction, _safe_damage_type(damage_type), attacker_name)
		return
	if game != null and game.has_method("_network_server_apply_player_damage"):
		var result: Dictionary = game.call("_network_server_apply_player_damage", target_peer, safe_damage, _safe_damage_type(damage_type), "")
		if not result.is_empty():
			send_authoritative_damage(target_peer, int(result.get("health", 0)), int(result.get("damage", safe_damage)), direction, damage_type, "", attacker_name)


func request_loot_pickup(loot_id: int) -> void:
	if not joined or loot_id < 0:
		return
	if is_server():
		_apply_loot_pickup(local_peer_id(), loot_id)
	else:
		_request_loot_pickup.rpc_id(1, loot_id)


func grant_loot(target_peer: int, loot_id: int, item_id: String, amount: int) -> void:
	if not is_server() or not players.has(target_peer):
		return
	if target_peer == 1 and mode == Mode.LISTEN_SERVER:
		if game != null and game.has_method("_network_receive_loot"):
			game.call("_network_receive_loot", loot_id, item_id, amount)
		return
	if game != null and game.has_method("_network_server_grant_item"):
		game.call("_network_server_grant_item", target_peer, loot_id, item_id, amount)
		_receive_loot.rpc_id(target_peer, loot_id, item_id, amount)


func notify_local_tile_changed(x: int, y: int, tile: int) -> void:
	if not joined or _applying_remote_tile:
		return
	if mode == Mode.CLIENT:
		_request_tile_change.rpc_id(1, x, y, tile)
	elif is_server():
		_apply_tile_change.rpc(x, y, tile)


func set_pvp_enabled(enabled: bool) -> void:
	if not is_server():
		return
	pvp_enabled = enabled
	_receive_server_rules.rpc(pvp_enabled)
	_emit_status("Server mode changed to %s." % ("PvP" if pvp_enabled else "PvE"))


func kick_peer(peer_id: int, reason := "Kicked by server.") -> void:
	if not is_server() or peer_id <= 1 or not authenticated_peers.has(peer_id):
		return
	_reject_join.rpc_id(peer_id, reason)
	call_deferred("_disconnect_peer_deferred", peer_id)


func _on_peer_connected(peer_id: int) -> void:
	if is_server():
		_emit_status("Peer %d connected; waiting for handshake…" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	var state: Dictionary = players.get(peer_id, {})
	var display_name := str(state.get("name", "Player"))
	if is_server() and game != null and game.has_method("_network_server_peer_disconnected"):
		game.call("_network_server_peer_disconnected", peer_id, str(peer_profile_ids.get(peer_id, "")), state)
	authenticated_peers.erase(peer_id)
	players.erase(peer_id)
	peer_profile_ids.erase(peer_id)
	_last_state_msec.erase(peer_id)
	for action_key in _last_damage_msec.keys():
		if str(action_key).begins_with("%d:" % peer_id):
			_last_damage_msec.erase(action_key)
	if is_server():
		_peer_left.rpc(peer_id)
	_emit_status("%s left the server." % display_name)
	roster_changed.emit()


func _on_connected_to_server() -> void:
	_emit_status("Connected; authorizing…")
	var identity_payload := "%s%s%s" % [local_player_name, IDENTITY_SEPARATOR, local_profile_id]
	_submit_handshake.rpc_id(1, PROTOCOL_VERSION, identity_payload, _join_password)


func _on_connection_failed() -> void:
	last_error = "Connection failed. Check IP, UDP port and firewall."
	shutdown(last_error)


func _on_server_disconnected() -> void:
	last_error = "Server disconnected."
	if game != null and game.has_method("_network_return_to_menu"):
		game.call_deferred("_network_return_to_menu", last_error)
	shutdown(last_error)


@rpc("any_peer", "call_remote", "reliable")
func _submit_handshake(protocol: int, requested_name: String, password: String) -> void:
	if not is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if protocol != PROTOCOL_VERSION:
		_reject_peer(sender, "Version mismatch (client %d, server %d)." % [protocol, PROTOCOL_VERSION])
		return
	if server_password_hash != "" and password.sha256_text() != server_password_hash:
		_reject_peer(sender, "Wrong server password.")
		return
	if players.size() >= MAX_PLAYERS:
		_reject_peer(sender, "Server is full (%d players)." % MAX_PLAYERS)
		return
	var identity_parts := requested_name.split(IDENTITY_SEPARATOR, false, 1)
	if identity_parts.size() != 2:
		_reject_peer(sender, "Client identity is missing. Update the game.")
		return
	var profile_id := _sanitize_profile_id(str(identity_parts[1]))
	if profile_id == "":
		_reject_peer(sender, "Client identity is invalid.")
		return
	if profile_id in peer_profile_ids.values():
		_reject_peer(sender, "This player profile is already connected.")
		return
	var clean_name := _unique_player_name(_sanitize_player_name(str(identity_parts[0])))
	var spawn := _spawn_for_peer(sender)
	var profile: Dictionary = {}
	if game != null and game.has_method("_network_prepare_player_profile"):
		profile = game.call("_network_prepare_player_profile", profile_id, clean_name, spawn)
		var saved_pos: Variant = profile.get("position", spawn)
		if saved_pos is Vector2:
			spawn = saved_pos
	var state := _default_remote_state(clean_name, spawn)
	state["health"] = int(profile.get("health", state.get("health", 100)))
	state["oxygen"] = float(profile.get("oxygen", state.get("oxygen", 100.0)))
	state["body_temperature"] = float(profile.get("body_temperature", state.get("body_temperature", 37.0)))
	state["flight_charge"] = float(profile.get("flight_charge", state.get("flight_charge", 100.0)))
	state["class"] = str(profile.get("active_class", state.get("class", "Warrior")))
	state["weapon"] = str(profile.get("equipped_weapon", ""))
	authenticated_peers[sender] = true
	peer_profile_ids[sender] = profile_id
	players[sender] = state
	_last_state_msec[sender] = Time.get_ticks_msec()
	var payload := _encode_world()
	if payload.is_empty():
		authenticated_peers.erase(sender)
		peer_profile_ids.erase(sender)
		players.erase(sender)
		_reject_peer(sender, "Server could not serialize the world.")
		return
	_accept_join.rpc_id(sender, sender, server_name, pvp_enabled, spawn, payload, players, profile)
	_peer_joined.rpc(sender, state)
	_emit_status("%s joined (%d/%d)." % [clean_name, players.size(), MAX_PLAYERS])
	roster_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _accept_join(assigned_peer_id: int, accepted_server_name: String, server_pvp: bool, spawn: Vector2, world_payload: PackedByteArray, roster: Dictionary, profile: Dictionary) -> void:
	if mode != Mode.CLIENT:
		return
	if assigned_peer_id != multiplayer.get_unique_id():
		_set_error("Server returned an invalid peer id.")
		return
	var world_data := _decode_world(world_payload)
	if world_data.is_empty():
		_set_error("World transfer failed or exceeded the size limit.")
		shutdown(last_error)
		return
	server_name = accepted_server_name
	pvp_enabled = server_pvp
	players = roster.duplicate(true)
	joined = true
	_join_password = ""
	if game != null and game.has_method("_network_apply_world_data"):
		game.call("_network_apply_world_data", world_data, spawn, server_name)
	if game != null and game.has_method("_network_apply_player_profile"):
		game.call("_network_apply_player_profile", profile, true, "Profile restored.")
	_emit_status("Joined %s — %s — %d/%d players." % [server_name, "PvP" if pvp_enabled else "PvE", players.size(), MAX_PLAYERS])
	session_started.emit()
	roster_changed.emit()


@rpc("authority", "call_remote", "reliable")
func _reject_join(reason: String) -> void:
	last_error = reason
	if game != null and game.has_method("_network_join_rejected"):
		game.call("_network_join_rejected", reason)
	shutdown(reason)


@rpc("authority", "call_remote", "reliable")
func _peer_joined(peer_id: int, state: Dictionary) -> void:
	players[peer_id] = state
	roster_changed.emit()
	_emit_status("%s joined the server." % str(state.get("name", "Player")))


@rpc("authority", "call_remote", "reliable")
func _peer_left(peer_id: int) -> void:
	players.erase(peer_id)
	roster_changed.emit()


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _submit_player_state(state: Dictionary) -> void:
	if not is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not authenticated_peers.has(sender):
		return
	var sanitized := _sanitize_remote_state(sender, state)
	players[sender] = sanitized
	if game != null and game.has_method("_network_server_update_profile_state"):
		game.call("_network_server_update_profile_state", sender, sanitized)
	_receive_player_state.rpc(sender, sanitized)


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _receive_player_state(peer_id: int, state: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	var previous: Dictionary = players.get(peer_id, {})
	state["render_pos"] = previous.get("render_pos", previous.get("pos", state.get("pos", Vector2.ZERO)))
	players[peer_id] = state
	if game != null:
		game.queue_redraw()


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receive_entity_snapshot(snapshot: Dictionary) -> void:
	if mode != Mode.CLIENT or not joined:
		return
	if game != null and game.has_method("_network_apply_entity_snapshot"):
		game.call("_network_apply_entity_snapshot", snapshot)


@rpc("any_peer", "call_remote", "reliable")
func _request_enemy_damage(enemy_id: int, damage: int, knockback: Vector2, damage_type: String, status: String) -> void:
	if not is_server():
		return
	_apply_enemy_damage(multiplayer.get_remote_sender_id(), enemy_id, damage, knockback, damage_type, status)


@rpc("any_peer", "call_remote", "reliable")
func _request_projectile(pos: Vector2, velocity: Vector2, damage: int, kind: String, color: Color, life: float, damage_type: String, status: String) -> void:
	if not is_server():
		return
	_apply_projectile_request(multiplayer.get_remote_sender_id(), pos, velocity, damage, kind, color, life, damage_type, status)


@rpc("any_peer", "call_remote", "reliable")
func _request_pvp_melee(range_px: float, damage: int, attack_facing: int, damage_type: String) -> void:
	if not is_server():
		return
	_apply_pvp_melee(multiplayer.get_remote_sender_id(), range_px, damage, attack_facing, damage_type)


@rpc("any_peer", "call_remote", "reliable")
func _request_loot_pickup(loot_id: int) -> void:
	if not is_server():
		return
	_apply_loot_pickup(multiplayer.get_remote_sender_id(), loot_id)


@rpc("any_peer", "call_remote", "reliable")
func _request_game_action(action: String, payload: Dictionary) -> void:
	if not is_server():
		return
	_apply_game_action(multiplayer.get_remote_sender_id(), action.substr(0, 32), payload)


@rpc("any_peer", "call_remote", "reliable")
func _request_tile_change(x: int, y: int, tile: int) -> void:
	if not is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not authenticated_peers.has(sender) or not _valid_tile_request(sender, x, y, tile):
		return
	if game == null or not game.has_method("_network_allow_direct_tile_change") or not bool(game.call("_network_allow_direct_tile_change", sender, x, y, tile)):
		return
	_applying_remote_tile = true
	if game != null and game.has_method("_network_apply_tile_change"):
		game.call("_network_apply_tile_change", x, y, tile)
	_applying_remote_tile = false
	_apply_tile_change.rpc(x, y, tile)


@rpc("authority", "call_remote", "reliable")
func _apply_tile_change(x: int, y: int, tile: int) -> void:
	if game == null or not game.has_method("_network_apply_tile_change"):
		return
	_applying_remote_tile = true
	game.call("_network_apply_tile_change", x, y, tile)
	_applying_remote_tile = false


@rpc("authority", "call_remote", "reliable")
func _receive_player_profile(profile: Dictionary, message: String) -> void:
	if game != null and game.has_method("_network_apply_player_profile"):
		game.call("_network_apply_player_profile", profile, false, message)


@rpc("authority", "call_remote", "reliable")
func _receive_chest_state(chest_key: String, loot: Dictionary, message: String) -> void:
	if game != null and game.has_method("_network_receive_chest_state"):
		game.call("_network_receive_chest_state", chest_key, loot, message)


@rpc("authority", "call_remote", "reliable")
func _receive_authoritative_damage(new_health: int, damage: int, direction: Vector2, damage_type: String, status: String, attacker_name: String) -> void:
	if game != null and game.has_method("_network_receive_authoritative_damage"):
		game.call("_network_receive_authoritative_damage", new_health, damage, direction, damage_type, status, attacker_name)


@rpc("authority", "call_remote", "reliable")
func _receive_respawn(spawn: Vector2, restored_health: int) -> void:
	if game != null and game.has_method("_network_apply_respawn"):
		game.call("_network_apply_respawn", spawn, restored_health)


@rpc("authority", "call_remote", "reliable")
func _receive_loot(loot_id: int, item_id: String, amount: int) -> void:
	if game != null and game.has_method("_network_receive_loot"):
		game.call("_network_receive_loot", loot_id, item_id, amount)


@rpc("authority", "call_remote", "reliable")
func _receive_player_damage(amount: int, direction: Vector2, damage_type: String, attacker_name: String) -> void:
	if game != null and game.has_method("_network_receive_player_damage"):
		game.call("_network_receive_player_damage", amount, direction, damage_type, attacker_name)


@rpc("authority", "call_remote", "reliable")
func _receive_enemy_hit(raw_damage: int, direction: Vector2, damage_type: String, status: String) -> void:
	if game != null and game.has_method("_network_receive_enemy_hit"):
		game.call("_network_receive_enemy_hit", raw_damage, direction, damage_type, status)


@rpc("authority", "call_remote", "reliable")
func _receive_server_rules(server_pvp: bool) -> void:
	pvp_enabled = server_pvp
	_emit_status("Server mode: %s." % ("PvP" if pvp_enabled else "PvE"))


func _apply_game_action(sender: int, action: String, payload: Dictionary) -> void:
	var allowed := ["craft", "chest_open", "chest_close", "chest_take", "chest_store", "drop", "place", "mine", "interact", "consume", "loadout", "respawn"]
	if action not in allowed:
		return
	var interval := 45
	if action in ["craft", "drop", "place", "consume", "respawn"]:
		interval = 120
	if not _can_accept_action(sender, interval, "game_%s" % action):
		return
	if game != null and game.has_method("_network_server_game_action"):
		game.call("_network_server_game_action", sender, action, payload)


func _apply_loot_pickup(sender: int, loot_id: int) -> void:
	if not _can_accept_action(sender, 120, "loot_%d" % loot_id):
		return
	if game != null and game.has_method("_network_server_pickup_loot"):
		game.call("_network_server_pickup_loot", sender, loot_id)


func _apply_enemy_damage(sender: int, enemy_id: int, damage: int, knockback: Vector2, damage_type: String, status: String) -> void:
	if not _can_accept_action(sender, 55, "enemy_%d" % enemy_id):
		return
	if game != null and game.has_method("_network_server_damage_enemy"):
		var safe_damage := clampi(damage, 1, 120)
		if game.has_method("_network_validated_attack_damage"):
			safe_damage = int(game.call("_network_validated_attack_damage", sender, safe_damage, "melee"))
		game.call("_network_server_damage_enemy", sender, enemy_id, safe_damage, knockback.limit_length(2.0), _safe_damage_type(damage_type), _safe_status(status))


func _apply_projectile_request(sender: int, pos: Vector2, velocity: Vector2, damage: int, kind: String, color: Color, life: float, damage_type: String, status: String) -> void:
	if not _can_accept_action(sender, 80, "projectile"):
		return
	var state: Dictionary = players.get(sender, {})
	var player_pos: Vector2 = state.get("pos", pos)
	var safe_kind := kind.substr(0, 24)
	if player_pos.distance_to(pos) > 42.0 or velocity.length() > 520.0:
		return
	if game != null and game.has_method("_network_validate_projectile_kind") and not bool(game.call("_network_validate_projectile_kind", sender, safe_kind)):
		return
	if game != null and game.has_method("_network_server_spawn_projectile"):
		var safe_damage := clampi(damage, 1, 120)
		if game.has_method("_network_validated_attack_damage"):
			safe_damage = int(game.call("_network_validated_attack_damage", sender, safe_damage, safe_kind))
		game.call("_network_server_spawn_projectile", sender, pos, velocity, safe_damage, safe_kind, color, clampf(life, 0.1, 2.5), _safe_damage_type(damage_type), _safe_status(status))


func _apply_pvp_melee(sender: int, range_px: float, damage: int, attack_facing: int, damage_type: String) -> void:
	if not pvp_enabled or not _can_accept_action(sender, 120, "pvp_melee"):
		return
	if not players.has(sender):
		return
	var attacker: Dictionary = players[sender]
	var attacker_pos: Vector2 = attacker.get("pos", Vector2.ZERO)
	var safe_range := clampf(range_px, 16.0, 58.0)
	var direction := 1 if attack_facing >= 0 else -1
	var center := attacker_pos + Vector2(float(direction) * safe_range * 0.6, 0.0)
	var attack_rect := Rect2(center - Vector2(safe_range * 0.5, 18.0), Vector2(safe_range, 36.0))
	var safe_damage := clampi(damage, 1, 80)
	if game != null and game.has_method("_network_validated_attack_damage"):
		safe_damage = int(game.call("_network_validated_attack_damage", sender, safe_damage, "melee"))
	for target_variant in players.keys():
		var target_id := int(target_variant)
		if target_id == sender:
			continue
		var target: Dictionary = players[target_id]
		var target_pos: Vector2 = target.get("pos", Vector2.ZERO)
		if not attack_rect.intersects(Rect2(target_pos - Vector2(7.0, 14.0), Vector2(14.0, 28.0))):
			continue
		var hit_dir := Vector2(float(direction), -0.25).normalized()
		damage_player_from_pvp(sender, target_id, safe_damage, hit_dir, damage_type)


func _can_accept_action(sender: int, minimum_interval_msec: int, channel := "action") -> bool:
	if not authenticated_peers.has(sender) or not players.has(sender):
		return false
	var now := Time.get_ticks_msec()
	var key := "%d:%s" % [sender, channel]
	var last := int(_last_damage_msec.get(key, -100000))
	if now - last < minimum_interval_msec:
		return false
	_last_damage_msec[key] = now
	return true


func _valid_tile_request(sender: int, x: int, y: int, tile: int) -> bool:
	if game == null:
		return false
	var world_tiles := Vector2i(1280, 190)
	if game.has_method("_network_world_size_tiles"):
		world_tiles = game.call("_network_world_size_tiles")
	if x < 0 or y < 0 or x >= world_tiles.x or y >= world_tiles.y:
		return false
	var tile_count := int(game.call("_network_tile_count")) if game.has_method("_network_tile_count") else 256
	if tile < 0 or tile >= tile_count:
		return false
	var state: Dictionary = players.get(sender, {})
	var player_pos: Vector2 = state.get("pos", Vector2.ZERO)
	var tile_size := float(game.call("_network_tile_size")) if game.has_method("_network_tile_size") else 16.0
	var tile_pos := Vector2(float(x) + 0.5, float(y) + 0.5) * tile_size
	# Trees and multi-tile structures can change tiles beyond the normal hand reach.
	return player_pos.distance_to(tile_pos) <= tile_size * 13.0


func _sanitize_remote_state(peer_id: int, incoming: Dictionary) -> Dictionary:
	var previous: Dictionary = players.get(peer_id, _default_remote_state("Player", Vector2.ZERO))
	var now := Time.get_ticks_msec()
	var last := int(_last_state_msec.get(peer_id, now))
	var elapsed := clampf(float(now - last) / 1000.0, 0.01, 0.5)
	_last_state_msec[peer_id] = now
	var old_pos: Vector2 = previous.get("pos", Vector2.ZERO)
	var requested_pos: Vector2 = incoming.get("pos", old_pos)
	var max_distance := MAX_PLAYER_SPEED * elapsed + TELEPORT_GRACE
	if old_pos.distance_to(requested_pos) > max_distance:
		requested_pos = old_pos + old_pos.direction_to(requested_pos) * max_distance
	var world_bounds := Vector2(20480.0, 3040.0)
	if game != null and game.has_method("_network_world_bounds"):
		world_bounds = game.call("_network_world_bounds")
	requested_pos.x = clampf(requested_pos.x, 0.0, world_bounds.x)
	requested_pos.y = clampf(requested_pos.y, 0.0, world_bounds.y)
	var previous_health := clampi(int(previous.get("health", 100)), 0, 1000)
	var reported_health := clampi(int(incoming.get("health", previous_health)), 0, 1000)
	var respawn_grace_until := int(previous.get("respawn_grace_until", 0))
	var accepted_health := previous_health if now < respawn_grace_until else mini(previous_health, reported_health)
	if now < respawn_grace_until and reported_health <= 0:
		requested_pos = old_pos
	return {
		"name": str(previous.get("name", "Player")),
		"pos": requested_pos,
		"vel": (incoming.get("vel", Vector2.ZERO) as Vector2).limit_length(MAX_PLAYER_SPEED),
		"facing": 1 if int(incoming.get("facing", 1)) >= 0 else -1,
		"on_floor": bool(incoming.get("on_floor", false)),
		# Client-side hazards may report damage, but clients can never heal
		# themselves through the movement stream. A short post-respawn grace
		# prevents a delayed pre-respawn packet from killing them again.
		"health": accepted_health,
		"max_health": clampi(int(previous.get("max_health", 100)), 1, 1000),
		"respawn_grace_until": respawn_grace_until,
		"oxygen": clampf(float(incoming.get("oxygen", previous.get("oxygen", 100.0))), 0.0, 1000.0),
		"body_temperature": clampf(float(incoming.get("body_temperature", previous.get("body_temperature", 37.0))), 0.0, 100.0),
		"flight_charge": clampf(float(incoming.get("flight_charge", previous.get("flight_charge", 100.0))), 0.0, 1000.0),
		"class": str(previous.get("class", "Warrior")).substr(0, 24),
		"weapon": str(previous.get("weapon", "")).substr(0, 40),
		"attack_kind": str(incoming.get("attack_kind", "")).substr(0, 16),
		"attack_ratio": clampf(float(incoming.get("attack_ratio", 0.0)), 0.0, 1.0),
		"tint": previous.get("tint", _peer_color(peer_id)),
		"render_pos": previous.get("render_pos", old_pos)
	}


func _update_render_positions(delta: float) -> void:
	var blend := 1.0 - exp(-18.0 * delta)
	var own_id := multiplayer.get_unique_id()
	for peer_variant in players.keys():
		var peer_id := int(peer_variant)
		if peer_id == own_id:
			continue
		var state: Dictionary = players[peer_id]
		var target: Vector2 = state.get("pos", Vector2.ZERO)
		var rendered: Vector2 = state.get("render_pos", target)
		state["render_pos"] = rendered.lerp(target, blend)
		players[peer_id] = state


func _local_state(name: String) -> Dictionary:
	if game != null and game.has_method("_network_local_player_state"):
		var state: Dictionary = game.call("_network_local_player_state", name)
		state["name"] = _sanitize_player_name(name)
		state["tint"] = _peer_color(multiplayer.get_unique_id())
		return state
	return _default_remote_state(name, Vector2.ZERO)


func _default_remote_state(name: String, spawn: Vector2) -> Dictionary:
	return {
		"name": name,
		"pos": spawn,
		"vel": Vector2.ZERO,
		"facing": 1,
		"on_floor": false,
		"health": 100,
		"max_health": 100,
		"oxygen": 100.0,
		"body_temperature": 37.0,
		"flight_charge": 100.0,
		"class": "Warrior",
		"weapon": "",
		"attack_kind": "",
		"attack_ratio": 0.0,
		"tint": Color.WHITE
	}


func _spawn_for_peer(peer_id: int) -> Vector2:
	if game != null and game.has_method("_network_spawn_for_peer"):
		return game.call("_network_spawn_for_peer", peer_id)
	return Vector2(160.0 + float(peer_id % 6) * 20.0, 160.0)


func _encode_world() -> PackedByteArray:
	if game == null or not game.has_method("_build_network_world_data"):
		return PackedByteArray()
	var data: Dictionary = game.call("_build_network_world_data")
	var raw := JSON.stringify(data).to_utf8_buffer()
	if raw.size() <= 0 or raw.size() > MAX_WORLD_BYTES:
		return PackedByteArray()
	return raw.compress(FileAccess.COMPRESSION_GZIP)


func _decode_world(payload: PackedByteArray) -> Dictionary:
	if payload.is_empty():
		return {}
	var raw := payload.decompress_dynamic(MAX_WORLD_BYTES, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}


func _reject_peer(peer_id: int, reason: String) -> void:
	_reject_join.rpc_id(peer_id, reason)
	call_deferred("_disconnect_peer_deferred", peer_id)


func _disconnect_peer_deferred(peer_id: int) -> void:
	await get_tree().create_timer(0.15).timeout
	if peer != null and peer_id in multiplayer.get_peers():
		peer.disconnect_peer(peer_id)


func _unique_player_name(base_name: String) -> String:
	var used: Dictionary = {}
	for state_variant in players.values():
		var state: Dictionary = state_variant
		used[str(state.get("name", "")).to_lower()] = true
	if not used.has(base_name.to_lower()):
		return base_name
	for suffix in range(2, MAX_PLAYERS + 2):
		var candidate := "%s %d" % [base_name, suffix]
		if not used.has(candidate.to_lower()):
			return candidate
	return "%s %d" % [base_name, Time.get_ticks_msec() % 1000]


func _load_or_create_identity() -> String:
	var test_identity := _sanitize_profile_id(OS.get_environment("ASHENROOT_TEST_PROFILE_ID"))
	if test_identity != "":
		return test_identity
	if FileAccess.file_exists(IDENTITY_PATH):
		var existing := _sanitize_profile_id(FileAccess.get_file_as_string(IDENTITY_PATH).strip_edges())
		if existing != "":
			return existing
	var bytes := Crypto.new().generate_random_bytes(24)
	var generated := bytes.hex_encode()
	if generated == "":
		generated = (str(Time.get_unix_time_from_system()) + str(Time.get_ticks_usec()) + str(randi())).sha256_text().substr(0, 48)
	var file := FileAccess.open(IDENTITY_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(generated)
	return generated


func _sanitize_profile_id(value: String) -> String:
	var clean := value.strip_edges().to_lower()
	if clean.length() < 24 or clean.length() > 64:
		return ""
	for character in clean:
		if character not in "0123456789abcdef":
			return ""
	return clean


func _sanitize_player_name(value: String) -> String:
	var clean := value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	return (clean if clean != "" else "Wanderer").substr(0, 20)


func _sanitize_server_name(value: String) -> String:
	var clean := value.strip_edges().replace("\n", " ").replace("\r", " ")
	return (clean if clean != "" else "Shadowgrove Server").substr(0, 36)


func _safe_damage_type(value: String) -> String:
	return value if value in ["physical", "poison", "fire", "arcane"] else "physical"


func _safe_status(value: String) -> String:
	return value if value in ["", "poison", "burn", "slow", "root_bind", "fragile", "wet", "armor_break"] else ""


func _peer_color(peer_id: int) -> Color:
	var colors := [Color("f6e2b3"), Color("82d4ff"), Color("9ce36d"), Color("d5a6ff"), Color("ff9b7b"), Color("72e0c1"), Color("ffd166"), Color("aab8ff")]
	return colors[absi(peer_id) % colors.size()]


func _set_error(message: String) -> void:
	last_error = message
	_emit_status(message)


func _emit_status(message: String) -> void:
	status_changed.emit(message)
