#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${GLAB_INSTALL_DIR:-${HOME}/.local/bin}"
REPO="gitlab-org/cli"
API_URL="https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases"

get_latest_version() {
  curl -fsSL "${API_URL}" \
    | grep -oP '"tag_name"\s*:\s*"v?\K[0-9]+\.[0-9]+\.[0-9]+"' \
    | head -1 \
    | tr -d '"'
}

get_installed_version() {
  if command -v glab &>/dev/null; then
    glab --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1
  fi
}

detect_arch() {
  case "$(uname -m)" in
    x86_64)  echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7l)  echo "armv6l" ;;  # best-effort fallback
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

detect_os() {
  case "$(uname -s)" in
    Linux)  echo "linux" ;;
    Darwin) echo "darwin" ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
}

install_glab() {
  local version="$1"
  local os arch tmp_dir archive_name download_url

  os="$(detect_os)"
  arch="$(detect_arch)"
  tmp_dir="$(mktemp -d)"
  archive_name="glab_${version}_${os}_${arch}.tar.gz"
  download_url="https://gitlab.com/${REPO}/-/releases/v${version}/downloads/${archive_name}"

  echo "Downloading glab v${version} (${os}/${arch})..."
  curl -fsSL -o "${tmp_dir}/${archive_name}" "${download_url}"

  echo "Extracting..."
  tar -xzf "${tmp_dir}/${archive_name}" -C "${tmp_dir}"

  echo "Installing to ${INSTALL_DIR}/glab..."
  local bin_path
  bin_path="$(find "${tmp_dir}" -name glab -type f -executable | head -1)"
  if [[ -z "${bin_path}" ]]; then
    # fallback: binary may be at top level in extracted dir
    bin_path="${tmp_dir}/bin/glab"
  fi

  if [[ ! -f "${bin_path}" ]]; then
    echo "Error: could not find glab binary in archive" >&2
    rm -rf "${tmp_dir}"
    exit 1
  fi

  mkdir -p "${INSTALL_DIR}"
  if [[ -w "${INSTALL_DIR}" ]]; then
    cp "${bin_path}" "${INSTALL_DIR}/glab"
    chmod +x "${INSTALL_DIR}/glab"
  else
    echo "Need elevated privileges to write to ${INSTALL_DIR}"
    sudo cp "${bin_path}" "${INSTALL_DIR}/glab"
    sudo chmod +x "${INSTALL_DIR}/glab"
  fi

  rm -rf "${tmp_dir}"
  echo "glab v${version} installed to ${INSTALL_DIR}/glab"
}

main() {
  echo "Fetching latest stable version..."
  local latest
  latest="$(get_latest_version)"

  if [[ -z "${latest}" ]]; then
    echo "Error: could not determine latest version" >&2
    exit 1
  fi

  local current
  current="$(get_installed_version)"

  if [[ -n "${current}" ]]; then
    if [[ "${current}" == "${latest}" ]]; then
      echo "glab is already up to date (v${current})"
      exit 0
    fi
    echo "Updating glab: v${current} -> v${latest}"
  else
    echo "glab not found, installing v${latest}..."
  fi

  install_glab "${latest}"
  echo "Done. $(glab --version 2>/dev/null || true)"
}

main
