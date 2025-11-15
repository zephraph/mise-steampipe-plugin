# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a mise backend plugin for managing Steampipe plugins. Steampipe plugins are database extensions (not standalone executables) that provide SQL interfaces to cloud APIs and services.

**Installation location**: Plugins are installed to steampipe's default location (`~/.steampipe`) unless the user sets `STEAMPIPE_INSTALL_DIR` environment variable.

Users interact with it as:
- `mise use steampipe-plugin:aws@1.26.0` - Install AWS plugin
- `mise use steampipe-plugin:github@1.7.0` - Install GitHub plugin

Steampipe CLI is installed separately (recommended: `mise use -g ubi:turbot/steampipe`).

## Architecture

### Backend Plugin System

The plugin implements three backend hooks:

1. **`hooks/backend_list_versions.lua`**: Queries GitHub API for releases from `turbot/steampipe-plugin-{name}` repositories. Strips 'v' prefix and filters for semantic versions only.

2. **`hooks/backend_install.lua`**: 
   - Locates steampipe binary via multiple strategies (PATH, mise where ubi:turbot/steampipe, mise where steampipe)
   - Checks both `{install_dir}/steampipe` and `{install_dir}/bin/steampipe` for the binary
   - Executes `steampipe plugin install --skip-config <tool>@<version>`
   - If `STEAMPIPE_INSTALL_DIR` env var is set, adds `--install-dir $STEAMPIPE_INSTALL_DIR`
   - Otherwise lets steampipe use its default location (~/.steampipe)

3. **`hooks/backend_exec_env.lua`**: 
   - Returns empty env_vars array
   - Does NOT set STEAMPIPE_INSTALL_DIR - respects whatever the user has set or steampipe's default

### Key Implementation Details

- **Installation location**: Uses steampipe's default `~/.steampipe` unless user sets `STEAMPIPE_INSTALL_DIR`
- **Plugin naming**: Tool name `aws` maps to GitHub repo `turbot/steampipe-plugin-aws`
- **Version source**: GitHub releases API (not OCI registry - too complex/slow)
- **Installation timeout**: Default 10s may be too short; installations can take 30-60s to download OCI images
- **No binary execution**: Steampipe plugins don't provide executables; users run `steampipe query "..."`
- **Binary detection**: Handles both ubi-style installations (binary at root) and traditional (binary in bin/)

## Development Commands

All commands require `MISE_EXPERIMENTAL=1` or `mise settings experimental=true` since backend plugins are experimental.

### Testing
```bash
mise run test          # Run integration tests
mise run lint          # Run all linters (luacheck, stylua check, actionlint)
mise run ci            # Run lint + test (same as CI)
```

### Formatting
```bash
mise run format        # Format Lua files with stylua
mise run fix           # Run luacheck and stylua auto-fix
```

### Manual testing during development
```bash
mise plugin link --force steampipe-plugin .               # Link local plugin
mise ls-remote steampipe-plugin:aws                       # Test version listing
mise install steampipe-plugin:github@1.7.0                # Test installation
ls -la ~/.steampipe/plugins                               # Verify install location
```

### Pre-commit hooks
```bash
lefthook install       # Install git hooks (runs luacheck, stylua, actionlint on commit)
```

## Important Constraints

### Respecting STEAMPIPE_INSTALL_DIR
The plugin checks for `STEAMPIPE_INSTALL_DIR` environment variable and passes it through to steampipe if set. Otherwise, steampipe uses its default `~/.steampipe` location. The plugin does NOT force a specific location.

### Steampipe Binary Detection
The implementation tries multiple strategies to find the steampipe binary:
1. Check PATH with `command -v steampipe`
2. Try `mise where ubi:turbot/steampipe` (for ubi installations)
3. Try `mise where steampipe` (for other mise installations)
4. For each mise location, check both `/steampipe` (ubi style) and `/bin/steampipe` (traditional)
5. Fallback to just `steampipe` command

### Plugin Installation Behavior
Steampipe's `plugin install` command creates a directory structure at the install location:
- `{install-dir}/config/`
- `{install-dir}/plugins/` - actual plugin files
- `{install-dir}/internal/`
- `{install-dir}/logs/`

### Test Expectations
The test suite (`mise-tasks/test`) verifies:
1. Version listing returns semantic versions
2. Installation succeeds
3. Plugins directory exists at `${STEAMPIPE_INSTALL_DIR:-$HOME/.steampipe}/plugins`

Tests use `steampipe-plugin:github@1.7.0` as the test plugin.

## Lua Modules Available

Backend hooks have access to:
- `cmd` - Execute shell commands via `cmd.exec()`
- `http` - HTTP client with `http.get()` and `http.download()`
- `json` - JSON parsing with `json.decode()` and `json.encode()`
- `file` - File operations (though not heavily used)

Runtime info available via `RUNTIME.osType`, `RUNTIME.archType`.

## Common Modifications

### Adding support for non-turbot plugins
Currently hardcoded to `turbot` org. To support other orgs, modify `backend_list_versions.lua` and `backend_install.lua` to parse org from tool name (e.g., `someorg/aws` format).

### Supporting different steampipe binary locations
Update the `variants` array and `candidates` array in `backend_install.lua` to check additional locations.

### Adjusting timeout handling
If installations timeout, the issue is in mise's default 10s timeout for hook execution, not in the Lua code. This is a mise limitation.

## Why Not Set STEAMPIPE_INSTALL_DIR?

The plugin lets steampipe manage its own default location (`~/.steampipe`) and only intervenes if the user explicitly sets `STEAMPIPE_INSTALL_DIR`. This provides:

1. **Simplicity**: Works out of the box with steampipe's defaults
2. **User control**: Users can override by setting env var
3. **Compatibility**: Doesn't interfere with existing steampipe setups
4. **Shared plugins**: All projects can share the same plugin installations unless customized

Users who want project-specific plugins can set `STEAMPIPE_INSTALL_DIR` in their `.mise.toml`:
```toml
[env]
STEAMPIPE_INSTALL_DIR = "./.steampipe"
```
