-- hooks/backend_install.lua
-- Installs a specific version of a Steampipe plugin
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall

function PLUGIN:BackendInstall(ctx)
    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    -- Validate inputs
    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end
    if not version or version == "" then
        error("Version cannot be empty")
    end

    -- Default install path to CWD/.steampipe if not provided
    if not install_path or install_path == "" then
        local cwd = os.getenv("PWD") or "."
        install_path = cwd .. "/.steampipe"
    end

    local cmd = require("cmd")

    -- Find steampipe binary
    -- First try to use mise to locate steampipe
    local steampipe_path = "steampipe" -- fallback to PATH
    local which_result = cmd.exec(
        "command -v steampipe 2>/dev/null || mise where steampipe 2>/dev/null | xargs -I {} echo {}/bin/steampipe"
    )

    if which_result and which_result ~= "" and not which_result:match("not found") then
        steampipe_path = which_result:gsub("%s+$", "") -- trim whitespace
    end

    -- Construct the plugin identifier with version
    -- Steampipe format: [registry/org/]name[@version]
    -- The tool name from mise will be just the plugin name (e.g., "aws")
    -- We want to install it as: aws@version
    local plugin_spec = tool .. "@" .. version

    -- Build the install command with --install-dir flag
    -- Using --skip-config to avoid creating default config files
    local install_cmd = steampipe_path
        .. " plugin install --install-dir "
        .. install_path
        .. " --skip-config "
        .. plugin_spec

    local result = cmd.exec(install_cmd)

    -- Check for errors in the output
    if result:match("[Ee]rror") or result:match("[Ff]ailed") then
        error("Failed to install " .. tool .. "@" .. version .. ": " .. result)
    end

    -- Verify installation succeeded
    if not result:match("Installed") and not result:match("installed") then
        error("Installation may have failed for " .. tool .. "@" .. version .. ". Output: " .. result)
    end

    return {}
end
