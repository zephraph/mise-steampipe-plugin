-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    -- Required: Plugin name (will be the backend name users reference)
    name = "steampipe-plugin",

    -- Required: Plugin version (not the tool versions)
    version = "1.0.0",

    -- Required: Brief description of the backend and tools it manages
    description = "A mise backend plugin for steampipe plugins",

    -- Required: Plugin author/maintainer
    author = "zephraph",

    -- Optional: Plugin homepage/repository URL
    homepage = "https://github.com/zephraph/mise-steampipe-plugin",

    -- Optional: Plugin license
    license = "MIT",

    -- Optional: Important notes for users
    notes = {
        "Requires steampipe to be installed on your system",
        -- "This plugin manages tools from the steampipe-plugin ecosystem"
    },
}
