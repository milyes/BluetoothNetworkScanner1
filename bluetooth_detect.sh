#!/bin/bash

# Chargement de la configuration
source "${HOME}/.bluetooth_detect/config.sh"

# Fonction de logging
log_bluetooth() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "${LOG_FILE}"
}

# Fonction principale de détection Bluetooth
detect_bluetooth_network() {
    # Vérification si Bluetooth est activé
    if ! hciconfig hci0 up 2>/dev/null; then
        echo -e "${ROUGE}Bluetooth désactivé.${NEUTRE}"
        log_bluetooth "Erreur: Bluetooth désactivé"
        return 1
    fi

    echo -e "${VERT}Scanning des réseaux Bluetooth...${NEUTRE}"
    
    # Création d'un fichier temporaire pour les résultats
    temp_file=$(mktemp)
    
    # Scan des appareils avec timeout
    timeout 10s hcitool scan > "$temp_file" 2>/dev/null

    # Vérification des résultats
    if [ ! -s "$temp_file" ]; then
        echo -e "${ROUGE}Aucun appareil Bluetooth détecté.${NEUTRE}"
        log_bluetooth "Aucun appareil détecté"
        rm "$temp_file"
        return 1
    fi

    # Traitement des résultats
    while read -r line; do
        if [[ $line == *":"* ]]; then
            mac_address=$(echo "$line" | awk '{print $1}')
            device_name=$(echo "$line" | cut -d' ' -f2-)
            
            # Récupération des informations détaillées
            device_info=$(bluetoothctl info "$mac_address" 2>/dev/null)
            
            # Détection du type de réseau
            if echo "$device_info" | grep -q "ServiceRecords"; then
                network_type="PAN (Personal Area Network)"
            elif echo "$device_info" | grep -q "Audio"; then
                network_type="Audio"
            else
                network_type="Standard"
            fi

            echo -e "${VERT}Appareil détecté:${NEUTRE}"
            echo -e "  Adresse MAC: ${mac_address}"
            echo -e "  Nom: ${device_name}"
            echo -e "  Type: ${network_type}"
            
            log_bluetooth "Appareil détecté - MAC: ${mac_address}, Nom: ${device_name}, Type: ${network_type}"
        fi
    done < "$temp_file"

    rm "$temp_file"
    return 0
}

# Exécution de la détection si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_bluetooth_network
fi
