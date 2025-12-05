#!/usr/bin/env bash

set -euo pipefail

# Global variable for the temporary directory
tmp_dir=""

# Cleanup function to be called on script exit
cleanup() {
  if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

# Print error message and exit
# Usage: err <message>
err() {
  echo "ERROR:" "$@" >&2
  exit 1
}

# Check for required commands
# Usage: check_deps <cmd1> <cmd2> ...
check_deps() {
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      err "Command not found: '$cmd'. Please install it first."
    fi
  done
}

main() {
  check_deps curl jq tar

  local repo="jesseduffield/lazygit"
  local install_dir="$HOME/.local/bin"

  # Determine architecture
  local arch
  case "$(uname -m)" in
    x86_64)
      arch="x86_64"
      ;;
    aarch64)
      arch="arm64"
      ;;
    *)
      err "Unsupported architecture: $(uname -m)"
      ;;
  esac

  # Get the download URL for the latest Linux release for the detected architecture
  local download_url
  download_url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" |
    jq -r ".assets[] | select(.name | test(\"linux_${arch}\")) | .browser_download_url")

  if [[ -z "$download_url" ]]; then
    err "Could not find a download URL for your architecture ($arch)."
  fi

  # Create a temporary directory for the download
  tmp_dir=$(mktemp -d)

  echo "Downloading lazygit..."
  curl -L -o "$tmp_dir/lazygit.tar.gz" "$download_url"

  # Create installation directory if it doesn't exist
  mkdir -p "$install_dir"

  echo "Installing lazygit to $install_dir..."
  # Extract the binary directly to the installation directory
  tar -xzf "$tmp_dir/lazygit.tar.gz" -C "$install_dir" lazygit

  # Make the binary executable
  chmod +x "$install_dir/lazygit"

  echo "lazygit installed successfully!"
  echo "You can now run 'lazygit' from your terminal."
}

# Run the main function
main "$@"
