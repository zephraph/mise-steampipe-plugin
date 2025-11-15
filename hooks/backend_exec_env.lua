-- hooks/backend_exec_env.lua
-- Sets up environment variables for a Steampipe plugin
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv

function PLUGIN:BackendExecEnv(ctx)
    local install_path = ctx.install_path
    local tool = ctx.tool
    local version = ctx.version

    local env_vars = {}

    -- Set STEAMPIPE_INSTALL_DIR    -- Only set STEAMPIPE_INSTALL_DIR if it's not already set
    -- This allows users to override the location if they want
    -- Otherwise, steampipe will use its default ~/.steampipe location
    -- We don't need to set it ourselves - just pass through if already set

    -- Note: Steampipe plugins are not executable binaries themselves.
    -- They are loaded by the main steampipe CLI when it runs.
    -- Users should have steampipe CLI installed and can use:
    --   steampipe query "..."
    -- Or with mise:
    --   mise x steampipe:plugin-name -- steampipe query "..."

    return {
        env_vars = env_vars,
    }
end
