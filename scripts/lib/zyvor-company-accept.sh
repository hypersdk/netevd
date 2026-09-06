#!/usr/bin/env bash
# Copyright 2026 Zyvor AI Labs · https://zyvor.dev
# SPDX-License-Identifier: Apache-2.0
# Zyvor company terms — does not replace LICENSE (Apache-2.0).
set -euo pipefail
PRODUCT="netevd"
CODE_LICENSE="Apache-2.0"
LICENSE_FILE="LICENSE"
ENV_PREFIX="NETEVD"
RECORD_DIR="netevd"

zyvor_terms_file() { echo "${1:?}/ZYVOR-COMPANY-TERMS.md"; }

zyvor_terms_hash() {
  local f="${1:?}"
  if command -v shasum &>/dev/null; then shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then sha256sum "$f" | awk '{print $1}'
  else wc -c <"$f" | tr -d ' '; fi
}

zyvor_terms_record_path() { echo "${HOME}/.${RECORD_DIR}/zyvor-company-acceptance.json"; }

zyvor_terms_already_recorded() {
  local root="${1:?}" tf h rec
  tf="$(zyvor_terms_file "$root")"
  h="$(zyvor_terms_hash "$tf")"
  rec="$(zyvor_terms_record_path)"
  [[ -f "$rec" ]] || return 1
  command -v python3 &>/dev/null || return 1
  python3 - "$rec" "$h" <<'PY' >/dev/null 2>&1
import json, sys
with open(sys.argv[1]) as f: d = json.load(f)
sys.exit(0 if d.get("termsHash")==sys.argv[2] and d.get("accepted") else 1)
PY
}

zyvor_terms_write_record() {
  local root="${1:?}" actor="${2:-${USER:-unknown}}"
  local tf h rec ts
  tf="$(zyvor_terms_file "$root")"
  h="$(zyvor_terms_hash "$tf")"
  mkdir -p "${HOME}/.${RECORD_DIR}"
  rec="$(zyvor_terms_record_path)"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if command -v python3 &>/dev/null; then
    python3 - "$rec" "$h" "$actor" "$ts" "$PRODUCT" "$CODE_LICENSE" <<'PY'
import json, sys
path,h,actor,ts,prod,lic=sys.argv[1:7]
with open(path,"w") as f:
  json.dump({"accepted":True,"termsVersion":"1.0","termsHash":h,"acceptedAt":ts,
    "acceptedBy":actor,"product":prod,"codeLicense":lic,
    "company":"ZyvorAI Labs Private Limited","brand":"zyvor.dev",
    "contact":"sales@zyvor.dev"},f,indent=2)
  f.write("\n")
PY
  else
    printf '{"accepted":true,"termsHash":"%s"}\n' "$h" >"$rec"
  fi
}

zyvor_terms_show_summary() {
  local root="${1:?}" tf
  tf="$(zyvor_terms_file "$root")"
  echo ""
  echo "  $PRODUCT — Zyvor company terms (zyvor.dev)"
  echo "  Code: $CODE_LICENSE — $LICENSE_FILE"
  echo "  Terms: $tf"
  sed -n '1,18p' "$tf" | sed 's/^/  /'
  echo ""
}

require_zyvor_company_accept() {
  local root="${1:?}" tf var
  tf="$(zyvor_terms_file "$root")"
  [[ -f "$tf" ]] || { echo "ERROR: Missing $tf" >&2; exit 1; }
  zyvor_terms_already_recorded "$root" && return 0
  local _zyvor_accept=""
  eval "_zyvor_accept=\"\${${ENV_PREFIX}_ZYVOR_ACCEPT:-}\""
  if [[ "$_zyvor_accept" == "1" ]]; then
    zyvor_terms_write_record "$root" "${USER:-unknown}"
    echo "✅ Zyvor terms accepted"
    return 0
  fi
  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    echo "ERROR: Accept Zyvor terms: $tf (export ${ENV_PREFIX}_ZYVOR_ACCEPT=1)" >&2
    exit 1
  fi
  zyvor_terms_show_summary "$root"
  echo -n "Type ACCEPT: "
  local r; read -r r
  [[ "$r" == "ACCEPT" ]] || { echo "Aborted." >&2; exit 1; }
  zyvor_terms_write_record "$root" "${USER:-unknown}"
}
