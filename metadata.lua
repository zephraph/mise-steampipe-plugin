-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    -- Required: Plugin name
    name = "steampipe-plugin",
    -- Required: Plugin version (not the tool versions)
    version = "1.0.0",
    -- Required: Brief description
    description = "A mise backend plugin for managing steampipe plugins",
    -- Required: Plugin author/maintainer
    author = "zephraph",
    -- Optional: Plugin homepage/repository URL
    homepage = "https://github.com/zephraph/mise-steampipe",
    -- Optional: Plugin license
    license = "MIT",
    -- Optional: Important notes for users
    notes = {
        "Manages steampipe plugins using the steampipe:plugin-name format",
        "Install steampipe CLI separately: mise use -g ubi:turbot/steampipe",
        "Plugins install to ~/.steampipe by default",
        "Set STEAMPIPE_INSTALL_DIR to customize installation location",
    },
}
