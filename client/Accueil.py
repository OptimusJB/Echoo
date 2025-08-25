from Screen import resize_screen
from ListPlaylistsView import playlist_manager
from PlayerView import player
from NotifManager import notif_manager
from RechercherBtn import rechercher_btn
from SettingsBtn import settings_btn
from KeyManager import key_manager
import sys
from InternalState import internal_state
from User import user
import pygame
pygame.init()

class Accueil:
    def __init__(self, game_state_manager):
        self.game_state = game_state_manager
        self.police = pygame.font.Font("assets/police.otf", 50)
        self.work_elements = [playlist_manager, player, rechercher_btn, settings_btn]

    def run(self):
        #print("accueil")
        # réinitialisation des différents composants de l'interface
        for element in self.work_elements:
            element.reset()

        internal_state.reset()

        clock = pygame.time.Clock()
        while True:
            # blit du fond
            resize_screen.fill(("grey10"))

            # blit des éléments de la page
            if internal_state.state_actuel.blit() == "crash":
                self.game_state.state_actuel = "Connexion"
                return None

            for element in self.work_elements:
                resultat = element.blit()
                if resultat == "crash":
                    self.game_state.state_actuel = "Connexion"
                    return None

            notif_manager.work()
            resize_screen.flip()
            clock.tick(user.fps)
            #print(clock.get_fps())
            
            for event in pygame.event.get():
                # récupération des potentielles touches pressées
                key_manager.work(event)

                # tous les listen entry (internal_state compris)
                if internal_state.state_actuel.listen_entry(event) == "crash":
                    self.game_state.state_actuel = "Connexion"
                    return None

                for element in self.work_elements:
                    resultat = element.listen_entry(event)
                    if resultat == "crash":
                        self.game_state.state_actuel = "Connexion"
                        return None

                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()