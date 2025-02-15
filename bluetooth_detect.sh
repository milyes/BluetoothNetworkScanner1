#!/bin/bash

# Chargement de la configuration
source "${HOME}/.bluetooth_detect/config.sh"

# Fonction de logging
log_bluetooth() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
    echo -e "${message}"
}

# Fonction de simulation pour le mode test
simulate_bluetooth_devices() {
    cat << EOF
Scanning ...
00:11:22:33:44:55	Smartphone Test
AA:BB:CC:DD:EE:FF	Écouteurs Test
12:34:56:78:90:AB	Enceinte Test
EOF
}

# Fonction de vérification de l'environnement
check_bluetooth_environment() {
    if [ "$TEST_MODE" = "true" ]; then
        log_bluetooth "${VERT}Mode test activé - Pas de vérification matérielle nécessaire${NEUTRE}"
        return 0
    fi

    # Vérification de l'existence des outils
    if ! command -v hcitool &> /dev/null; then
        log_bluetooth "${ROUGE}Erreur: hcitool non trouvé${NEUTRE}"
        return 1
    fi

    if ! command -v bluetoothctl &> /dev/null; then
        log_bluetooth "${ROUGE}Erreur: bluetoothctl non trouvé${NEUTRE}"
        return 1
    fi

    # Vérification de l'interface Bluetooth
    if ! hciconfig &> /dev/null; then
        log_bluetooth "${ROUGE}Erreur: Pas d'interface Bluetooth détectée${NEUTRE}"
        return 1
    fi

    # Vérification des permissions
    if ! groups | grep -q "bluetooth"; then
        log_bluetooth "${ROUGE}Erreur: L'utilisateur n'a pas les permissions Bluetooth nécessaires${NEUTRE}"
        return 1
    fi

    return 0
}

# Fonction principale de détection Bluetooth
detect_bluetooth_network() {
    log_bluetooth "${VERT}Vérification de l'environnement Bluetooth...${NEUTRE}"

    if ! check_bluetooth_environment; then
        log_bluetooth "${ROUGE}L'environnement n'est pas configuré correctement pour le Bluetooth${NEUTRE}"
        return 1
    fi

    log_bluetooth "${VERT}Démarrage du scan Bluetooth...${NEUTRE}"

    # Création d'un fichier temporaire pour les résultats
    temp_file=$(mktemp)

    if [ "$TEST_MODE" = "true" ]; then
        # En mode test, utiliser des données simulées
        simulate_bluetooth_devices > "$temp_file"
    else
        # Activation de l'interface Bluetooth
        hciconfig_output=$(hciconfig hci0 up 2>&1)
        if [ $? -ne 0 ]; then
            log_bluetooth "${ROUGE}Impossible d'activer l'interface Bluetooth: ${hciconfig_output}${NEUTRE}"
            rm "$temp_file"
            return 1
        fi

        # Scan des appareils avec timeout et capture des erreurs
        scan_output=$(timeout ${SCAN_TIMEOUT}s hcitool scan 2>&1)
        scan_status=$?

        if [ $scan_status -eq 124 ]; then
            log_bluetooth "${ROUGE}Le scan a dépassé le délai d'attente${NEUTRE}"
            rm "$temp_file"
            return 1
        elif [ $scan_status -ne 0 ]; then
            log_bluetooth "${ROUGE}Erreur pendant le scan: ${scan_output}${NEUTRE}"
            rm "$temp_file"
            return 1
        fi

        echo "$scan_output" > "$temp_file"
    fi

    # Vérification des résultats
    if [ ! -s "$temp_file" ]; then
        log_bluetooth "${ROUGE}Aucun appareil Bluetooth détecté${NEUTRE}"
        rm "$temp_file"
        return 1
    fi

    # Traitement des résultats
    log_bluetooth "${VERT}Appareils détectés :${NEUTRE}"
    while read -r line; do
        if [[ $line != "Scanning ..."* ]]; then
            mac_address=$(echo "$line" | awk '{print $1}')
            device_name=$(echo "$line" | cut -d$'\t' -f2-)

            echo -e "  Adresse MAC: ${mac_address}"
            echo -e "  Nom: ${device_name}"

            if [ "$TEST_MODE" = "false" ] && command -v bluetoothctl &> /dev/null; then
                device_info=$(bluetoothctl info "$mac_address" 2>/dev/null)
                device_class=$(echo "$device_info" | grep "Class:" | cut -d' ' -f2-)

                if [ ! -z "$device_class" ]; then
                    echo -e "  Classe: ${device_class}"
                fi
            fi

            log_bluetooth "Appareil détecté - MAC: ${mac_address}, Nom: ${device_name}"
        fi
    done < "$temp_file"

    rm "$temp_file"
    return 0
}

# Exécution de la détection si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_bluetooth_network
fi