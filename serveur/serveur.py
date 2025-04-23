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
        cursor.execute("CREATE TABLE Musiques(id INTEGER, nom TEXT, genre TEXT, annee INTEGER, artiste TEXT, album TEXT, image TEXT, min TEXT, moyen TEXT, max TEXT, PRIMARY KEY (id AUTOINCREMENT))")
        #cursor.execute("INSERT INTO Utilisateurs(username, password) VALUES('jb', 'jb123')")
        database.commit()
        #cursor.execute("SELECT username FROM Utilisateurs")
        database.close()

class request_manager(socketserver.BaseRequestHandler):

    def send_message(self, liste:list):
        assert type(liste) == list, "pas une liste"
        texte = self.transfo_chaine(liste)
        texte = bytes(texte, "utf-8")
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
        database.close()
        print("nouvel utilisateur : " + pseudo)

    def transfo_chaine(self, liste):
        chaine = ""
        for element in liste:
            chaine = chaine + str(element) + "&slchaine&"
        chaine = chaine[:len(chaine)-10]
        return chaine

    def transfo_liste(self, chaine:str):
        if chaine == "":
            return []
        return chaine.split("&slchaine&")

    def check_exist(self, pseudo, password):
        """
        retourne True si le compte existe dans la base de données, False sinon
        """
        assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT password FROM Utilisateurs WHERE username==?", (pseudo,))
        resultat = cursor.fetchall()
        database.close()

        assert not len(resultat) > 1, "trop d'enregistrements trouvés (normalement il y en a qu'un)"
        if len(resultat) == 1:
            if resultat[0][0] == password:
                # connexion réussie
                return "oui"
            else:
                return "non"
        return "new account"

    
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


print("que voulez-vous faire ?")
print("1 : créer nouvelle base de données")
print("2 : lancer serveur")
reponse = ""
while not reponse in ("1", "2"):
    reponse = input("réponse : ")
if reponse == "1":
    init_db()
elif reponse == "2":
    serveur = socketserver.TCPServer(("0.0.0.0", 25565), request_manager)
    serveur.request_queue_size = 50
    print("serveur lancé")
    serveur.serve_forever()