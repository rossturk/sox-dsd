# Claude.md - Flox Environment Creation Guide

This document provides guidance for creating and working with Flox environments.

## User Context & Preferences

### Working Style
- **Modular, self-sufficient bash functions** in hook scripts
- Each function should handle a specific aspect of setup
- Functions should be **idempotent** - safe to run multiple times
- Consider using **gum** for styled output and user feedback in environments designed for interactive use
- Provide **clear, informative logging** with success/failure indicators
- **Function naming for composability**: Use descriptive, unique function names

### Directory Structure Preferences
- Use `$FLOX_ENV_CACHE` for persistent data, configurations, and downloads
- Use `$FLOX_ENV_PROJECT` to return to the project directory at end of hooks
- Create organized subdirectories within cache: `config/`, `data/`, `plugins/`, `logs/`, `samples/`
- Use `mktemp` for temporary files during setup operations and clean them up immediately

### Configuration Management
- **Runtime configurability** is essential - support environment variable overrides
- Allow `VARIABLE=value flox activate -s` to override defaults
- Environment variables should follow consistent naming patterns
- Document all configurable variables clearly

### Secrets & Authentication Management
- **Never store secrets in the manifest** - they would be visible in version control
- **Offer persistent storage in user's home**: `~/.config/<env_name>` or `~/.config/<package_name>`
- **Always provide options**: Let users choose between:
  - Environment variable injection at runtime
  - Persistent storage in home directory
  - Manual configuration after activation
- **Check for existing configs**: Reuse standard tool configurations when available

## Flox Environment Structure

### Key Paths & Files
- `$FLOX_ENV_PROJECT/.flox/env/manifest.toml` - The main environment manifest file
- `$FLOX_ENV_PROJECT/.flox/env.json` - Required environment metadata file
- `$FLOX_ENV_CACHE` - Persistent storage for the environment
- `$FLOX_ENV_PROJECT` - Project root directory

**CRITICAL**: Always use `flox init` to properly initialize an environment with both `env.json` and the manifest structure.

### Environment Variables Set by Flox
- **$FLOX_ENV**: Path to the built environment (merged bin, lib, etc directories)
- **$FLOX_ENV_CACHE**: Directory for transient files that persist locally but aren't pushed
- **$FLOX_ENV_PROJECT**: Project directory (containing .flox/ for local, or CWD for remote)
- **$FLOX_ENV_DESCRIPTION**: Project name for identification
- **$FLOX_PROMPT_ENVIRONMENTS**: Space-delimited list of active environments
- **$FLOX_ACTIVATE_START_SERVICES**: "true" if activation started services, "false" otherwise

## Working with Flox

### Package Management

#### Essential Commands
```bash
flox init                                # Initialize a new environment
flox search <term>                       # Search for packages in the Flox Catalog
flox show <pkg-name>                     # Show available versions of a package
flox list                                # See all installed packages
flox list -c                             # See config details and manifest
flox install <package>                   # Add package imperatively
flox edit                                # Edit manifest directly (interactive)
flox activate                            # Enter the environment
flox activate -s                         # Activate with services started
flox activate -- <command>               # Run command in environment without entering
flox activate -m dev|run                 # Override activation mode
flox services status                     # Check service status
flox services logs                       # View service logs
flox services logs --follow              # Tail service logs
flox services start/stop/restart [name]  # Control specific services
```

#### Working with Existing Environments
When encountering a `.flox/` directory in a project:
1. Check what's installed with `flox list`
2. Review the manifest with `flox list -c` or `cat .flox/env/manifest.toml`
3. Activate with `flox activate` or run commands with `flox activate -- <cmd>`
4. Check for services before installing packages that might already be available

#### Non-Interactive Manifest Editing

Since Claude Code can't use interactive `flox edit`, use these approaches:

##### Method 1: Edit Via Temporary File
```bash
# Get current manifest
flox list -c > /tmp/manifest.toml

# Modify the file (sed, awk, or direct editing)
sed -i '/\[install\]/a new-package.pkg-path = "new-package"' /tmp/manifest.toml

# Apply changes
flox edit -f /tmp/manifest.toml

# Clean up
rm /tmp/manifest.toml
```

