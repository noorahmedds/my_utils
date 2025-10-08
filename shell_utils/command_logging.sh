log_cmd_to_cwd() {
  local status=$?
  local last=$(history 1 | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//')
  [[ -z "$last" ]] && return
  printf '%(%Y-%m-%d %H:%M:%S)T [%03d] %s\n' -1 "$status" "$last" >> "$PWD/.command_log"
}

enable_cmd_logging() {
  [[ "$PROMPT_COMMAND" == *"log_cmd_to_cwd"* ]] && return
  [[ -z "${_CMD_LOG_PREV_PROMPT+x}" ]] && _CMD_LOG_PREV_PROMPT="$PROMPT_COMMAND"
  PROMPT_COMMAND="log_cmd_to_cwd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

disable_cmd_logging() {
  [[ "$PROMPT_COMMAND" == *"log_cmd_to_cwd"* ]] || return
  PROMPT_COMMAND="${_CMD_LOG_PREV_PROMPT-}"
  unset _CMD_LOG_PREV_PROMPT
}

