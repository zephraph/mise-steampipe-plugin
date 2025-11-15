-- hooks/backend_exec_env.lua
-- Sets up environment variables for a Steampipe plugin
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv

function PLUGIN:BackendExecEnv(ctx)
    local install_path = ctx.install_path
    local tool = ctx.tool
    local version = ctx.version

    local env_vars = {}

    -- Set STEAMPIPE_INSTALL_DIR to point to the plugin installation directory
    -- This tells Steampipe where to find the installed plugins
    if install_path and install_path ~= "" then
        table.insert(env_vars, {
            key = "STEAMPIPE_INSTALL_DIR",
            value = install_path,
        })
    end

    -- Note: Steampipe plugins are not executable binaries themselves.
    -- They are loaded by the main steampipe CLI when it runs.
    -- Users should use: mise x steampipe -- steampipe query "..."
    -- The STEAMPIPE_INSTALL_DIR environment variable tells steampipe
    -- where to find the installed plugins.

    return {
        env_vars = env_vars,
    }
end
