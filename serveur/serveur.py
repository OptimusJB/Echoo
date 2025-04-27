import socketserver
import os
import sqlite3

def init_db():
    """
    crée une base de donnée de base contenant :
    - une table représentant la liste des utilisateurs
    - une table représentant la liste des musiques
    """
    if "data.db" in os.listdir():
        print("data.db existe déjà, supprimez-le pour créer une nouvelle base de données")
    else:
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("CREATE TABLE Utilisateurs(id INTEGER, username TEXT, password TEXT, PRIMARY KEY (id AUTOINCREMENT))")
        cursor.execute("CREATE TABLE Musiques(id INTEGER, nom TEXT, genre TEXT, annee INTEGER, artiste TEXT, album TEXT, position_album INTEGER, image TEXT, min TEXT, moyen TEXT, max TEXT, PRIMARY KEY (id AUTOINCREMENT))")
        cursor.execute("CREATE TABLE Playlists(id INTEGER, nom TEXT, musiques LONGTEXT, id_utilisateur INTEGER, PRIMARY KEY (id AUTOINCREMENT), FOREIGN KEY (id_utilisateur) REFERENCES Utilisateurs(id))")
        #cursor.execute("INSERT INTO Utilisateurs(username, password) VALUES('jb', 'jb123')")
        #database.commit()
        #cursor.execute("SELECT username FROM Utilisateurs")
        cursor.close()
        database.close()

