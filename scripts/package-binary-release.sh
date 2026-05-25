#!/usr/bin/env bash
# Build netevd and assemble customer tarball (local / GitHub Actions).
# Usage: ./scripts/package-binary-release.sh [--build] [--target TRIPLE] [--out-dir DIR]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DO_BUILD=false
TARGET="${CARGO_TARGET:-}"
OUT_DIR="${NETEVD_PACKAGE_DIR:-${REPO_DIR}/dist}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build) DO_BUILD=true; shift ;;
        --target) TARGET="${2:?}"; shift 2 ;;
        --out-dir) OUT_DIR="${2:?}"; shift 2 ;;
        -h|--help)
            sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

VERSION="${NETEVD_PACKAGE_VERSION:-$(sed -n 's/^version = "\(.*\)"/\1/p' "${REPO_DIR}/Cargo.toml" | head -1)}"
VERSION="${VERSION:-0.2.0}"

case "${TARGET:-x86_64-unknown-linux-gnu}" in
    x86_64-unknown-linux-gnu|"") ARCH_SUFFIX="linux-amd64" ;;
    aarch64-unknown-linux-gnu) ARCH_SUFFIX="linux-arm64" ;;
    *)
        echo "Unsupported target for customer bundle: ${TARGET}" >&2
        exit 1
        ;;
esac

ARTIFACT="netevd-${VERSION}-${ARCH_SUFFIX}"
TARGET_DIR="${REPO_DIR}/target"
if [[ -n "${TARGET}" ]]; then
    TARGET_DIR="${TARGET_DIR}/${TARGET}"
fi
BINARY="${NETEVD_BINARY:-${TARGET_DIR}/release/netevd}"

if $DO_BUILD; then
    cd "${REPO_DIR}"
    if [[ -n "${TARGET}" ]]; then
        cargo build --release --target "${TARGET}"
    else
        cargo build --release
    fi
fi

if [[ ! -x "${BINARY}" ]]; then
    echo "Missing release binary: ${BINARY} (pass --build or build first)" >&2
    exit 1
fi

# shellcheck source=lib/package-netevd-client-bundle.sh
source "${SCRIPT_DIR}/lib/package-netevd-client-bundle.sh"

STAGE="${OUT_DIR}/${ARTIFACT}"
export NETEVD_BINARY="${BINARY}"

echo "Assemble customer bundle → ${OUT_DIR}/${ARTIFACT}.tar.gz"
package_netevd_client_bundle "${STAGE}" "${REPO_DIR}" "${VERSION}"
package_netevd_client_tarball "${OUT_DIR}" "${ARTIFACT}" "${STAGE}"
"${BINARY}" --version 2>/dev/null || true
ls -lh "${OUT_DIR}/${ARTIFACT}.tar.gz"
echo "Done: ${OUT_DIR}/${ARTIFACT}.tar.gz"
