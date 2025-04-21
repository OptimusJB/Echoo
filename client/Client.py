import pygame
import socket
pygame.init()

class Client:
    def __init__(self):
        fichier = open("server ip.txt", "r")
        self.ip_serveur = fichier.read()
        fichier.close()

    def transfo_chaine(self, liste):
        chaine = ""
        for element in liste:
            chaine = chaine + str(element) + "&slchaine&"
        chaine = chaine[:len(chaine)-10]
        return chaine

    def transfo_liste(self, chaine:str):
        return chaine.split("&slchaine&")

    def send_message(self, liste:list): # liste de str
        texte = self.transfo_chaine(liste)
        texte = bytes(texte, "utf-8")
        texte = bytes(str(len(texte)) + "a", "utf-8") + texte

        requete = socket.socket()
        requete.settimeout(20)
        requete.connect((self.ip_serveur, 25565))
        requete.sendall(texte)

        nb_bytes = ""
        data = None
        while not data == "a":
            data = str(requete.recv(1), "utf-8")
            if data == "":
                raise ConnectionError("pas de réponse du serveur")
            if not data == "a":
                nb_bytes = nb_bytes + data

        data = requete.recv(int(nb_bytes))
        data = str(data, "utf-8")
        data = self.transfo_liste(data)
        return data

    def ask_music(self, nom_musique:str, qualite:str):
        """
        retourne sous forme de bytes la musique demandée (stockée sur le serveur)

        qualite = qualité à renvoyer
        = "max (320kbps)" ou "moyen ()" ou "min (160kbps)"
        """
        assert qualite in ["min", "moyen", "max"], "qualité invalide"
        requete = socket.socket()
        requete.settimeout(20)
        requete.connect((self.ip_serveur, 25565))

        texte = self.transfo_chaine(["ask music", str(nom_musique), str(qualite)])
        texte = bytes(texte, "utf-8")
        texte = bytes(str(len(texte)) + "a", "utf-8") + texte
        requete.sendall(texte)

        nb_bytes = ""
        data = None
        while not data == "a":
            data = str(requete.recv(1), "utf-8")
            if data == "":
                raise ConnectionError("pas de réponse du serveur")
            if not data == "a":
                nb_bytes = nb_bytes + data

        data = requete.recv(int(nb_bytes))
        return data

client = Client()
print(client.envoi("salut"))