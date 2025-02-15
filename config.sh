#!/bin/bash

# Configuration des couleurs
ROUGE='\033[0;31m'
VERT='\033[0;32m'
NEUTRE='\033[0m'

# Configuration des chemins
INSTALL_DIR="${HOME}/.bluetooth_detect"
LOG_FILE="${INSTALL_DIR}/bluetooth_detect.log"

# Création du répertoire de logs s'il n'existe pas
mkdir -p "${INSTALL_DIR}"
touch "${LOG_FILE}"

# Configuration du timeout de scan (en secondes)
SCAN_TIMEOUT=10

# Mode test (true/false)
TEST_MODE=${TEST_MODE:-false}

# Configuration des permissions de logs
if [ -f "${LOG_FILE}" ]; then
    chmod 644 "${LOG_FILE}"
fi