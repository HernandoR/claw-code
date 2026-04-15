# Claw Code – project-level justfile
# https://github.com/casey/just

set dotenv-load := false
set positional-arguments := true

# Default recipe: list all available recipes
default:
    @just --list

# ---------------------------------------------------------------------------
# Environment setup
# ---------------------------------------------------------------------------

# Install / verify the full development toolchain (cargo + uv)
setup:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Checking for cargo …"
    if ! command -v cargo &>/dev/null; then
        echo "    cargo not found – installing Rust via rustup …"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    fi
    echo "    $(cargo --version)"

    echo "==> Ensuring rustfmt and clippy components …"
    rustup component add rustfmt clippy

    echo "==> Checking for uv …"
    if ! command -v uv &>/dev/null; then
        echo "    uv not found – installing via cargo …"
        cargo install --locked uv
    fi
    echo "    uv $(uv --version)"

    echo "==> Environment is ready."

# ---------------------------------------------------------------------------
# Rust workspace helpers  (run from the rust/ subdirectory)
# ---------------------------------------------------------------------------

# Format the Rust workspace
fmt:
    cd rust && cargo fmt --all

# Check formatting without modifying files
fmt-check:
    cd rust && cargo fmt --all --check

# Run clippy on the workspace
clippy:
    cd rust && cargo clippy --workspace --all-targets -- -D warnings

# Run the full test suite
test:
    cd rust && cargo test --workspace

# Build the release CLI binary (claw)
build-release:
    cd rust && cargo build --release -p rusty-claude-cli

# Build debug CLI binary
build:
    cd rust && cargo build -p rusty-claude-cli

# Run all quality checks (fmt, clippy, test)
check: fmt-check clippy test

# Build release and print the binary path
release: build-release
    @echo "Release binary: rust/target/release/claw"

# ---------------------------------------------------------------------------
# CI convenience recipe – called from GitHub Actions
# ---------------------------------------------------------------------------

# Full CI pipeline: setup, quality checks, and release build
ci: setup check build-release
