import socketserver
import os
import sqlite3
import pygame
pygame.init()

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
        cursor.execute("CREATE TABLE Musiques(nom TEXT, genre TEXT, annee INTEGER, artiste TEXT, album TEXT, position_album INTEGER, image TEXT, min TEXT, moyen TEXT, max TEXT, PRIMARY KEY (nom))")
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
        self.request.sendall(texte)

    def send_bytes(self, message):
        """
        message peut être sous forme de bytes ou sous forme de liste de bytes
        """
        texte = message
        if type(message) == list:
            texte = bytes("&slchaine&", "utf-8").join(message)
        #texte = bytes(str(len(texte)) + "a", "utf-8") + texte
        self.request.sendall(texte)

    def get_music_envoi(self, pseudo, musique, qualite="max"):
        """
        qualite = qualité à renvoyer
        = "max (320kbps)" ou "moyen ()" ou "min (160kbps)"
        retourne la musique sous forme de bytes
        les musiques doivent être sous forme de mp3
        """
        assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT " + qualite + " FROM Musiques WHERE nom == ?", (musique,))
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
        if chaine == "":
            chaine = "rien"
        return chaine

    def transfo_liste(self, chaine:str, separateur="&slchaine&"):
        if chaine == "rien" or chaine == "":
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
        assert len(resultat) == 1, "problème : nombre d'enregistrements pas égal à 1 : " + str(len(resultat))
        cursor.close()
        database.close()
        return self.transfo_liste(resultat[0][0])

    def get_playlist_content_via_album(self, pseudo, nom_playlist):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT nom FROM Musiques WHERE album == ? ORDER BY position_album ASC", (nom_playlist,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "longueur résultat inférieur à 1, pas normal"
        cursor.close()
        database.close()

        liste_finale = []
        for element in resultat:
            liste_finale.append(element[0])
        return liste_finale

    def opti_get_playlist_content(self, pseudo, recherche, fonction_recherche):
        # ça envoie directement toutes les infos en une seule requête
        liste_musiques = fonction_recherche(pseudo, recherche)
        liste_infos = []
        for musique in liste_musiques:
            liste_infos.append("&slinfo&".join([musique] + self.get_music_infos(pseudo, musique) + [("'" + self.get_cover_name(pseudo, musique) + "'").replace("/", "&sl&")]))

        return liste_infos

    def get_playlist_content_via_recherche(self, pseudo, recherche_joueur):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        # LIKE est insensible à la casse (on s'en fout des majuscules)
        cursor.execute("SELECT nom FROM Musiques WHERE nom LIKE ? OR album LIKE ?", ("%" + recherche_joueur + "%", "%" + recherche_joueur + "%"))
        resultat = cursor.fetchall()

        liste_musiques = []
        for element in resultat:
            liste_musiques.append(element[0])
        cursor.close()
        database.close()
        return liste_musiques

    def get_music_infos(self, pseudo:str, musique:str, date_str=False):
        """
        retourne une liste de la forme [artiste, annee, album]
        date_str : si True, retourne la date en str, en int sinon
        """
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT artiste, annee, album FROM Musiques WHERE nom == ?", (musique,))
        resultat = cursor.fetchall()

        # peut crash si le nom de la musique a changé après la création de la playlist (qui se base sur les noms)
        assert len(resultat) == 1, "len(resultat) != 1 --> " + str(len(resultat)) + ", musique " + musique + ", la musique a peut-être été supprimée"

        liste_finale = []
        for element in resultat[0]:
            liste_finale.append(element)
        liste_finale[1] = str(liste_finale[1])
        cursor.close()
        database.close()
        return liste_finale

    def get_images_opti(self, pseudo, images):
        # attention les images ont des ' ' et des &sl& donc il faut les convertir
        images_convert = []
        for chemin_image in images:
            images_convert.append(chemin_image[1:len(chemin_image)-1].replace("&sl&", "/"))

        liste_images = []
        for chemin_image in images_convert:
            assert chemin_image[len(chemin_image) - 4:] == ".png", "les images doivent être sous format png"
            fichier = open(chemin_image, "rb")
            fichier_read = fichier.read()
            fichier.close()
            liste_images.append(fichier_read)
        return liste_images

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

    def check_quality(self, pseudo, musique, quality):
        # création dico
        dico_quality = {"min":0, "moyen":1, "max":2}
        dico_index = {0:"min", 1:"moyen", 2:"max"}
        assert quality in dico_quality.keys(), "qualité invalide : " + str(quality)

        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT min, moyen, max FROM Musiques WHERE nom == ?", (musique,))
        resultat = cursor.fetchall()
        qualites = [resultat[0][0], resultat[0][1], resultat[0][2]]
        index_quality = dico_quality[quality]

        quality_final = "None"
        boucle = True
        while boucle:
            if index_quality == -1:
                boucle = False
            elif index_quality == 0 and not qualites[index_quality] == "?":
                quality_final = dico_index[index_quality]
                boucle = False
            elif index_quality == 1 and not qualites[index_quality] == "?":
                quality_final = dico_index[index_quality]
                boucle = False
            elif index_quality == 2 and not qualites[index_quality] == "?":
                quality_final = dico_index[index_quality]
                boucle = False
            index_quality -= 1
        cursor.close()
        database.close()
        return quality_final

    def insert_to_playlist(self, pseudo, nom_playlist, nom_musique):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        # on récupère la playlist
        playlist = self.get_playlist_content(pseudo, nom_playlist)
        playlist.append(nom_musique)
        playlist_txt = self.transfo_chaine(playlist)

        # récupération de l'id du pseudo
        cursor.execute("SELECT id FROM Utilisateurs WHERE username==?", (pseudo,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "pseudo non trouvé"
        id_pseudo = resultat[0][0]

        cursor.execute("UPDATE Playlists SET musiques=? WHERE nom==? AND id_utilisateur==?",(playlist_txt, nom_playlist, id_pseudo))
        database.commit()
        cursor.close()
        database.close()

    def delete_from_playlist(self, pseudo, nom_playlist, index_musique):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()

        # on récupère la playlist
        playlist = self.get_playlist_content(pseudo, nom_playlist)
        playlist.pop(index_musique)
        playlist_txt = self.transfo_chaine(playlist)

        # récupération de l'id du pseudo
        cursor.execute("SELECT id FROM Utilisateurs WHERE username==?", (pseudo,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "pseudo non trouvé"
        id_pseudo = resultat[0][0]

        cursor.execute("UPDATE Playlists SET musiques=? WHERE nom==? AND id_utilisateur==?",(playlist_txt, nom_playlist, id_pseudo))

        database.commit()
        cursor.close()
        database.close()

    def deplacement(self, pseudo, nom_playlist, index_musique1, index_musique2):
        # c'est pas un échange, c'est la musique 1 qui va au dessus de la musique 2
        database = sqlite3.connect("data.db")
        cursor = database.cursor()

        # on récupère la playlist
        playlist = self.get_playlist_content(pseudo, nom_playlist)
        musique = playlist.pop(index_musique1)
        playlist.insert(index_musique2, musique)
        playlist_txt = self.transfo_chaine(playlist)

        # récupération de l'id du pseudo
        cursor.execute("SELECT id FROM Utilisateurs WHERE username==?", (pseudo,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "pseudo non trouvé"
        id_pseudo = resultat[0][0]

        cursor.execute("UPDATE Playlists SET musiques=? WHERE nom==? AND id_utilisateur==?",(playlist_txt, nom_playlist, id_pseudo))

        database.commit()
        cursor.close()
        database.close()

    def get_artistes(self, pseudo, recherche_joueur):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT DISTINCT artiste FROM Musiques WHERE artiste LIKE ?", ("%" + recherche_joueur + "%",))
        resultat = cursor.fetchall()

        liste = []
        for element in resultat:
            liste.append(element[0])
        cursor.close()
        database.close()
        return liste

    def get_playlists_of_artiste(self, pseudo, artiste):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT DISTINCT album FROM Musiques WHERE artiste == ?", (artiste,))
        resultat = cursor.fetchall()

        liste = []
        for element in resultat:
            liste.append(element[0])
        cursor.close()
        database.close()
        return liste

    def get_cover_name(self, pseudo, musique):
        database = sqlite3.connect("data.db")
        cursor = database.cursor()
        cursor.execute("SELECT image FROM Musiques WHERE nom == ?", (musique,))
        resultat = cursor.fetchall()
        assert len(resultat) > 0, "pas de résultat trouvé"
        cursor.close()
        database.close()
        return resultat[0][0]

    def shutdown_server(self):
        self.server.shutdown()

    def handle(self):
        self.request.settimeout(20)

        # récupération des données envoyées par le client
        data = ""
        reception = "truc"
        while not "#fin du message" in data:  # le client ne ferme pas le socket afin de recevoir une réponse
            reception = self.request.recv(1024)
            data = data + str(reception, "utf-8")

        data = data.replace("#fin du message", "")
        if data == "":
            print("le client a fermé la connexion")
            return None
        data = self.transfo_liste(data)

        type_data = data[0]
        data.pop(0)

        # test du type
        if type_data == "ask music":
            musique = self.get_music_envoi(data[0], data[1], data[2])
            self.send_bytes(musique)

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

        elif type_data == "get playlist content opti":
            resultat = self.opti_get_playlist_content(data[0], data[1], self.get_playlist_content)
            self.send_message(resultat)

        elif type_data == "get playlist content via album":
            resultat = self.get_playlist_content_via_album(data[0], data[1])    # renvoie une liste
            self.send_message(resultat)

        elif type_data == "get playlist content via album opti":
            resultat = self.opti_get_playlist_content(data[0], data[1], self.get_playlist_content_via_album)
            self.send_message(resultat)

        elif type_data == "get music infos":
            resultat = self.get_music_infos(data[0], data[1])   # renvoie une liste
            self.send_message(resultat)

        elif type_data == "ask music image":
            resultat = self.get_music_image(data[0], data[1])
            self.send_bytes(resultat)

        elif type_data == "get images opti":
            resultat = self.get_images_opti(data[0], data[1:])
            self.send_bytes(resultat)

        elif type_data == "check quality":
            resultat = self.check_quality(data[0], data[1], data[2])
            self.send_message([resultat])

        elif type_data == "insert to playlist":
            resultat = self.insert_to_playlist(data[0], data[1], data[2])
            self.send_message(["ok"])

        elif type_data == "delete from playlist":
            resultat = self.delete_from_playlist(data[0], data[1], int(data[2]))
            self.send_message(["ok"])

        elif type_data == "deplacement":
            resultat = self.deplacement(data[0], data[1], int(data[2]), int(data[3]))
            self.send_message(["ok"])
        
        elif type_data == "get musics with":
            resultat = self.get_playlist_content_via_recherche(data[0], data[1])    # retourne une liste
            self.send_message(resultat)

        elif type_data == "get musics with opti":
            resultat = self.opti_get_playlist_content(data[0], data[1], self.get_playlist_content_via_recherche)
            self.send_message(resultat)

        elif type_data == "get artistes":
            resultat = self.get_artistes(data[0], data[1])  # retourne une liste
            self.send_message(resultat)

        elif type_data == "get playlists of artiste":
            resultat = self.get_playlists_of_artiste(data[0], data[1])  # retourne une liste
            self.send_message(resultat)

        elif type_data == "get cover name":
            resultat = self.get_cover_name(data[0], data[1]) # retourne un str
            self.send_message([resultat])

        elif type_data == "stop server":
            if self.client_address[0] == "127.0.0.1":
                print("demande d'arrêt reçu, arrêt du serveur...")
                import threading
                threading.Thread(target=self.shutdown_server).start()
                self.send_message(["ok"])

def player_input(texte, type_attendu, reponse_attendue=None):
    if reponse_attendue == None:
        reponse_attendue = []
    reponse = None
    while not reponse in reponse_attendue:
        print(texte)
        try:
            reponse = type_attendu(input("réponse : "))
        except KeyboardInterrupt:
            raise KeyboardInterrupt
        except:
            print("réponse incorrecte")
            continue

        if len(reponse_attendue) == 0:
            reponse_attendue.append(reponse)
    return reponse

def ajouter_musique():
    musique = []    # différentes infos de la musique
    database = sqlite3.connect("data.db")
    cursor = database.cursor()

    # nom
    boucle = True
    while boucle:
        nom = player_input("nom de la musique", str, [])

        # vérification que le nom de la musique n'est pas déjà utilisée
        cursor.execute("SELECT * FROM Musiques WHERE nom==?", (nom,))
        resultat = cursor.fetchall()
        if len(resultat) > 0:
            print("le nom est déjà utilisé")
        else:
            boucle = False
    musique.append(nom)

    # genre
    genre = player_input("genre de la musique", str, [])
    musique.append(genre)

    # année
    annee = player_input("année de la musique", int, [])
    musique.append(annee)

    # artiste
    artiste = player_input("nom de l'artiste", str, [])
    musique.append(artiste)

    # album
    album = player_input("album de la musique", str, [])
    musique.append(album)

    # position album
    position_album = player_input(f"position de la musique dans l'album '{album}'", int, [])
    musique.append(position_album)

    # image
    boucle = True
    while boucle:
        image = player_input("chemin de l'image", str, [])

        # on test si l'image est ouvrable et dans le bon format
        if image[len(image) - 4:] == ".png":
            if not "cache.png" in image:   # noms interdits
                try:
                    test = pygame.image.load(image)
                    boucle = False
                except:
                    print("le fichier ne semble ne pas fonctionner ou ne pas exister")
            else:
                print("nom interdit")
        else:
            print("l'image doit être sous format png")
    musique.append(image)

    # qualités
    for qualite in ["minimum", "moyenne", "maximale"]:
        boucle = True
        while boucle:
            chemin_musique = player_input(f"chemin du fichier audio pour la qualité {qualite} (mettre ? pour ne rien mettre)", str, [])
            if chemin_musique == "?":
                boucle = False
            else:
                if chemin_musique[len(chemin_musique) - 4:] == ".ogg":
                    if not "cache.ogg" in chemin_musique:  # noms interdits
                        try:
                            pygame.mixer.music.load(chemin_musique)
                            boucle = False
                        except:
                            print("le fichier semble pas fonctionner ou ne pas exister")
                    else:
                        print("nom interdit")
                else:
                    print("l'audio doit être sous format ogg")
        musique.append(chemin_musique)

    # ajout de la musique
    cursor.execute("INSERT INTO Musiques VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", tuple(musique))

    database.commit()
    cursor.close()
    database.close()
    print("musique ajoutée")

def transfo_chaine(liste, separateur="&slchaine&"):
    chaine = ""
    for element in liste:
        chaine = chaine + str(element) + separateur
    chaine = chaine[:len(chaine)-len(separateur)]
    if chaine == "":
        chaine = "rien"
    return chaine

def transfo_liste(chaine:str, separateur="&slchaine&"):
    if chaine == "rien" or chaine == "":
        return []
    return chaine.split(separateur)

def suppression_des_playlists(musique_a_supprimer):
    """
    supprime de l'ensemble des playlists la musique passée en paramètre
    """
    database = sqlite3.connect("data.db")
    cursor = database.cursor()

    cursor.execute("SELECT id, musiques FROM Playlists")
    resultat = cursor.fetchall()
    for element in resultat:
        id_playlist = element[0]
        liste_musiques = transfo_liste(element[1])

        # vérification de la présence de la musique à supprimer
        if musique_a_supprimer in liste_musiques:
            liste_musiques.remove(musique_a_supprimer)
            # mise à jour de la table
            cursor.execute("UPDATE Playlists SET musiques = ? WHERE id==?", (transfo_chaine(liste_musiques), id_playlist))

    database.commit()
    cursor.close()
    database.close()

def supprimer_musique():
    print("notez que la suppression d'une musique entrainera le non fonctionnement des playlists où était la musique (le serveur va crash en disant qu'il y a 0 résultat)")
    database = sqlite3.connect("data.db")
    cursor = database.cursor()

    boucle = True
    while boucle:
        musique_a_supprimer = player_input("musique a supprimer", str, [])

        # vérification que la musique existe
        cursor.execute("SELECT * FROM Musiques WHERE nom==?", (musique_a_supprimer,))
        resultat = cursor.fetchall()
        if len(resultat) == 0:
            print("cette musique n'existe pas")
        else:
            boucle = False

    # suppression de la musique
    cursor.execute("DELETE FROM Musiques WHERE nom==?", (musique_a_supprimer,))

    database.commit()
    cursor.close()
    database.close()
    print("musique supprimée")
    
    # suppression de la musique dans les playlists
    texte = """supprimer la musique des playlists pour éviter les problèmes ?
1 : oui
2 : non"""
    resultat = player_input(texte, int, (1, 2))
    if resultat == 1:
        suppression_des_playlists(musique_a_supprimer)
        print("la musique a été supprimée des playlists")

def get_open_value(chemin_fichier):
    if not chemin_fichier[len(chemin_fichier)-4:] == ".png":
        fichier = open(chemin_fichier, "r")
        fichier_read = fichier.read()
        fichier.close()
        return fichier_read
    else:
        return chemin_fichier

def ajout_multiple():
    texte = """
entrez le chemin du dossier où se trouvent les musiques en .ogg
des fichiers nommés artiste.txt, annee.txt, album.txt, genre.txt, cover.png doivent être présents dans le dossier"""
    chemin_musiques = player_input(texte, str, [])
    if chemin_musiques[len(chemin_musiques) - 1] != "/":
        print("le chemin doit se terminer par un /")
        ajout_multiple()
        return None

    liste_musiques = []
    requis = {"artiste.txt":False, "annee.txt":False, "album.txt":False, "cover.png":False, "genre.txt":False}
    for fichier in sorted(os.listdir(chemin_musiques)): # les noms sont triés
        if fichier in requis.keys():
            if not requis[fichier] == False:
                print("il y a plusieurs fichiers nommés " + fichier)
                return None
            requis[fichier] = get_open_value(chemin_musiques + fichier)

        else:
            # test ogg
            if not fichier[len(fichier)-4:] == ".ogg":
                print("le fichier " + fichier + " n'est pas valide")
                return None

            # test nom interdit
            if fichier == "cache.ogg":
                print("cache.ogg est un nom interdit")
                return None

            liste_musiques.append(fichier)
    if False in requis.values():
        print("il manque un fichier")
        return None

    # nb caractères à enlever à chaque nom de musique
    nb_prefix_remove = abs(player_input("nombre de caractères à enlever au début", int))

    texte = """
qualité des musiques :
1 : min
2 : moyen
3 : max"""
    qualite = player_input(texte, int, [1, 2, 3])
    print("ajout des musiques en cours...")
    database = sqlite3.connect("data.db")
    cursor = database.cursor()

    position_album = 1
    for element in liste_musiques:  # pas le chemin complet

        # changement du nom
        nom_musique = element[nb_prefix_remove:]    # pas de crash, même si nb_prefix_remove est au dessus de l'index max
        nom_musique = nom_musique[:len(nom_musique)-4]

        # vérification que le nom de la musique n'est pas déjà utilisée
        cursor.execute("SELECT * FROM Musiques WHERE nom==?", (nom_musique,))
        resultat = cursor.fetchall()
        if len(resultat) > 0:
            print(str(nom_musique) + " est déjà présent dans la base de données, skip")
            continue

        liste_qualite = ("?",) * (qualite - 1) + (chemin_musiques + element,) + ("?",) * (2 - (qualite - 1))
        cursor.execute("INSERT INTO Musiques VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", (nom_musique, requis["genre.txt"], requis["annee.txt"], requis["artiste.txt"], requis["album.txt"], position_album, requis["cover.png"]) + liste_qualite)
        position_album += 1
    database.commit()
    cursor.close()
    database.close()
    print("ajout terminé")

def data_gestion():
    texte = """
1 : ajouter musique
2 : supprimer musique
3 : ajout multiple"""
    resultat = player_input(texte, int, (1, 2, 3))
    if resultat == 1:
        ajouter_musique()
    elif resultat == 2:
        supprimer_musique()
    elif resultat == 3:
        ajout_multiple()

print("que voulez-vous faire ?")
print("1 : créer nouvelle base de données")
print("2 : gestion base de données")
print("3 : lancer serveur ")
reponse = ""
while not reponse in ("1", "2", "3"):
    reponse = input("réponse : ")
if reponse == "1":
    init_db()

elif reponse == "3":
    assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
    serveur = socketserver.TCPServer(("0.0.0.0", 25565), request_manager)
    serveur.request_queue_size = 50
    print("serveur lancé")
    serveur.serve_forever()
    serveur.server_close()
    print("serveur arrêté")

elif reponse == "2":
    assert "data.db" in os.listdir(), "la base de donnée n'existe pas, créez là avec init_db()"
    data_gestion()

input("appuyez sur entrée pour terminer le programme")

# cache.png et cache.ogg --> nom interdit