# claude-profile.zsh — Manage Claude Code config profiles via CLAUDE_CONFIG_DIR
# Source from ~/.zshrc:
#   source ~/.config/claude-profile/claude-profile.zsh

_CP_DATA="${HOME}/.claude-profiles"
_CP_DEFAULT_FILE="${_CP_DATA}/.default"

_cp_die() { printf 'claude-profile: %s\n' "$1" >&2; }

_cp_validate_name() {
  case "$1" in
    "")              _cp_die "name empty"; return 1 ;;
    .*|*..*|*/*|*\\*) _cp_die "bad name: '$1'"; return 1 ;;
    *[!A-Za-z0-9_-]*) _cp_die "name must match [A-Za-z0-9_-]+"; return 1 ;;
  esac
}

# Wrap `claude` so the active/default profile sets CLAUDE_CONFIG_DIR.
claude() {
  if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -f "$_CP_DEFAULT_FILE" ]; then
    local _name=$(cat "$_CP_DEFAULT_FILE" 2>/dev/null)
    if [ -n "$_name" ] && [ -d "${_CP_DATA}/${_name}" ]; then
      export CLAUDE_CONFIG_DIR="${_CP_DATA}/${_name}"
    fi
  fi
  command claude "$@"
}

claude-profile() {
  local cmd="${1:-}"
  [ $# -gt 0 ] && shift

  case "$cmd" in
    use)
      local n="${1:-}"
      _cp_validate_name "$n" || return 1
      [ -d "${_CP_DATA}/${n}" ] || { _cp_die "profile '$n' missing (create: claude-profile create $n)"; return 1; }
      export CLAUDE_CONFIG_DIR="${_CP_DATA}/${n}"
      printf 'switched: %s\n' "$n"
      ;;

    create)
      local n="${1:-}"
      _cp_validate_name "$n" || return 1
      [ -d "${_CP_DATA}/${n}" ] && { _cp_die "profile '$n' exists"; return 1; }
      mkdir -p "${_CP_DATA}/${n}"
      printf 'created: %s\n' "${_CP_DATA}/${n}"
      ;;

    list|ls)
      local def="" active=""
      [ -f "$_CP_DEFAULT_FILE" ] && def=$(cat "$_CP_DEFAULT_FILE" 2>/dev/null)
      case "${CLAUDE_CONFIG_DIR:-}" in
        "${_CP_DATA}"/*) active=$(basename "$CLAUDE_CONFIG_DIR") ;;
      esac
      local found=0 n tag
      for e in "${_CP_DATA}"/*/; do
        [ -d "$e" ] || continue
        n=$(basename "$e"); found=1
        tag=""
        [ "$n" = "$def" ] && tag="${tag}default"
        [ "$n" = "$active" ] && tag="${tag:+$tag,}active"
        if [ -n "$tag" ]; then printf '  %s (%s)\n' "$n" "$tag"
        else printf '  %s\n' "$n"; fi
      done
      [ $found -eq 0 ] && printf 'no profiles (claude-profile create <name>)\n'
      ;;

    default)
      local n="${1:-}"
      if [ -z "$n" ]; then
        if [ -f "$_CP_DEFAULT_FILE" ]; then
          local cur=$(cat "$_CP_DEFAULT_FILE" 2>/dev/null)
          [ -n "$cur" ] && printf '%s\n' "$cur" || { _cp_die "default file empty"; return 1; }
        else
          _cp_die "no default set"
          return 1
        fi
      else
        _cp_validate_name "$n" || return 1
        [ -d "${_CP_DATA}/${n}" ] || { _cp_die "profile '$n' missing"; return 1; }
        printf '%s' "$n" > "$_CP_DEFAULT_FILE"
        printf 'default: %s\n' "$n"
      fi
      ;;

    which)
      local n="${1:-}"
      if [ -z "$n" ]; then
        [ -f "$_CP_DEFAULT_FILE" ] || { _cp_die "no default set"; return 1; }
        n=$(cat "$_CP_DEFAULT_FILE" 2>/dev/null)
      fi
      _cp_validate_name "$n" || return 1
      [ -d "${_CP_DATA}/${n}" ] || { _cp_die "profile '$n' missing"; return 1; }
      printf '%s\n' "${_CP_DATA}/${n}"
      ;;

    delete|rm)
      local n="${1:-}"
      _cp_validate_name "$n" || return 1
      [ -d "${_CP_DATA}/${n}" ] || { _cp_die "profile '$n' missing"; return 1; }
      printf 'delete profile "%s" and ALL its data? [y/N] ' "$n"
      local ans=""
      read -r ans
      case "$ans" in
        y|Y|yes|YES)
          rm -rf "${_CP_DATA}/${n}"
          printf 'deleted: %s\n' "$n"
          if [ -f "$_CP_DEFAULT_FILE" ] && [ "$(cat "$_CP_DEFAULT_FILE" 2>/dev/null)" = "$n" ]; then
            rm -f "$_CP_DEFAULT_FILE"
            printf 'cleared default\n'
          fi
          if [ "${CLAUDE_CONFIG_DIR:-}" = "${_CP_DATA}/${n}" ]; then
            unset CLAUDE_CONFIG_DIR
            printf 'cleared active\n'
          fi
          ;;
        *) printf 'cancelled\n' ;;
      esac
      ;;

    help|-h|--help)
      cat <<EOF
usage: claude-profile [cmd] [args]
  (none)            show active + default
  use <name>        switch session
  create <name>     new empty profile
  list, ls          list all
  default [name]    get or set default
  which [name]      print profile dir
  delete <name>     remove profile (confirm)
  help              this

auth: Claude derives a per-profile macOS keychain service name
(Claude Code-credentials-<sha256[:8] of CLAUDE_CONFIG_DIR>),
so each profile keeps its own login automatically.
EOF
      ;;

    "")
      local active=""
      case "${CLAUDE_CONFIG_DIR:-}" in
        "${_CP_DATA}"/*) active=$(basename "$CLAUDE_CONFIG_DIR") ;;
      esac
      if [ -n "$active" ]; then printf 'active:  %s\n' "$active"
      elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then printf 'active:  %s (unmanaged)\n' "$CLAUDE_CONFIG_DIR"
      else printf 'active:  (none)\n'; fi
      if [ -f "$_CP_DEFAULT_FILE" ]; then printf 'default: %s\n' "$(cat "$_CP_DEFAULT_FILE" 2>/dev/null)"
      else printf 'default: (none)\n'; fi
      ;;

    *)
      _cp_die "unknown command '$cmd' — try 'claude-profile help'"
      return 1
      ;;
  esac
}
