import os
import pygame
pygame.init()

class User:
    def remove_cache(self):
        for element in os.listdir("cache/"):
            os.remove("cache/" + element)

    def save_settings(self):
        fichier = open("settings.txt", "w")
        fichier.write(str(int(self.load_images)) + "\n" + self.quality + "\n" + str(self.volume))
        fichier.close()

    def __init__(self):
        # génération des settings
        if not "settings.txt" in os.listdir():
            fichier = open("settings.txt", "w")
            fichier.write("1\nmax\n1.0")
            fichier.close()

        # ouverture fichier
        fichier = open("settings.txt", "r")
        fichier_read = fichier.read()
        fichier.close()
        fichier_read = fichier_read.split("\n")

        self.load_images = bool(int(fichier_read[0]))
        self.quality = fichier_read[1]
        self.volume = float(fichier_read[2])
        pygame.mixer.music.set_volume(self.volume)
        assert self.quality in ["min", "moyen", "max"], "qualité invalide"

        self.username = None
        self.password = None

user = User()