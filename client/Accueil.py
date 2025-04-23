from Screen import resize_screen
import pygame
pygame.init()
class Accueil:
    def __init__(self, game_state_manager):
        self.game_state = game_state_manager
        self.police = pygame.font.Font("assets/police.otf", 50)

    def run(self):
        print("accueil")

        clock = pygame.time.Clock()
        while True:
            clock.tick(30)
            pygame.event.get()