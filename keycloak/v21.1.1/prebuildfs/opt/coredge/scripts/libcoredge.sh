#!/bin/bash
# Copyright Coredge, Inc.
# SPDX-License-Identifier: APACHE-2.0
#

# shellcheck disable=SC1091

# Load Generic Libraries
. /opt/coredge/scripts/liblog.sh

# Constants
BOLD='\033[1m'

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
# Print the welcome page for a Coredge Docker image
# Globals:
#   COREDGE_APP_NAME
# Arguments:
#   None
# Returns:
#   None
#########################
print_image_welcome_page() {

    log ""
    log "${BOLD}Welcome to the Coredge ${COREDGE_APP_NAME} container${RESET}"
    log ""
}

