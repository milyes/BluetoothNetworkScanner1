#!/bin/bash
# Définition des couleurs pour les messages
ROUGE='\033[0;31m'
VERT='\033[0;32m'
NEUTRE='\033[0m'

# Création du répertoire d'installation et de logs
install_dir="$HOME/.bluetooth_detect"
mkdir -p "$install_dir"
chmod 700 "$install_dir"

# Fonction de logging
log_message() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "${install_dir}/install.log"
    echo -e "${message}"
}

# Vérification des outils nécessaires
log_message "Vérification des outils Bluetooth..."
required_tools=("hcitool" "bluetoothctl")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    log_message "${ROUGE}Erreur: Les outils suivants sont manquants: ${missing_tools[*]}${NEUTRE}"
    log_message "Installation des outils manquants..."
    sudo apt-get update
    sudo apt-get install -y bluez bluez-tools
fi

# Copie des fichiers avec les bonnes permissions
cp bluetooth_detect.sh "$install_dir/"
cp config.sh "$install_dir/"
chmod 700 "$install_dir/bluetooth_detect.sh"
chmod 600 "$install_dir/config.sh"

# Configuration de .bashrc
bashrc_file="$HOME/.bashrc"
if ! grep -q "source ${install_dir}/bluetooth_detect.sh" "$bashrc_file" 2>/dev/null; then
    echo "source ${install_dir}/bluetooth_detect.sh" >> "$bashrc_file"
fi

log_message "${VERT}Installation terminée${NEUTRE}"
log_message "Pour commencer à utiliser le script, exécutez:"
log_message "source ${install_dir}/bluetooth_detect.sh"