##### Method 2: Pipe Editing
```bash
# One-line edit with sed
flox list -c | sed '/\[install\]/a tool.pkg-path = "tool"' | flox edit -f -

# Complex edits with awk
flox list -c | awk '/\[vars\]/{print; print "NEW_VAR = \"value\""; next}1' | flox edit -f -

# Add multiple packages
flox list -c | sed -e '/\[install\]/a cmake.pkg-path = "cmake"' \
                  -e '/\[install\]/a ninja.pkg-path = "ninja"' | flox edit -f -
```

## Manifest Structure

### [install] Section
```toml
# Basic package installation
curl.pkg-path = "curl"
jq.pkg-path = "jq"

# Package groups (for dependency isolation)
gnused.pkg-path = "gnused"
gnused.pkg-group = "darwin-tools"

# System-specific packages
openssh.pkg-path = "openssh"
openssh.systems = ["x86_64-darwin", "aarch64-darwin"]
ollama-cuda.pkg-path = "ollama-cuda"
ollama-cuda.systems = ["x86_64-linux", "aarch64-linux"]
```

#### Package Features
- **pkg-path**: The nixpkgs package name
- **pkg-group**: Isolates packages with conflicting dependencies
- **systems**: Constrains packages to specific platforms

### [vars] Section
- Use **only for invariant variables** that users generally won't change
- If users need to change these, they edit the manifest manually
- **Do NOT use for runtime-configurable variables**
- **Do NOT use variable references** - TOML doesn't support variable expansion

### [hook] Section
```bash
on-activate = '''
# CRITICAL: Never use 'exit' in hooks - it terminates the flox subshell!
# Use 'return' instead to exit from functions while keeping the environment active

# Set all environment variables with defaults first
export VAR1="${VAR1:-default}"
export VAR2="${VAR2:-default}"

# Helper functions (for use within the hook only)
function_name() {
    # Use 'return' not 'exit' for error handling
    if [ ! -f "required_file" ]; then
        echo "Error: Required file not found"
        return 1  # NOT exit 1
    fi
}

# Main installation/setup functions
install_component() {
    # Component-specific setup
}

# Main orchestration function
main_function() {
    # Call setup functions in order
    # Display summary information
    # Return to project directory
    cd $FLOX_ENV_PROJECT
}

# Execute main function
main_function
'''
```

### [services] Section
```toml
# Simple command service
postgres.command = "postgres -D $PGDATA -p $PGPORT"

# Complex script service with conditional logic
spark.command = '''
mkdir -p "$SPARK_LOG_DIR"
if [ "$SPARK_MODE" = "master" ]; then
    ./sbin/start-master.sh
elif [ "$SPARK_MODE" = "worker" ]; then
    ./sbin/start-worker.sh "$SPARK_MASTER_URL"
fi
# For services that spawn daemons and exit, use tail to keep the service "running"
tail -f /dev/null
'''

# Daemon service with custom shutdown
myapp.command = "./start-daemon.sh"
myapp.is-daemon = true
myapp.shutdown.command = "./stop-daemon.sh"
```

### [profile] Section
```toml
[profile]
common = '''
# Shell-agnostic environment setup
# Note: This runs in each shell's native syntax, so keep it simple
# Avoid shell-specific syntax here
'''

bash = '''
# Bash-specific functions and aliases
alias ll='ls -la'
function bash_function() {
    echo "bash implementation"
}
export BASH_VAR="bash-specific"
'''

zsh = '''
# Zsh-specific functions and aliases  
alias ll='ls -la'
function zsh_function() {
    echo "zsh implementation"
}
export ZSH_VAR="zsh-specific"
'''
```

### [options] Section
```toml
[options]
# Activation mode: "dev" includes development dependencies, "run" excludes them
activate.mode = "dev"  # or "run"

# Systems supported by this environment
systems = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]

# License allowlist
allow.licenses = ["mit", "apache-2.0", "gpl-3.0"]
```

## Advanced Flox Features

### Environment Layering
- **Layering**: Activating multiple environments in sequence, creating a stack
- **Runtime operation**: Stacking Flox subshells, each inheriting from those beneath
- **Override behavior**: Later activated environments take precedence for conflicts
- **When to use**: Ad hoc requirements, workflow flexibility, separation of concerns

