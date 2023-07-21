#!/bin/bash
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/coredge/scripts/libcoredge.sh
. /opt/coredge/scripts/liblog.sh
. /opt/coredge/scripts/libkeycloak.sh

# Load keycloak environment variables
. /opt/coredge/scripts/keycloak-env.sh

print_welcome_page

if [[ "$*" = *"/opt/coredge/scripts/keycloak/run.sh"* ]]; then
    info "** Starting keycloak setup **"
    /opt/coredge/scripts/keycloak/setup.sh
    info "** keycloak setup finished! **"
fi

echo ""
exec "$@"
