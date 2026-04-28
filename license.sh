#!/usr/bin/env bash
# =============================================================================
# license.sh — DeelTech Solutions | CSC2510 Final Project Spring 2026
#
# Part 4: License Enforcement Module
# AI-assisted key obfuscation technique (required per project specification)
#
# Usage (source into main.sh):
#   source "$(dirname "$0")/license.sh"
#   enforce_license
#
# Standalone utilities:
#   bash license.sh check      — verify license status on this machine
#   bash license.sh generate   — developer tool: generate digest for a new key
#
# AI Citation:
#   Key obfuscation technique (HMAC-SHA256 split-secret design) was developed
#   with AI assistance per CSC2510 project requirements (Part 4, Section iv).
# =============================================================================

# =============================================================================
# OBFUSCATED KEY MATERIAL
# -----------------------------------------------------------------------------
# The 16-digit DeelTech license key is NEVER stored in plaintext.
# Technique (AI-assisted): HMAC-SHA256 with a base64-encoded split secret.
#
#   1. The actual key is hashed with HMAC-SHA256 using a private secret.
#   2. Only the resulting digest is embedded here — the key cannot be reversed.
#   3. The HMAC secret is split into two base64-encoded halves so neither
#      half alone reveals anything useful to someone reading this file.
#
# To regenerate for a NEW key:
#   bash license.sh generate
# =============================================================================

# Split HMAC secret — base64-encoded halves (AI-assisted obfuscation)
_DT_SECRET_A="cGE="
_DT_SECRET_B="c3M="
# HMAC-SHA256 digest of the canonical license key "DEEL-TECH-2026-0001"
# Replace both lines with output from:  bash license.sh generate
_DT_HMAC_DIGEST=(
    "b8802e4ce30a0a5f"
    "686ceaf7e9b8edf1"
    "320b78a778a52173"
    "e912305924aa806d"
)


# License file — name chosen by team ("svc_runtime" looks like a system file)
_DT_LICENSE_PATHS=(
    "$HOME/.local/share/svc_runtime.dat"
    "$HOME/.config/.svc_runtime.dat"
    "/tmp/.svc_runtime_${USER}.dat"
    "$(dirname "${BASH_SOURCE[0]}")/svc_runtime.dat"
)

# Magic bytes written into the license file header
_DT_MAGIC="44454C54454348"          # hex for "DEELTECH"

# Maximum failed key-entry attempts before the program exits
_DT_MAX_ATTEMPTS=3


# =============================================================================
# INTERNAL HELPERS
# =============================================================================

# Reassemble the full HMAC secret from the two encoded halves at runtime.
# The secret only exists in memory during execution — never on disk.
_dt_get_secret() {
    printf '%s' \
        "$(printf '%s' "$_DT_SECRET_A" | base64 -d 2>/dev/null)" \
        "$(printf '%s' "$_DT_SECRET_B" | base64 -d 2>/dev/null)"
}

# Join the four digest fragments into one 64-character hex string.
_dt_full_digest() {
    printf '%s' "${_DT_HMAC_DIGEST[@]}"
}

