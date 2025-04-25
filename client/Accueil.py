from Screen import resize_screen
from ListPlaylistsView import playlist_manager
from PlayerView import player
from NotifManager import notif_manager
import sys
import pygame
pygame.init()

class InternalState:
    def __init__(self):
        self.state_actuel = "Rechercher"
        self.states = {}

internal_state = InternalState()

class Accueil:
    def __init__(self, game_state_manager):
        self.game_state = game_state_manager
        self.police = pygame.font.Font("assets/police.otf", 50)
        self.work_elements = [playlist_manager, player]

    def run(self):
        print("accueil")
        # réinitialisation des différents composants de l'interface
        for element in self.work_elements:
            element.reset()

        clock = pygame.time.Clock()
        while True:
            # blit du fond
            resize_screen.fill(("grey10"))

            # blit des éléments de la page
            for element in self.work_elements:
                element.blit()

            notif_manager.work()
            resize_screen.flip()
            clock.tick(30)
            
            for event in pygame.event.get():
                for element in self.work_elements:
                    resultat = element.listen_entry(event)
                    if resultat == "crash":
                        self.game_state.state_actuel = "Connexion"
                        return None

                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()