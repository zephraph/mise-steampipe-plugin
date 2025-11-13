-- hooks/backend_list_versions.lua
-- Lists available versions for a Steampipe plugin
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions

function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool

    -- Validate tool name
    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    local http = require("http")
    local json = require("json")

    -- Steampipe plugins are open source and hosted on GitHub under the turbot organization
    -- Plugin naming convention: steampipe-plugin-{name}
    -- Repository: https://github.com/turbot/steampipe-plugin-{name}

    -- Parse tool name to extract org and plugin name
    -- Supports formats:
    --   - "aws" -> "turbot/steampipe-plugin-aws"
    --   - "turbot/aws" -> "turbot/steampipe-plugin-aws"
    --   - "someorg/plugin-name" -> "someorg/steampipe-plugin-plugin-name"
    local org = "turbot" -- default organization
    local plugin_name = tool

    if tool:match("/") then
        org, plugin_name = tool:match("^([^/]+)/(.+)$")
    end

    -- Construct the repository name
    local repo_name = "steampipe-plugin-" .. plugin_name

    -- Use GitHub API to list tags (which correspond to releases)
    local api_url = "https://api.github.com/repos/" .. org .. "/" .. repo_name .. "/tags"

    local resp, err = http.get({
        url = api_url,
        headers = {
            -- GitHub API recommends setting User-Agent
            ["User-Agent"] = "mise-steampipe-plugin",
            -- Use Accept header for API versioning
            ["Accept"] = "application/vnd.github.v3+json"
        }
    })

    if err then
        error("Failed to fetch versions for " .. tool .. ": " .. err)
    end

    if resp.status_code == 404 then
        error("Plugin '" ..
        tool .. "' not found. Make sure the repository exists at https://github.com/" .. org .. "/" .. repo_name)
    end

    if resp.status_code == 403 then
        error("GitHub API rate limit exceeded. Please try again later or set GITHUB_TOKEN environment variable.")
    end

    if resp.status_code ~= 200 then
        error("GitHub API returned status " .. resp.status_code .. " for " .. tool)
    end

    local data = json.decode(resp.body)
    local versions = {}

    -- Parse versions from GitHub tags
    if type(data) == "table" then
        for _, tag_info in ipairs(data) do
            if tag_info.name then
                local version = tag_info.name
                -- Remove 'v' prefix if present (e.g., v1.0.0 -> 1.0.0)
                version = version:gsub("^v", "")

                -- Only include tags that look like semantic versions
                -- This filters out non-version tags
                if version:match("^%d+%.%d+%.%d+") then
                    table.insert(versions, version)
                end
            end
        end
    end

    if #versions == 0 then
        error("No semantic versions found for " .. tool .. " at https://github.com/" .. org .. "/" .. repo_name)
    end

    return { versions = versions }
end
