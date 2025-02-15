#!/bin/bash

# Chargement de la configuration
source "$HOME/.bluetooth_detect/config.sh"

# Fonction de logging
log_bluetooth() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
    echo -e "${message}"
}

# Fonction de vérification du service Bluetooth
check_bluetooth_service() {
    if [ "$TEST_MODE" = "true" ]; then
        return 0
    fi

    # Essayer différentes méthodes pour vérifier/démarrer le service Bluetooth
    if command -v service >/dev/null 2>&1; then
        if ! service bluetooth status >/dev/null 2>&1; then
            log_bluetooth "${ROUGE}Le service Bluetooth n'est pas actif. Démarrage...${NEUTRE}"
            sudo service bluetooth start
            sleep 2
        else
            log_bluetooth "${VERT}Le service Bluetooth est actif${NEUTRE}"
        fi
    elif [ -f "/etc/init.d/bluetooth" ]; then
        if ! /etc/init.d/bluetooth status >/dev/null 2>&1; then
            log_bluetooth "${ROUGE}Le service Bluetooth n'est pas actif. Démarrage...${NEUTRE}"
            sudo /etc/init.d/bluetooth start
            sleep 2
        else
            log_bluetooth "${VERT}Le service Bluetooth est actif${NEUTRE}"
        fi
    else
        log_bluetooth "${JAUNE}Impossible de vérifier le statut du service Bluetooth. Continuation...${NEUTRE}"
    fi
}

# Fonction de simulation pour le mode test
simulate_bluetooth_devices() {
    cat << EOF
Scan en cours...
00:11:22:33:44:55	Smartphone Test
AA:BB:CC:DD:EE:FF	Écouteurs Test
12:34:56:78:90:AB	Enceinte Test
EOF
}

# Vérification de l'environnement Bluetooth
check_bluetooth_environment() {
    if [ "$TEST_MODE" = "true" ]; then
        log_bluetooth "${VERT}Mode test activé - Pas de vérification matérielle nécessaire${NEUTRE}"
        return 0
    fi

    # Vérification des outils requis
    local required_tools=("hcitool" "bluetoothctl")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_bluetooth "${ROUGE}Erreur : Les outils suivants sont manquants: ${missing_tools[*]}${NEUTRE}"
        return 1
    fi

    # Vérification du service Bluetooth
    check_bluetooth_service

    # Vérification de l'interface Bluetooth
    if ! hciconfig 2>/dev/null | grep -q "hci"; then
        log_bluetooth "${ROUGE}Erreur : Aucune interface Bluetooth n'a été détectée${NEUTRE}"
        return 1
    fi

    return 0
}

# Fonction principale de détection Bluetooth
detect_bluetooth_network() {
    log_bluetooth "${VERT}Vérification de l'environnement Bluetooth...${NEUTRE}"

    if ! check_bluetooth_environment; then
        log_bluetooth "${ROUGE}L'environnement n'est pas correctement configuré pour le Bluetooth${NEUTRE}"
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
        if ! sudo hciconfig hci0 up 2>/dev/null; then
            log_bluetooth "${ROUGE}Impossible d'activer l'interface Bluetooth${NEUTRE}"
            rm "$temp_file"
            return 1
        fi

        # Scan des appareils avec timeout et capture des erreurs
        if ! timeout ${SCAN_TIMEOUT}s sudo hcitool scan > "$temp_file" 2>&1; then
            log_bluetooth "${ROUGE}Erreur durant le scan Bluetooth${NEUTRE}"
            rm "$temp_file"
            return 1
        fi
    fi

    # Vérification et affichage des résultats
    if [ ! -s "$temp_file" ]; then
        log_bluetooth "${ROUGE}Aucun appareil Bluetooth n'a été détecté${NEUTRE}"
        rm "$temp_file"
        return 1
    fi

    # Traitement et affichage des résultats
    log_bluetooth "${VERT}Appareils détectés :${NEUTRE}"
    while read -r line; do
        if [[ $line != "Scanning ..."* ]] && [[ $line != "Scan en cours..."* ]]; then
            mac_address=$(echo "$line" | awk '{print $1}')
            device_name=$(echo "$line" | cut -d$'\t' -f2-)

            echo -e "  Adresse MAC : ${mac_address}"
            echo -e "  Nom : ${device_name}"

            if [ "$TEST_MODE" = "false" ] && command -v bluetoothctl &> /dev/null; then
                device_info=$(sudo bluetoothctl info "$mac_address" 2>/dev/null)
                device_class=$(echo "$device_info" | grep "Class:" | cut -d' ' -f2-)

                if [ ! -z "$device_class" ]; then
                    echo -e "  Classe : ${device_class}"
                fi
            fi

            log_bluetooth "Appareil détecté - Adresse MAC : ${mac_address}, Nom : ${device_name}"
        fi
    done < "$temp_file"

    rm "$temp_file"
    return 0
}

# Exécution de la détection si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_bluetooth_network
fi