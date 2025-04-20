import pygame
from Screen import resize_screen
from Connexion import Connexion

class State:
    def __init__(self):
        pygame.init()
        infos = pygame.display.Info()
        largeur = min([infos.current_w, 1920])
        hauteur = min([infos.current_h, 1080])
        resize_screen.set_mode((largeur, hauteur), pygame.RESIZABLE)
        self.state_actuel = "Connexion"
        self.states = {"Connexion":Connexion(self)}

    def run(self):
        while True:
            self.states[self.state_actuel].run()

state = State()
state.run()