ASHENROOTS DEDICATED SERVER

1. Open UDP port 24567 in the firewall/router.
2. Linux: configure environment variables if needed, then run ./start_server.sh
   Windows: set variables in Command Prompt, then run start_server.bat

Settings (environment variables):
  WORLD=0
  PORT=24567
  SERVER_NAME=My Shadowgrove
  PASSWORD=
  PVP=false

Administration while the server is running:
  Linux:  ./admin.sh STATUS
  Windows: admin.bat STATUS

Commands:
  STATUS                 Print roster, ban count and network diagnostics.
  SAVE                   Force a world save and update data/world_export.json.
  KICK <peer_id>         Disconnect a player shown by STATUS.
  BAN <peer_id>          Persistently ban that player's profile and disconnect it.
  CLEAR_BANS             Remove every persistent ban.
  SHUTDOWN [reason]      Save, notify clients, disconnect them and exit cleanly.

Connection events are appended as JSON lines to the Godot user-data file
server_connections.log. The persistent server_bans.json file is stored beside it.
The exact platform location is printed by Godot and documented at:
https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html

The current world export is data/world_export.json. It can be imported into a client
world slot from MULTIPLAYER -> IMPORT. Keep the whole data directory in backups.

The bundled Godot runtime is distributed under the MIT license. Its license and
third-party notices are included as GODOT_LICENSE.txt and GODOT_COPYRIGHT.txt.
