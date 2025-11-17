# Activer le Mode Développeur sur iPhone (iOS 18.5)

## Étapes pour activer le Mode Développeur

1. **Sur votre iPhone :**
   - Ouvrez **Réglages**
   - Allez dans **Confidentialité et sécurité**
   - Faites défiler jusqu'à **Mode développeur**
   - Activez le **Mode développeur**

2. **Si l'option n'apparaît pas :**
   - Ouvrez **Xcode** sur votre Mac
   - Connectez votre iPhone via USB
   - Allez dans **Window → Devices and Simulators**
   - Sélectionnez votre iPhone
   - Xcode va demander d'activer le Mode Développeur
   - Acceptez sur votre iPhone

3. **Redémarrer l'iPhone :**
   - Après activation, redémarrez votre iPhone
   - Le Mode Développeur sera actif

4. **Vérifier la confiance :**
   - Sur l'iPhone, quand vous connectez au Mac
   - Une popup "Faire confiance à cet ordinateur ?" apparaît
   - Appuyez sur **Faire confiance**

5. **Relancer Flutter :**
   ```bash
   cd frontend
   flutter run -d 00008140-000E2C412E00401C
   ```

## Si ça ne fonctionne toujours pas

- Vérifiez que votre iPhone est déverrouillé
- Vérifiez le câble USB (essayez un autre câble)
- Dans Xcode : **Window → Devices and Simulators** → Vérifiez que l'iPhone apparaît
- Redémarrez Xcode et reconnectez l'iPhone

