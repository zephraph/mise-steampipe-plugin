# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a mise backend plugin for managing Steampipe plugins. Unlike standard mise tool plugins that manage a single tool, backend plugins manage **multiple tools** using the `plugin:tool` format (e.g., `steampipe-plugin:aws`, `steampipe-plugin:github`).

Steampipe plugins are database extensions (not standalone executables) that provide SQL interfaces to cloud APIs and services. They are distributed as OCI images from hub.steampipe.io and developed under the turbot organization on GitHub.

## Architecture

### Backend Plugin System

The plugin implements three core hooks required by mise's vfox-style backend architecture:

1. **`hooks/backend_list_versions.lua`**: Queries GitHub API for releases from `turbot/steampipe-plugin-{name}` repositories. Strips 'v' prefix and filters for semantic versions only.

2. **`hooks/backend_install.lua`**: 
   - Locates the steampipe binary via `mise where steampipe` (since it's not in PATH during install)
   - Executes `steampipe plugin install <tool>@<version> --install-dir <path> --skip-config`
   - Defaults install path to `CWD/.steampipe` for project-local installations
   - The `--install-dir` flag is a global steampipe flag (not a subcommand flag)

3. **`hooks/backend_exec_env.lua`**: Sets `STEAMPIPE_INSTALL_DIR` environment variable to tell steampipe where to find installed plugins.

### Key Implementation Details

- **Plugin naming**: Tool name `aws` maps to GitHub repo `turbot/steampipe-plugin-aws`
- **Version source**: GitHub releases API, not OCI registry (OCI registry queries are complex and slow)
- **Installation timeout**: Default 10s may be too short; installations can take 30-60s to download OCI images
- **No binary execution**: Steampipe plugins don't provide executables; users run `mise x steampipe-plugin:aws -- steampipe query "..."`
- **Environment variables**: The plugin only needs to set `STEAMPIPE_INSTALL_DIR`; steampipe handles the rest

## Development Commands

All commands require `MISE_EXPERIMENTAL=1` or `mise settings experimental=true` since backend plugins are experimental.

### Testing
```bash
mise run test          # Run integration tests (links plugin, tests list/install/env)
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
mise plugin link --force steampipe-plugin .           # Link local plugin
mise ls-remote steampipe-plugin:aws                   # Test version listing
mise install steampipe-plugin:github@1.7.0            # Test installation
mise where steampipe-plugin:github@1.7.0              # Check install path
mise x steampipe-plugin:github@1.7.0 -- sh -c 'echo $STEAMPIPE_INSTALL_DIR'  # Verify env
```

### Pre-commit hooks
```bash
lefthook install       # Install git hooks (runs luacheck, stylua, actionlint on commit)
```

## Important Constraints

### Steampipe Binary Availability
During the install hook, steampipe is not in PATH. The implementation uses:
```lua
cmd.exec("command -v steampipe 2>/dev/null || mise where steampipe 2>/dev/null | xargs -I {} echo {}/bin/steampipe")
```
This falls back to locating steampipe via mise if it's not in PATH.

### Plugin Installation Behavior
Steampipe's `--install-dir` flag creates a full steampipe directory structure (config/, plugins/, internal/, logs/) at the specified path. The actual plugin files go into `<install-dir>/plugins/`.

### Test Expectations
The test suite (`mise-tasks/test`) verifies:
1. Version listing returns semantic versions
2. Installation succeeds and creates `<install-path>/plugins/` directory
3. `STEAMPIPE_INSTALL_DIR` is set correctly via `BackendExecEnv`

Tests use `steampipe-plugin:github@1.7.0` as the test plugin.

## Lua Modules Available

Backend hooks have access to:
- `cmd` - Execute shell commands via `cmd.exec()`
- `http` - HTTP client with `http.get()` and `http.download()`
- `json` - JSON parsing with `json.decode()` and `json.encode()`
- `file` - File operations (though not heavily used in this plugin)

Runtime info available via `RUNTIME.osType`, `RUNTIME.archType`.

## Common Modifications

### Adding support for non-turbot plugins
Currently hardcoded to `turbot` org. To support other orgs, modify `backend_list_versions.lua` and `backend_install.lua` to parse org from tool name (e.g., `someorg/aws` format).

### Adjusting timeout handling
If installations timeout, the issue is in mise's default 10s timeout for hook execution, not in the Lua code. This is a mise limitation.

### Changing default install location
Modify the install path default in `backend_install.lua`:
```lua
if not install_path or install_path == "" then
    local cwd = os.getenv("PWD") or "."
    install_path = cwd .. "/.steampipe"  -- Change this
end
```
