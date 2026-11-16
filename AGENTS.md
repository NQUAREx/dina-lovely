# Repository content safety

- `content/letters*.json` is maintained on GitHub. Before content work run `python3 tools/sync_letters.py`; cloud values take priority.
- Keep these files tracked and published. Never remove them from Git because they appear in `.gitignore`.
- Run `python3 tools/sync_letters.py --setup` after checkout to enable hooks and local `skip-worktree` protection.
- Do not commit local text edits. For an explicitly requested schema addition, use `--add-missing-ui`, preserve every existing cloud value, and set `GARDEN_CONTENT_SCHEMA_UPDATE=1` only for that reviewed commit/push.
- Runtime UI copy belongs in both JSON variants. Keep their comments; run `python3 tests/content_schema.py` after schema changes.

- Delegate independent subtasks to subagents when doing so improves speed, token use, or context use; keep shared-file integration coordinated.

- Every shared corridor must render identically from either active room. Its material belongs to the physically upper room; use canonical corridor coordinates for variants and draw its longitudinal backdrop once, never through the cached neighbour too. Preserve the extra junction apron rows that conceal the outer edge; draw each room’s apron with the shared corridor material owner even when that room is cached. When changing boundaries/fog, compare screenshots of the same physical corridor on both sides of the midpoint, including backdrop rows and fog geometry. Room fog bounds must follow actual floor bounds, excluding empty grid padding.
- Excavation corridor boundaries use `earth_boundary.draw_shared_corridor()` and the cached room3 procedural bake, not wall_room3 PNGs. Keep both halves in the final shared pass so active-room floors cannot crop inward mound silhouettes differently at midpoint.
