import pygame
from Screen import resize_screen
# on met en place le screen avant les imports (pour les .convert())
pygame.init()
pygame.display.set_caption("Spoutoufy")
pygame.display.set_icon(pygame.transform.smoothscale(pygame.image.load("assets/Spoutoufy logo.png"), (32, 32)))

infos = pygame.display.Info()
largeur = min([infos.current_w, 1920])*0.6
hauteur = min([infos.current_h, 1080])*0.6
resize_screen.set_mode((largeur, hauteur), pygame.RESIZABLE)

from Connexion import Connexion
from Accueil import Accueil
import os
from User import user

class State:
    def __init__(self):
        # suppression du cache
        if not "cache" in os.listdir():
            os.mkdir("cache")
            print("dossier cache créé")
        user.remove_cache()

        self.state_actuel = "Connexion"
        self.states = {"Connexion":Connexion(self),
                       "Accueil":Accueil(self)}

    def run(self):
        while True:
            self.states[self.state_actuel].run()

state = State()
state.run()