# Normalise raw user input to canonical form: XXXX-XXXX-XXXX-XXXX (uppercase).
# Prints the canonical key on success; returns 1 if the input is invalid.
_dt_canonical_key() {
    local raw="$1"
    local digits
    digits=$(printf '%s' "$raw" \
        | tr -d $'[:space:]\r-' \
        | tr '[:lower:]' '[:upper:]')

    if [[ ${#digits} -ne 16 ]]; then
        return 1
    fi
    printf '%s-%s-%s-%s' \
        "${digits:0:4}" "${digits:4:4}" \
        "${digits:8:4}" "${digits:12:4}"
}

# Compute HMAC-SHA256 of a canonical key using the reassembled secret.
# Prints the lowercase hex digest.
_dt_compute_digest() {
    local key="$1"
    local secret
    secret=$(_dt_get_secret)
    printf '%s' "$key" \
        | openssl dgst -sha256 -hmac "$secret" 2>/dev/null \
        | awk '{print $NF}'
}

# Timing-safe string comparison.
# Hashes both sides with sha256sum so the == check does not short-circuit
# and leak information about how many characters matched.
_dt_safe_compare() {
    local a="$1" b="$2"
    local ha hb
    ha=$(printf '%s' "$a" | sha256sum | awk '{print $1}')
    hb=$(printf '%s' "$b" | sha256sum | awk '{print $1}')
    [[ "$ha" == "$hb" ]]
}

# Validate raw key input against the embedded digest.
# Returns 0 (valid) or 1 (invalid).
_dt_check_key() {
    local raw="$1"
    local canon
    canon=$(_dt_canonical_key "$raw") || return 1
    local digest
    digest=$(_dt_compute_digest "$canon")
    _dt_safe_compare "$digest" "$(_dt_full_digest)"
}

# Return the first path whose parent directory is writable.
_dt_get_license_path() {
    local path parent
    for path in "${_DT_LICENSE_PATHS[@]}"; do
        parent=$(dirname "$path")
        if mkdir -p "$parent" 2>/dev/null && [[ -w "$parent" ]]; then
            printf '%s' "$path"
            return 0
        fi
    done
    # Absolute fallback: same directory as this script
    printf '%s' "$(dirname "${BASH_SOURCE[0]}")/svc_runtime.dat"
}

# Write a validated license file to disk.
#
# File format (3 lines, mode 600):
#   Line 1: hex magic header   (DEELTECH in hex)
#   Line 2: Unix activation timestamp
#   Line 3: HMAC-SHA256 digest (NOT the key itself)
#
# Prints the path where the file was written.
_dt_write_license() {
    local raw_key="$1"
    local canon
    canon=$(_dt_canonical_key "$raw_key") || return 1

    local digest
    digest=$(_dt_compute_digest "$canon")

    local path
    path=$(_dt_get_license_path)

    {
        printf '%s\n' "$_DT_MAGIC"
        date +%s
        printf '%s\n' "$digest"
    } > "$path"

    chmod 600 "$path" 2>/dev/null
    printf '%s' "$path"
}

# Scan all known license paths for a valid, well-formed license file.
# Returns 0 if a valid license exists, 1 otherwise.
_dt_read_license() {
    local path magic ts stored_digest

    for path in "${_DT_LICENSE_PATHS[@]}" \
                "$(dirname "${BASH_SOURCE[0]}")/svc_runtime.dat"; do

        [[ -f "$path" ]] || continue

        {
            IFS= read -r magic
            IFS= read -r ts
            IFS= read -r stored_digest
        } < "$path"

        # Verify magic header
        [[ "$magic" == "$_DT_MAGIC" ]] || continue

        # Timing-safe digest comparison
        if _dt_safe_compare "$stored_digest" "$(_dt_full_digest)"; then
            return 0
        fi
    done

    return 1
}


# =============================================================================
# PUBLIC API — call this from main.sh
# =============================================================================

# enforce_license
#
# Checks for a valid license before the calling script continues.
#   • Valid file found  - returns immediately (transparent to the user).
#   • No file found     - prompts for the 16-digit key (hidden input).
#     - Correct key     - writes license file, returns.
#     - Wrong key × 3   - prints error and exits the entire script.
enforce_license() {
    # ── Already licensed ──────────────────────────────────────────────────────
    if _dt_read_license; then
        return 0
    fi
    # ── First run or missing file — prompt for key ────────────────────────────
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           DEELTECH SOLUTIONS — LICENSE REQUIRED          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  No valid license file was found on this machine.        ║"
    echo "║  Contact your Scrum Master for the 16-digit license key. ║"
    echo "║  Format: XXXX-XXXX-XXXX-XXXX  (dashes optional)         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    local attempt raw_key saved_path remaining

    for (( attempt=1; attempt<=_DT_MAX_ATTEMPTS; attempt++ )); do
        # -s suppresses terminal echo so the key is never visible on screen
        read -r -s -p "  License key (attempt ${attempt}/${_DT_MAX_ATTEMPTS}): " raw_key
        echo ""  # newline after hidden input

        if _dt_check_key "$raw_key"; then
            saved_path=$(_dt_write_license "$raw_key")
            echo ""
            echo "   License accepted."
            echo "    Activation file written to: $saved_path"
            echo ""
            return 0
        fi

        remaining=$(( _DT_MAX_ATTEMPTS - attempt ))
        if (( remaining > 0 )); then
            echo "   Invalid key — ${remaining} attempt(s) remaining."
            echo ""
        else
            echo ""
            echo "   Too many failed attempts."
            echo "    Contact your Scrum Master for a valid license key."
            echo ""
            exit 1
        fi
    done
}


# =============================================================================
# DEVELOPER CLI UTILITIES
# Run this file directly — not sourced — to access these commands.
# =============================================================================

_dt_cli_check() {
    echo ""
    echo "DeelTech Solutions — License Check"
    echo "-----------------------------------"
    if _dt_read_license; then
        echo " Valid license found on this machine."
        echo ""
        exit 0
    else
        echo " No valid license found."
        echo ""
        exit 1
    fi
}

_dt_cli_generate() {

    
    local STORED_HASH="acd694d7ac2fd22b8f4fd7beea11b5bdf51ce706604b00a5df7e4edd0167e83b"

    local user_input
    echo -n "Enter Admin Password: "
    read -r -s user_input < /dev/tty
    echo ""
    user_input=$(printf '%s' "$user_input" | tr -d '\r')

    if [[ -z "$user_input" ]]; then
        echo "Error: No password entered."
        exit 1
    fi

    local input_hash
    input_hash=$(printf '%s' "$user_input" | sha256sum | awk '{print $1}')

    if [[ "$input_hash" != "$STORED_HASH" ]]; then
        echo "incorrect Admin Password: PLEASE REOPEN THE OPERATION!!"
        exit 1
    fi
    echo ""
    echo "DeelTech Solutions — License Key Generator"
    echo "============================================"
    echo "(AI-assisted obfuscation tool — CSC2510 Part 4)"
    echo ""

    read -r -p "Enter the 16-digit license key (e.g. DEEL-TECH-2026-0001): " raw_key

    local canon
    canon=$(_dt_canonical_key "$raw_key") || {
        echo "Error: key must be exactly 16 alphanumeric characters."
        exit 1
    }

    local secret
    read -r -s -p "Enter HMAC secret passphrase: " secret
    echo ""
    [[ -z "$secret" ]] && { echo "Error: secret cannot be empty."; exit 1; }

    local digest
    digest=$(printf '%s' "$canon" \
        | openssl dgst -sha256 -hmac "$secret" 2>/dev/null \
        | awk '{print $NF}')

    # Split secret into two halves for embedding
    local half=$(( ${#secret} / 2 ))
    local sa sb
    sa=$(printf '%s' "${secret:0:$half}" | base64 | tr -d '\n')
    sb=$(printf '%s' "${secret:$half}"   | base64 | tr -d '\n')

    # Split digest into four 16-character fragments for embedding
    local d1="${digest:0:16}"
    local d2="${digest:16:16}"
    local d3="${digest:32:16}"
    local d4="${digest:48:16}"

    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "  Paste these lines into license.sh (replace placeholders)"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    echo "_DT_SECRET_A=\"${sa}\""
    echo "_DT_SECRET_B=\"${sb}\""
    echo "_DT_HMAC_DIGEST=("
    echo "    \"${d1}\""
    echo "    \"${d2}\""
    echo "    \"${d3}\""
    echo "    \"${d4}\""
    echo ")"
    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "  Email this key(Scrum Master):"
    echo "  $canon"
    echo "══════════════════════════════════════════════════════════"
    echo ""
}
_dt_cli_revoke() {
    echo ""
    echo "DeelTech Solutions — Revoke License"
    echo "-------------------------------------"
    local path removed=0
    for path in "${_DT_LICENSE_PATHS[@]}" \
                "$(dirname "${BASH_SOURCE[0]}")/svc_runtime.dat"; do
        if [[ -f "$path" ]]; then
            rm -f "$path" && echo "  Removed: $path" && (( removed++ ))
        fi
    done
    if (( removed == 0 )); then
        echo "  No license file found to remove."
    else
        echo "  License revoked. The program will prompt for a key on next run."
    fi
    echo ""
}

# Guard: only execute CLI logic when run directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        check)
            _dt_cli_check
            ;;
        generate)
            _dt_cli_generate
            ;;
        revoke)
            _dt_cli_revoke
            ;;
        *)
            echo ""
            echo "DeelTech Solutions — license.sh"
            echo "Usage:"
            echo "  bash license.sh check      — verify license status"
            echo "  bash license.sh generate   — generate digest for a new key"
            echo "  bash license.sh revoke     — remove license file (re-prompt on next run)"
            echo ""
            ;;
    esac
fi
