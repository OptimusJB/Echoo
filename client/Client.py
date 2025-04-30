import pygame
import os
from Screen import resize_screen
import socket
pygame.init()

class Client:
    """
    le contenu de server ip.txt doit être de la forme 'ip:port'
    """
    def __init__(self):
        if not "server ip.txt" in os.listdir():
            self.reset_server_ip_file()
        fichier = open("server ip.txt", "r")
        fichier_read = fichier.read().rstrip().split(":")
        self.ip_serveur = fichier_read[0]
        self.port_serveur = int(fichier_read[1])
        fichier.close()
        self.police = pygame.font.Font("assets/police.otf", 20)

    def reset_server_ip_file(self):
        fichier = open("server ip.txt", "w")
        fichier.write("0.0.0.0:25565")
        fichier.close()

    def change_ip(self, ip:str, port:int):
        self.ip_serveur = str(ip)
        self.port_serveur = int(port)


    def get_ip(self):
        return (self.ip_serveur, self.port_serveur)

    def texte_fond(self, texte:str):
        texte = pygame.font.Font("assets/police.otf", 20).render(texte, True, "white")
        texte_rect = texte.get_rect()
        texte_rect.centerx = 1920//2
        texte_rect.bottom = 1080
        full_rect = texte_rect.copy()
        full_rect.width = 1920
        full_rect.x = 0
        resize_screen.draw_rect("grey15", full_rect)
        resize_screen.blit(texte, texte_rect.topleft)

    def crash(self):
        pygame.event.get()  # retrait du "ne répond pas" pour que flip marche
        self.texte_fond("échec de la connexion au serveur, retour au menu")
        resize_screen.flip()
        pygame.event.get()
        pygame.time.wait(3000)
        pygame.event.get()
        return "crash"

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

    def send_message(self, liste:list): # liste de str
        assert type(liste) == list, "pas une liste"
        self.texte_fond("communication avec le serveur en cours...")
        resize_screen.flip()
        requete = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        texte = self.transfo_chaine(liste)
        assert not "#" in texte, "# interdit"
        texte = bytes(texte + "#", "utf-8")

        try:


            requete.settimeout(20)
            requete.connect((self.ip_serveur, self.port_serveur))
            requete.sendall(texte)

            data = ""
            reception = "truc"
            while reception:
                pygame.event.get()
                reception = requete.recv(65536)
                data = data + str(reception, "utf-8")
            data = self.transfo_liste(data)
            requete.close()
            return data
        except:
            self.crash()
            requete.close()
            return "crash"

    def ask_music(self, pseudo:str, nom_musique:str, qualite:str):
        """
        retourne sous forme de bytes la musique demandée (stockée sur le serveur)

        qualite = qualité à renvoyer
        = "max (320kbps)" ou "moyen ()" ou "min (160kbps)"
        """
        assert qualite in ["min", "moyen", "max"], "qualité invalide"
        self.texte_fond("communication avec le serveur en cours...")
        resize_screen.flip()
        requete = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        try:
            requete.settimeout(20)
            requete.connect((self.ip_serveur, self.port_serveur))

            texte = self.transfo_chaine(["ask music", str(pseudo), str(nom_musique), str(qualite)])
            assert not "#" in texte, "# interdit"
            texte = bytes(texte + "#", "utf-8")
            #texte = bytes(str(len(texte)) + "a", "utf-8") + texte
            requete.sendall(texte)

            data = bytes("", "utf-8")
            reception = "truc"
            while reception:
                pygame.event.get()
                reception = requete.recv(65536)
                data = data + reception
            requete.close()
            return data
        except Exception as error:
            self.crash()
            requete.close()
            print(error)
            return "crash"

    def ask_music_image(self, pseudo:str, nom_musique:str):
        """
        retourne sous forme de bytes l'image de la musique demandée (stockée sur le serveur)
        """
        self.texte_fond("communication avec le serveur en cours...")
        resize_screen.flip()
        requete = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        try:
            requete.settimeout(20)
            requete.connect((self.ip_serveur, self.port_serveur))

            texte = self.transfo_chaine(["ask music image", str(pseudo), str(nom_musique)])
            assert not "#" in texte, "# interdit"
            texte = bytes(texte + "#", "utf-8")
            #texte = bytes(str(len(texte)) + "a", "utf-8") + texte
            requete.sendall(texte)
            data = bytes("", "utf-8")
            reception = "truc"
            while reception:
                pygame.event.get()
                reception = requete.recv(65536)
                data = data + reception
            requete.close()
            return data
        except Exception as error:
            print(error)
            self.crash()
            requete.close()
            return "crash"

client = Client()