pkg update
   pkg install root-repo
   pkg install bluetoothd bluez
   ```

2. Clonez ce dépôt :
   ```bash
   git clone [URL_DU_DEPOT]
   cd [NOM_DU_DOSSIER]
   ```

3. Donnez les permissions nécessaires :
   ```bash
   termux-setup-storage
   ```

4. Lancez le script d'installation :
   ```bash
   bash install.sh
   ```

5. Activez le script :
   ```bash
   source ~/.bluetooth_detect/bluetooth_detect.sh
   ```

## Installation sur Ubuntu/Debian (Original instructions)

1. Installez les dépendances système (sur Ubuntu/Debian) :
   ```bash
   sudo apt-get update
   sudo apt-get install bluez bluez-tools
   ```

## Utilisation sur Termux

1. Activez le Bluetooth sur votre appareil Android dans les paramètres système

2. Démarrez le service Bluetooth :
   ```bash
   su -c "service bluetooth start"
   ```
   Note : Cette commande nécessite un appareil rooté. Si votre appareil n'est pas rooté, activez simplement le Bluetooth dans les paramètres Android.

3. Vérifiez que votre interface Bluetooth est reconnue :
   ```bash
   hciconfig
   ```

4. Exécutez la commande de détection :
   ```bash
   detect_bluetooth_network
   ```

## Utilisation en Mode Réel (Original instructions)

1. Assurez-vous que votre Bluetooth est activé :
   ```bash
   sudo systemctl start bluetooth
   sudo hciconfig hci0 up
   ```

2. Vérifiez que votre interface Bluetooth est reconnue :
   ```bash
   hciconfig
   ```

3. Exécutez la commande de détection :
   ```bash
   detect_bluetooth_network
   ```

## Mode Test

Si vous n'avez pas accès root ou si vous voulez tester le script sans utiliser le Bluetooth :
```bash
TEST_MODE=true detect_bluetooth_network
```

## Logs et Dépannage

- Les logs sont stockés dans : `~/.bluetooth_detect/bluetooth_detect.log`
- Vérifiez que Termux a les permissions Bluetooth dans les paramètres Android
- Si vous rencontrez des erreurs :
  - Assurez-vous que le Bluetooth est activé dans les paramètres Android
  - Vérifiez que Termux a les permissions nécessaires
  - Pour les appareils rootés, assurez-vous d'avoir les permissions root correctes
- Si vous rencontrez des erreurs de permission (Original instructions):
  ```bash
  sudo usermod -a -G bluetooth $USER