# Repository content safety

- `content/letters*.json` is maintained on GitHub. Before content work run `python3 tools/sync_letters.py`; cloud values take priority.
- Keep these files tracked and published. Never remove them from Git because they appear in `.gitignore`.
- Run `python3 tools/sync_letters.py --setup` after checkout to enable hooks and local `skip-worktree` protection.
- Do not commit local text edits. For an explicitly requested schema addition, use `--add-missing-ui`, preserve every existing cloud value, and set `GARDEN_CONTENT_SCHEMA_UPDATE=1` only for that reviewed commit/push.
- Runtime UI copy belongs in both JSON variants. Keep their comments; run `python3 tests/content_schema.py` after schema changes.

- Delegate independent subtasks to subagents when doing so improves speed, token use, or context use; keep shared-file integration coordinated.

- Every shared corridor must render identically from either active room. Its material belongs to the physically upper room; use canonical corridor coordinates for variants and draw its longitudinal backdrop once, never through the cached neighbour too. Keep exactly one boundary row: no outer masonry ring, duplicate hedge crowns, forest/soil apron or additional corridor wall columns. When changing boundaries/fog, compare screenshots of the same physical corridor on both sides of the midpoint, including backdrop rows and fog geometry. Room fog bounds must follow actual floor bounds, excluding empty grid padding.
- Excavation boundaries use the standard cubic wall renderer and `wall_room3` earth-block textures, in the same final canonical corridor pass as other blocks. Never restore procedural earth mound banks or extra boundary rows. Both corridor halves use room3's material and canonical coordinates.
