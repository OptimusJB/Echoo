import pygame
import socket
pygame.init()

class Client:
    def __init__(self):
        fichier = open("server ip.txt", "r")
        self.ip_serveur = fichier.read()
        fichier.close()

    def envoi(self, texte, send_buffer=False, receive_buffer=False):
        """
        buffer=True si l'élément à envoyer/recevoir est déjà en bytes
        """
        if not send_buffer:
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
                raise ConnectionError("le serveur a fermé la connexion")
            if not data == "a":
                nb_bytes = nb_bytes + data

        data = requete.recv(int(nb_bytes))
        if not receive_buffer:
            data = str(data, "utf-8")
        return data

client = Client()
print(client.envoi("salut"))