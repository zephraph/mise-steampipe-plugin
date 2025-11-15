# mise-steampipe-plugin

A [mise](https://mise.jdx.dev) backend plugin for managing [Steampipe](https://steampipe.io) plugins.

## What is Steampipe?

Steampipe is an open-source tool that lets you query cloud APIs, services, and more using SQL. It uses plugins to provide database-like interfaces to various APIs and services including AWS, Azure, GCP, GitHub, Kubernetes, and many more.

## What does this plugin do?

This mise backend plugin allows you to install and manage Steampipe plugins using mise's tool management system. Since Steampipe has 150+ plugins, this backend lets you manage them individually:

- `steampipe-plugin:aws` - AWS plugin
- `steampipe-plugin:github` - GitHub plugin  
- `steampipe-plugin:kubernetes` - Kubernetes plugin
- And many more!

## Prerequisites

- [mise](https://mise.jdx.dev) installed
- [Steampipe](https://steampipe.io) installed (managed via mise or system-wide)

## Installation

### Enable experimental features

Backend plugins require mise experimental features:

```bash
mise settings experimental=true
```

### Install the plugin

```bash
mise plugin install steampipe-plugin https://github.com/zephraph/mise-steampipe-plugin
```

## Usage

### List available versions

```bash
mise ls-remote steampipe-plugin:aws
mise ls-remote steampipe-plugin:github
```

### Install a plugin

```bash
# Install latest version
mise install steampipe-plugin:aws@latest

# Install specific version
mise install steampipe-plugin:github@1.7.0

# Install to .mise.toml
mise use steampipe-plugin:aws@1.26.0
```

### Use with Steampipe

Steampipe plugins are database extensions, not standalone executables. Use them with the Steampipe CLI:

```bash
# The STEAMPIPE_INSTALL_DIR environment variable is automatically set
mise exec steampipe-plugin:github@1.7.0 -- steampipe query "select * from github_repository limit 5"

# Or use mise x for short
mise x steampipe-plugin:github@1.7.0 -- steampipe query "select name, stargazers_count from github_repository"
```

### Install multiple plugins

Create a `.mise.toml` file in your project:

```toml
[tools]
"steampipe-plugin:aws" = "1.26.0"
"steampipe-plugin:github" = "1.7.0"
"steampipe-plugin:kubernetes" = "0.30.0"
steampipe = "2.3.2"
```

Then install all at once:

```bash
mise install
```

### Project-local plugin installation

By default, plugins install to `.steampipe` in the current directory when using mise. This allows different projects to have different plugin versions:

```bash
cd my-aws-project
mise use steampipe-plugin:aws@1.26.0
# Plugins installed to my-aws-project/.steampipe/

cd ../my-other-project  
mise use steampipe-plugin:aws@1.25.0
# Plugins installed to my-other-project/.steampipe/
```

## How it works

This backend plugin:

1. **Lists versions** by querying the GitHub API for releases from `turbot/steampipe-plugin-{name}` repositories
2. **Installs plugins** using `steampipe plugin install` with a custom `--install-dir` 
3. **Sets environment** by configuring `STEAMPIPE_INSTALL_DIR` to point to the installation directory

Steampipe plugins are distributed as OCI (Open Container Initiative) images from [hub.steampipe.io](https://hub.steampipe.io) and developed under the [turbot](https://github.com/turbot) organization on GitHub.

## Supported Plugins

All official Steampipe plugins are supported. See the complete list at [hub.steampipe.io](https://hub.steampipe.io/plugins).

Common plugins include:
- `aws` - Amazon Web Services
- `azure` - Microsoft Azure
- `gcp` - Google Cloud Platform
- `github` - GitHub
- `kubernetes` - Kubernetes
- `slack` - Slack
- `terraform` - Terraform
- And 140+ more!

## Plugin naming

Plugins use the format `steampipe-plugin:<name>` where `<name>` is the plugin name from [hub.steampipe.io](https://hub.steampipe.io/plugins).

The backend automatically handles the GitHub repository naming convention (`turbot/steampipe-plugin-{name}`).

## Development

### Local testing

1. Clone this repository
2. Link the plugin for development:
   ```bash
   mise plugin link --force steampipe-plugin .
   ```

3. Test version listing:
   ```bash
   mise ls-remote steampipe-plugin:aws
   ```

4. Test installation:
   ```bash
   mise install steampipe-plugin:github@1.7.0
   ```

### Run tests

```bash
mise run test
```

### Run linters

```bash
mise run lint
```

### Run full CI suite

```bash
mise run ci
```

## Files

- `metadata.lua` - Plugin metadata and configuration
- `hooks/backend_list_versions.lua` - Fetches available versions from GitHub
- `hooks/backend_install.lua` - Installs Steampipe plugins
- `hooks/backend_exec_env.lua` - Sets up STEAMPIPE_INSTALL_DIR environment variable
- `mise-tasks/test` - Integration tests
- `.github/workflows/ci.yml` - CI/CD pipeline

## Troubleshooting

### GitHub API rate limits

The plugin uses the GitHub API to list versions. If you hit rate limits:

```bash
export GITHUB_TOKEN=your_personal_access_token
```

### Steampipe not found

Make sure Steampipe is installed and available:

```bash
# Install via mise
mise use -g steampipe@latest

# Or install via package manager
brew install steampipe  # macOS
```

### Installation timeout

Steampipe plugin installations can take time as they download OCI images. The default timeout should be sufficient, but if you experience issues, check your network connection.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `mise run ci` to ensure tests pass
5. Submit a pull request

## Resources

- [Steampipe Documentation](https://steampipe.io/docs)
- [Steampipe Hub](https://hub.steampipe.io) - Plugin directory
- [mise Documentation](https://mise.jdx.dev)
- [mise Backend Plugin Development](https://mise.jdx.dev/backend-plugin-development.html)

## License

MIT

## Author

zephraph
