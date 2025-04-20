import socketserver
import os

class request_manager(socketserver.BaseRequestHandler):

    def get_music_envoi(self, musique, qualite="max"):
        """
        qualite = qualité à renvoyer
        = "max (320kbps)" ou "moyen ()" ou "min (160kbps)"
        retourne la musique sous forme de bytes
        les musiques doivent être sous forme de mp3
        """
        liste_musiques = os.listdir("musics/")
        assert musique in liste_musiques, "la musique demandée n'existe pas"

        fichier = open("assets/" + musique + "-" + qualite + ".mp3", "rb")
        resultat = fichier.read()
        fichier.close()
        return resultat
    
    def handle(self):
        self.request.settimeout(20)

        # récupération des données envoyées par le client
        nb_bytes = ""
        data = None
        while not data == "a":  # a est le séparateur
            data = str(self.request.recv(1), "utf-8")
            if data == "":
                break
            elif not data == "a":
                nb_bytes = nb_bytes + data


serveur = socketserver.TCPServer(("0.0.0.0", 25565), request_manager)
serveur.request_queue_size = 50
print("serveur lancé")
serveur.serve_forever()