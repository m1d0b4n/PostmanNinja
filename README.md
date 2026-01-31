# 🥷

```
██████╗  ██████╗ ███████╗████████╗███╗   ███╗ █████╗ ███╗   ██╗
██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝████╗ ████║██╔══██╗████╗  ██║
██████╔╝██║   ██║███████╗   ██║   ██╔████╔██║███████║██╔██╗ ██║
██╔═══╝ ██║   ██║╚════██║   ██║   ██║╚██╔╝██║██╔══██║██║╚██╗██║
██║     ╚██████╔╝███████║   ██║   ██║ ╚═╝ ██║██║  ██║██║ ╚████║
╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
███╗   ██╗██╗███╗   ██╗     ██╗ █████╗ 
████╗  ██║██║████╗  ██║     ██║██╔══██╗
██╔██╗ ██║██║██╔██╗ ██║     ██║███████║
██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║
██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║
╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝
```

> **Discute comme un ninja.** 🌙  
> *Rapide. Efficace.*

[![WoW](https://img.shields.io/badge/WoW-Classic%20%7C%20Retail-00D1FF?style=for-the-badge&logo=battle-net)](https://worldofwarcraft.com)
[![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?style=for-the-badge&logo=lua)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

## 🎯 Mission Objective

PostmanNinja est un addon World of Warcraft conçu pour les vrais professionnels du spam... euh, de la communication ! Propose l'envoi de messages multiples dans différents canaux de chat à chaque connexion ou envoie-les manuellement.

**Cas d'usage :**
- 📢 Recrutement de guilde automatique
- 🛒 Annonces de ventes répétitives
- 🎮 Messages de bienvenue personnalisés
- 💬 Tout ce qui nécessite de poster régulièrement

---

## ⚡ Features

### 🔥 Système de Jobs Multi-Tâches
- Crée **plusieurs jobs** indépendants avec leurs propres paramètres
- Active/désactive chaque job individuellement
- Onglets à défilement horizontal pour gérer tous tes jobs

### 🎲 Messages Variés & Randomisés
- Ajoute **plusieurs variantes** de messages par job
- Le système choisit **aléatoirement** une variante à chaque envoi
- Évite les détections de spam avec des messages différents

### 🎯 Canaux Multiples
- **GUILD** - Canal de guilde
- **SAY** - Dire (proximité)
- **YELL** - Crier (zone)
- **PARTY** - Groupe
- **RAID** - Raid

### 🚀 Interface
- Interface moderne et épurée
- Auto-focus sur les nouveaux champs
- Suppression automatique des champs vides
- Popup de **proposition** d'envoi au login (positionnable & déplaçable)

### 🔧 Mode Test
- Teste un job spécifique avant de l'activer
- Teste tous les jobs actifs en un clic
- Vérifie tes messages

---

## 📦 Installation

### Méthode Ninja (Manuelle)
```bash
# Clone ce repo dans ton dossier AddOns
cd "World of Warcraft/_retail_/Interface/AddOns/"
git clone https://github.com/m1d0b4n/PostmanNinja.git

# Ou télécharge le ZIP et extrais-le
```

### Méthode Conventionnelle
1. Télécharge la [dernière release](https://github.com/m1d0b4n/PostmanNinja/releases)
2. Extrais le dossier dans `World of Warcraft/_retail_/Interface/AddOns/`
3. Redémarre WoW

---

## 🎮 Utilisation

### Commandes de Chat
```lua
/pmn              -- Ouvre/ferme l'interface
/postmanninja     -- Alias de /pmn
/pmn reload       -- Recharge l'interface (équivalent à /reload)
/pmn rl           -- Alias de reload
```

### Workflow

1. **Ouvre l'interface** avec `/pmn`
2. **Crée tes jobs** avec le bouton `+`
3. **Configure chaque job :**
   - Nomme ton job
   - Ajoute plusieurs variantes de messages
   - Choisis le canal de destination
   - Active le job avec la checkbox "Activé"
4. **Teste avant de lancer** avec "Test Job"
5. **Au prochain login**, un popup te proposera d'envoyer les jobs actifs ! 🥷
6. **Ou utilise "Test Tous"** pour envoyer manuellement tous les jobs actifs

### Astuces Pro

- 💡 **Champ vide ?** → Il se supprime auto quand tu cliques ailleurs
- 💡 **Nouveau message ?** → Le champ est auto-focus et prêt à l'emploi
- 💡 **Beaucoup de jobs ?** → Scroll horizontal avec la molette
- 💡 **Message vide envoyé ?** → Impossible, ils sont filtrés automatiquement

---

## 🐛 Debug & Support

Rencontré un bug ? Ouvre une [issue](https://github.com/m1d0b4n/PostmanNinja/issues) !

### Logs Console
Les messages sont affichés dans le chat principal :
- 🟢 **Vert** : Succès / Info
- 🟡 **Jaune** : Envoi de message
- 🔴 **Rouge** : Erreur

---

## 📜 License

MIT License - Fais ce que tu veux, ninja ! 🥷

---

## 🙏 Crédits

Développé par un mage avec 🖤 et beaucoup de ☕ givré ❄️ pour la communauté WoW.

**Special Thanks:**
- La communauté Lua WoW pour les APIs
- Tous les testeurs ninjas

---

## 🌟 Star ce repo si tu trouves ça cool !

*Stay ninja. Stay hidden. Post messages.* 🥷💨