class request_manager(socketserver.BaseRequestHandler):

    def send_message(self, liste:list):
        assert type(liste) == list, "pas une liste"
        texte = self.transfo_chaine(liste)
        texte = bytes(texte, "utf-8")
        texte = bytes(str(len(texte)) + "a", "utf-8") + texte
        self.request.sendall(texte)

    def send_bytes(self, message):
        texte = message
        texte = bytes(str(len(texte)) + "a", "utf-8") + texte
        self.request.sendall(texte)

    def get_music_envoi(self, musique, qualite="max"):
        """
        qualite = qualité à renvoyer
        = "max (320kbps)" ou "moyen ()" ou "min (160kbps)"
        retourne la musique sous forme de bytes
        les musiques doivent être sous forme de mp3
        """
        assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT ? FROM Musiques WHERE nom == ?", (qualite, musique))
        resultat = cursor.fetchall()
        cursor.close()
        database.close()
        assert len(resultat) > 0, "la musique " + str(musique) + " n'existe pas"
        resultat = resultat[0][0]   # resultat[0] de la forme tuple de 1 valeur

        # ouverture du fichier
        fichier = open(resultat, "rb")
        music = fichier.read()
        fichier.close()
        return music

    def create_account(self, pseudo, mdp):
        assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("INSERT INTO Utilisateurs (username, password) VALUES (?, ?)", (pseudo, mdp))
        database.commit()
        cursor.close()
        database.close()
        print("nouvel utilisateur : " + pseudo)

    def transfo_chaine(self, liste, separateur="&slchaine&"):
        chaine = ""
        for element in liste:
            chaine = chaine + str(element) + separateur
        chaine = chaine[:len(chaine)-len(separateur)]
        return chaine

    def transfo_liste(self, chaine:str, separateur="&slchaine&"):
        if chaine == "":
            return []
        return chaine.split(separateur)

    def check_exist(self, pseudo, password):
        """
        retourne True si le compte existe dans la base de données, False sinon
        """
        assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT password FROM Utilisateurs WHERE username==?", (pseudo,))
        resultat = cursor.fetchall()
        cursor.close()
        database.close()

        assert not len(resultat) > 1, "trop d'enregistrements trouvés (normalement il y en a qu'un)"
        if len(resultat) == 1:
            if resultat[0][0] == password:
                # connexion réussie
                return "oui"
            else:
                return "non"
        return "new account"
    
    def get_playlists(self, pseudo):
        """
        retourne une liste de str le nom des playlists de l'utilisateur
        """
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT nom FROM Playlists JOIN Utilisateurs ON Utilisateurs.id = Playlists.id_utilisateur WHERE Utilisateurs.username == ?", (pseudo,))
        resultat = cursor.fetchall()
        cursor.close()
        database.close()

        liste_final = []
        for element in resultat:
            liste_final.append(element[0])
        
        return liste_final

    def create_playlist(self, pseudo, nom_playlist):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT id FROM Utilisateurs WHERE username == ?", (pseudo,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "resultat vide, problème car le pseudo est censé exister"
        id_pseudo = resultat[0][0]

        # test de si la playlist existe déjà
        cursor.execute("SELECT * FROM Playlists WHERE nom==? AND id_utilisateur==?", (nom_playlist, id_pseudo))
        resultat = cursor.fetchall()
        if len(resultat) > 0:
            # la playlist existe déjà
            cursor.close()
            database.close()
            return "existe deja"
        cursor.execute("INSERT INTO Playlists(nom, musiques, id_utilisateur) VALUES(?, '', ?)", (nom_playlist, id_pseudo))
        database.commit()
        cursor.close()
        database.close()
        return "ok"

    def delete_playlist(self, pseudo, nom_playlist):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        # récupération de l'id du pseudo
        cursor.execute("SELECT id FROM Utilisateurs WHERE username==?", (pseudo,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "pseudo non trouvé"
        id_pseudo = resultat[0][0]
        # pas besoin de vérification de présence
        cursor.execute("DELETE FROM Playlists WHERE nom==? and id_utilisateur==?", (nom_playlist, id_pseudo))
        database.commit()
        cursor.close()
        database.close()
        return "ok"

    def get_playlist_content(self, pseudo, nom_playlist):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT musiques FROM Playlists JOIN Utilisateurs ON Utilisateurs.id = Playlists.id_utilisateur WHERE Utilisateurs.username == ? AND Playlists.nom == ?", (pseudo, nom_playlist))
        resultat = cursor.fetchall()
        assert len(resultat) == 1, "problème : nombre d'enregistrements pas égal 1 : " + str(len(resultat))
        cursor.close()
        database.close()
        return self.transfo_liste(resultat[0][0])

    def get_music_infos(self, pseudo:str, musique:str):
        """
        retourne une liste de la forme [artiste, annee, album]
        """
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT artiste, annee, album FROM Musiques WHERE nom == ?", (musique,))
        resultat = cursor.fetchall()

        # peut crash si le nom de la musique a changé après la création de la playlist (qui se base sur les noms)
        assert len(resultat) == 1, "len(resultat) != 1 --> " + str(len(resultat))

        liste_finale = []
        for element in resultat[0]:
            liste_finale.append(element)
        cursor.close()
        database.close()
        return liste_finale

    def get_music_image(self, pseudo, nom_musique):
        """
        l'image stockée doit être sous format png
        """
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT image FROM Musiques WHERE nom==?", (nom_musique,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "résultat vide, pas normal"
        chemin_image = resultat[0][0]

        # ouverture du fichier en bytes
        assert chemin_image[len(chemin_image)-4:] == ".png", "les images doivent être sous format png"
        fichier = open(chemin_image, "rb")
        fichier_read = fichier.read()
        fichier.close()
        cursor.close()
        database.close()
        return fichier_read

    def handle(self):
        self.request.settimeout(20)

        # récupération des données envoyées par le client
        nb_bytes = ""
        data = None
        while not data == "a":  # a est le séparateur
            data = str(self.request.recv(1), "utf-8")
            if data == "":
                raise ConnectionError("le client n'a rien envoyé")
            elif not data == "a":
                nb_bytes = nb_bytes + data

        nb_bytes = int(nb_bytes)
        data = str(self.request.recv(nb_bytes), "utf-8")
        data = self.transfo_liste(data)

        type_data = data[0]
        data.pop(0)

        # test du type
        if type_data == "ask music":
            musique = self.get_music_envoi(data[0], data[1])
            self.request.sendall(musique)

        elif type_data == "connect":
            resultat = self.check_exist(data[0], data[1])
            self.send_message([resultat])

        elif type_data == "create account":
            self.create_account(data[0], data[1])
            self.send_message(["ok"])
        
        elif type_data == "get playlists names":
            playlists = self.get_playlists(data[0])
            self.send_message(playlists)    # playlists est une liste

        elif type_data == "create playlist":
            resultat = self.create_playlist(data[0], data[1])
            self.send_message([resultat])

        elif type_data == "delete playlist":
            resultat = self.delete_playlist(data[0], data[1])
            self.send_message([resultat])

        elif type_data == "get playlist content":
            resultat = self.get_playlist_content(data[0], data[1])  # renvoie une liste
            self.send_message(resultat)

        elif type_data == "get music infos":
            resultat = self.get_music_infos(data[0], data[1])   # renvoie une liste
            self.send_message(resultat)

        elif type_data == "ask music image":
            resultat = self.get_music_image(data[0], data[1])
            self.send_bytes(resultat)

print("que voulez-vous faire ?")
print("1 : créer nouvelle base de données")
print("2 : lancer serveur")
reponse = ""
while not reponse in ("1", "2"):
    reponse = input("réponse : ")
if reponse == "1":
    init_db()
elif reponse == "2":
    assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
    serveur = socketserver.TCPServer(("0.0.0.0", 25565), request_manager)
    serveur.request_queue_size = 50
    print("serveur lancé")
    serveur.serve_forever()