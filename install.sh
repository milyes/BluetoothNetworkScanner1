#!/bin/bash

# Définition des couleurs pour les messages
ROUGE='\033[0;31m'
VERT='\033[0;32m'
NEUTRE='\033[0m'

# Création du répertoire d'installation et de logs
install_dir="${HOME}/.bluetooth_detect"
mkdir -p "$install_dir"
touch "${install_dir}/install.log"

# Fonction de logging
log_message() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "${install_dir}/install.log"
    echo -e "${message}"
}

# Installation des dépendances système
log_message "Installation des dépendances systèmes..."
if command -v apt-get &> /dev/null; then
    apt-get update || log_message "${ROUGE}Erreur lors de la mise à jour des paquets${NEUTRE}"
    apt-get install -y bluetooth bluez bluez-tools || log_message "${ROUGE}Erreur lors de l'installation des paquets Bluetooth${NEUTRE}"
fi

# Vérification de l'installation des outils
required_tools=("hciconfig" "hcitool" "bluetoothctl")
missing_tools=()
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    log_message "${ROUGE}Erreur: Les outils suivants n'ont pas pu être installés: ${missing_tools[*]}${NEUTRE}"
    exit 1
fi

# Copie des fichiers
cp bluetooth_detect.sh "$install_dir/"
cp config.sh "$install_dir/"
chmod +x "$install_dir/bluetooth_detect.sh"
chmod +x "$install_dir/config.sh"

# Configuration de .bashrc
if ! grep -q "source ${install_dir}/bluetooth_detect.sh" "${HOME}/.bashrc"; then
    echo "source ${install_dir}/bluetooth_detect.sh" >> "${HOME}/.bashrc"
    log_message "${VERT}Configuration de .bashrc effectuée${NEUTRE}"
fi

# Test du service Bluetooth
if systemctl is-active bluetooth.service &> /dev/null; then
    log_message "${VERT}Service Bluetooth déjà actif${NEUTRE}"
else
    if systemctl start bluetooth.service; then
        systemctl enable bluetooth.service
        log_message "${VERT}Service Bluetooth démarré et activé${NEUTRE}"
    else
        log_message "${ROUGE}Impossible de démarrer le service Bluetooth${NEUTRE}"
    fi
fi

log_message "${VERT}Installation terminée${NEUTRE}"
log_message "Pour commencer à utiliser le script, veuillez redémarrer votre terminal ou exécuter: source ~/.bashrc"