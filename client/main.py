import pygame
from Screen import resize_screen
from Connexion import Connexion
from Accueil import Accueil

class State:
    def __init__(self):
        pygame.init()
        infos = pygame.display.Info()
        largeur = min([infos.current_w, 1240])
        hauteur = min([infos.current_h, 700])
        resize_screen.set_mode((largeur, hauteur), pygame.RESIZABLE)
        pygame.display.set_caption("Spoutoufy")
        pygame.display.set_icon(pygame.image.load("assets/Spoutoufy logo.png"))
        self.state_actuel = "Connexion"
        self.states = {"Connexion":Connexion(self),
                       "Accueil":Accueil(self)}

    def run(self):
        while True:
            self.states[self.state_actuel].run()

state = State()
state.run()