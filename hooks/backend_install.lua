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

    local cmd = require("cmd")

    -- Find steampipe binary
    -- Try multiple strategies to locate steampipe
    local steampipe_path = nil

    -- Strategy 1: Check if it's in PATH
    local path_result = cmd.exec("command -v steampipe 2>/dev/null || true")
    if path_result and path_result ~= "" and not path_result:match("not found") then
        steampipe_path = path_result:gsub("%s+$", "")
    end

    -- Strategy 2: Try to find via mise (ubi:turbot/steampipe or other variants)
    if not steampipe_path then
        local variants = {
            "ubi:turbot/steampipe",
            "steampipe"
        }

        for _, variant in ipairs(variants) do
            local mise_result = cmd.exec("mise where " .. variant .. " 2>/dev/null || true")
            if mise_result and mise_result ~= "" and not mise_result:match("not found") then
                local install_dir = mise_result:gsub("%s+$", "")
                -- Try both /bin/steampipe and /steampipe (ubi installs to root, others might use bin/)
                local candidates = {
                    install_dir .. "/steampipe",
                    install_dir .. "/bin/steampipe"
                }

                for _, candidate in ipairs(candidates) do
                    local test_result = cmd.exec("test -f " .. candidate .. " && echo found || true")
                    if test_result:match("found") then
                        steampipe_path = candidate
                        break
                    end
                end

                if steampipe_path then
                    break
                end
            end
        end
    end

    -- Fallback: use "steampipe" and hope it's in PATH
    if not steampipe_path then
        steampipe_path = "steampipe"
    end

    -- Construct the plugin identifier with version
    -- Steampipe format: [registry/org/]name[@version]
    -- The tool name from mise will be just the plugin name (e.g., "aws")
    -- We want to install it as: aws@version
    local plugin_spec = tool .. "@" .. version

    -- Build the install command
    -- If STEAMPIPE_INSTALL_DIR is set, pass it through with --install-dir
    -- Otherwise, let steampipe use its default location (~/.steampipe)
    local install_cmd = steampipe_path .. " plugin install --skip-config"

    local steampipe_install_dir = os.getenv("STEAMPIPE_INSTALL_DIR")
    if steampipe_install_dir and steampipe_install_dir ~= "" then
        install_cmd = install_cmd .. " --install-dir " .. steampipe_install_dir
    end

    install_cmd = install_cmd .. " " .. plugin_spec

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
