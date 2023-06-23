#!/bin/bash
#
# coredge custom library

# shellcheck disable=SC1091

# Load Generic Libraries
. /opt/coredge/scripts/liblog.sh

# Constants
BOLD='\033[1m'

export COREDGE_APP_NAME= print_image_welcome_page
# Functions

########################
# Print the welcome page
# Globals:
#   DISABLE_WELCOME_MESSAGE
#   COREDGE_APP_NAME
# Arguments:
#   None
# Returns:
#   None
#########################
print_welcome_page() {
    if [[ -z "${DISABLE_WELCOME_MESSAGE:-}" ]]; then
        if [[ -n "$COREDGE_APP_NAME" ]]; then
            print_image_welcome_page
        fi
    fi
}

########################
# Print the welcome page for a coredge Docker image
# Globals:
#   COREDGE_APP_NAME
# Arguments:
#   None
# Returns:
#   None
#########################
print_image_welcome_page() {
    local github_url="https://github.com/coredge/containers"

    log ""
    log "${BOLD}Welcome to the coredge ${COREDGE_APP_NAME} container${RESET}"
    log "Subscribe to project updates by watching ${BOLD}${github_url}${RESET}"
    log "Submit issues and feature requests at ${BOLD}${github_url}/issues${RESET}"
    log ""
}
