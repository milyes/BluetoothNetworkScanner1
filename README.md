pkg update
   pkg install root-repo
   pkg install wireless-tools
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

5. Configurez les variables d'environnement pour les notifications SMS :
   ```bash
   export TWILIO_ACCOUNT_SID="votre_account_sid"
   export TWILIO_AUTH_TOKEN="votre_auth_token"
   export TWILIO_PHONE_NUMBER="votre_numero_twilio"
   export NOTIFICATION_PHONE="votre_numero_personnel"
   ```

6. Activez le script :
   ```bash
   source ~/.wifi_detect/wifi_detect.sh
   ```

## Installation sur Ubuntu/Debian

1. Installez les dépendances système :
   ```bash
   sudo apt-get update
   sudo apt-get install wireless-tools python3-pip
   ```

2. Installez les dépendances Python :
   ```bash
   pip3 install twilio
   ```

## Configuration des Notifications SMS

Pour activer les notifications SMS via Twilio :

1. Créez un compte sur [Twilio](https://www.twilio.com)
2. Obtenez vos identifiants Twilio (Account SID et Auth Token)
3. Configurez les variables d'environnement :
   - TWILIO_ACCOUNT_SID : Votre Account SID Twilio
   - TWILIO_AUTH_TOKEN : Votre Auth Token Twilio
   - TWILIO_PHONE_NUMBER : Le numéro Twilio attribué
   - NOTIFICATION_PHONE : Votre numéro de téléphone personnel (format international)

## Mode Test

Si vous n'avez pas accès aux outils wireless-tools ou si vous voulez tester le script sans utiliser le WiFi :
```bash
TEST_MODE=true detect_wifi_network
```

## Résolution des problèmes

- Les journaux sont stockés dans : `~/.wifi_detect/wifi_detect.log`
- Pour Termux :
  - Vérifiez que le WiFi est activé dans les paramètres Android
  - Vérifiez que Termux a les permissions WiFi nécessaires
  - Pour les appareils rootés, assurez-vous d'avoir les permissions root correctes
- Pour Ubuntu/Debian :
  - En cas d'erreur de permission :
    ```bash
    sudo usermod -a -G netdev $USER