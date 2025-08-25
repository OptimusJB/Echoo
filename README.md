# Spoutoufy

## Présentation
C'est un logiciel d'écoute de musique en gros

## Spec techniques

- python 3.13
- pygame-ce 2.5.3
- utilisation des sockets pour les communications avec le serveur
- le serveur utilise le port 25565

## Comment lancer
pour lancer le serveur :

```
cd serveur
python serveur.py
```
pour lancer le client :
```
cd client
python main.py
```

## Comment utiliser
- après avoir lancé le serveur, on a le choix entre lancer le serveur, créer une base de données, et gérer la base de données. La première chose à faire est de créer une base de données. Vous pourrez ensuite ajouter et supprimer des musiques, et enfin lancer le serveur.
- sur le client, il est possible de changer l'ip du serveur en cliquant en haut à gauche sur l'écran de connexion. Pour créer un compte, il faut juste se connecter avec un nouvel identifiant (le fait de créer un compte sera alors proposé)  
note : il est possible de cliquer sur le nom de l'artiste pour accéder à sa page, pareil pour le nom de l'album
