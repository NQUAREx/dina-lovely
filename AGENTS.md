# Repository content safety

- `content/letters*.json` is maintained on GitHub. Before content work run `python3 tools/sync_letters.py`; cloud values take priority.
- Keep these files tracked and published. Never remove them from Git because they appear in `.gitignore`.
- Run `python3 tools/sync_letters.py --setup` after checkout to enable hooks and local `skip-worktree` protection.
- Do not commit local text edits. For an explicitly requested schema addition, use `--add-missing-ui`, preserve every existing cloud value, and set `GARDEN_CONTENT_SCHEMA_UPDATE=1` only for that reviewed commit/push.
- Runtime UI copy belongs in both JSON variants. Keep their comments; run `python3 tests/content_schema.py` after schema changes.
