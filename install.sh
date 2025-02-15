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

# Détection de l'environnement Termux
is_termux() {
    if [ -d "/data/data/com.termux" ]; then
        return 0
    else
        return 1
    fi
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

    if is_termux; then
        log_message "Installation des dépôts et outils sur Termux..."
        # Mise à jour des dépôts
        pkg update -y
        # Installation du dépôt root
        pkg install -y root-repo
        # Installation des outils Bluetooth
        pkg install -y bluetoothd bluez
    else
        log_message "Installation des outils manquants..."
        sudo apt-get update
        sudo apt-get install -y bluez bluez-tools
    fi
fi

# Copie des fichiers
cp bluetooth_detect.sh "$install_dir/"
cp config.sh "$install_dir/"
chmod +x "$install_dir/bluetooth_detect.sh"
chmod +x "$install_dir/config.sh"

# Configuration de .bashrc
if ! grep -q "source ${install_dir}/bluetooth_detect.sh" "${HOME}/.bashrc" 2>/dev/null; then
    echo "source ${install_dir}/bluetooth_detect.sh" >> "${HOME}/.bashrc" 2>/dev/null
    log_message "${VERT}Configuration de .bashrc effectuée${NEUTRE}"
fi

log_message "${VERT}Installation terminée${NEUTRE}"
if is_termux; then
    log_message "Note: Sur Termux, assurez-vous que:"
    log_message "1. Le Bluetooth est activé dans les paramètres Android"
    log_message "2. Termux a les permissions Bluetooth nécessaires"
    log_message "3. Pour un accès complet, votre appareil doit être rooté"
fi
log_message "Pour commencer à utiliser le script, exécutez: source ${install_dir}/bluetooth_detect.sh"