Example layering workflow:
```bash
# Base workflow - activate environments as needed
flox activate -r platform-team/postgres      # Database service
flox activate -r frontend-team/python-dbms   # Python tools
flox activate -r my-handle/ollama            # LLM for SQL generation

# Or create an alias for repeatable layering
alias mystack='flox activate -r platform-team/postgres -- \
               flox activate -r frontend-team/python-dbms -- \
               flox activate -r my-handle/ollama'
```

### Environment Composition
- **Composition**: Declaratively merge environments at build time via `[include]` section
- **Build-time operation**: Dependencies resolved when creating the composed environment
- **When to use**: Repeatable stacks, unified toolchains, CI/CD environments

Include syntax:
```toml
[include]
environments = [
  # Local environment by path
  { dir = "../myenv" },
  # Local with custom name
  { dir = "../other_env", name = "other" },
  # Remote from FloxHub
  { remote = "myuser/myenv" },
]
```

#### Implementation Constraints (Claude Code)
- **Local includes**: Only use `dir` paths within or below current working directory
- **Remote includes**: Ask user for FloxHub handle and environment names if unknown
- **Path strategy**: Create multiple composable environments as subdirectories of the main project

### Build System
The `[build]` section enables reproducible builds using Nix's deterministic build system:

```toml
[install]
# Build dependencies
gcc.pkg-path = "gcc"
cmake.pkg-path = "cmake"

[build]
myapp.command = '''
# IMPORTANT: $out is a special variable provided by Nix/Flox
# - You do NOT define it yourself
# - It points to a location in the Nix store
# - All build outputs MUST go to $out
# - Note: $FLOX_ENV_CACHE and $FLOX_ENV_PROJECT are NOT available in [build]

mkdir -p $out/bin $out/lib

# Standard build process
cmake -B build -DCMAKE_INSTALL_PREFIX=$out
cmake --build build -j$(nproc)
cmake --install build
'''
```

Using builds:
```bash
# Build a target
flox build myapp

# Results appear in ./result-myapp
ls ./result-myapp/bin/

# When working with users, always ask for their preference on artifact location:
# - Copy to project directory: cp -r ./result-myapp/* ./my-project/
# - Copy to home directory: cp -r ./result-myapp/* $HOME/dev/sources/
# - Copy to XDG directories: cp -r ./result-myapp/* $XDG_DATA_HOME/my-app/
```

### Containerization
Flox environments can be exported as container images:

```bash
# Export to file
flox containerize -f ./mycontainer.tar
docker load -i ./mycontainer.tar

# Load directly into runtime
flox containerize --runtime docker

# Configure container behavior
[containerize.config]
user = "appuser:appgroup"
exposed-ports = ["8080/tcp"]
cmd = ["./start.sh"]
```

## Best Practices & Common Pitfalls

### Error Handling
- Use `set -e` carefully - prefer explicit error checking
- Provide informative error messages with suggested solutions
- Use gum for styled output: success (✓), error (✗), info (ℹ)
- Show progress for long-running operations

### Environment Variable Conventions
- `COMPONENT_HOST` and `COMPONENT_PORT` for service connections
- `ENABLE_COMPONENT_NAME` for optional component flags
- `COMPONENT_VERSION` for version overrides
- `COMPONENT_DIR` for directory customization
- `DEBUG` and `VERBOSE` for troubleshooting

### Common Anti-Patterns to Avoid
- Never use `exit` in hooks - it terminates the flox subshell (use `return` instead)
- Don't put service properties outside the command block
- Don't use variable references in `[vars]` - TOML doesn't support variable expansion
- Don't fail silently - always provide status feedback
- Avoid requiring manual configuration steps after activation
- Ensure environments can be re-activated safely and idempotently

### Function Naming Strategy for Composition
When creating environments intended for composition:
- Use descriptive, prefixed function names: `setup_postgres_data()`, `install_python_tools()`
- Avoid generic names like `setup()`, `install()`, `configure()` as these will collide
- Example pattern:
  ```bash
  # In postgres-env
  setup_postgres_data() { ... }
  configure_postgres_auth() { ... }
  
  # In python-env  
  setup_python_venv() { ... }
  install_python_packages() { ... }
  
  # In composing environment
  main() {
      setup_postgres_data
      setup_python_venv
  }
  ```

---

This guide serves as a reference for creating and working with Flox environments efficiently.
