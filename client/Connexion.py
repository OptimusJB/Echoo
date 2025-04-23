import pygame
import sys
from TextZone import TextZone
from Screen import resize_screen
from Client import client
from NotifManager import notif_manager
import User
from Tick import Tick
pygame.init()
class Connexion:
    def __init__(self, game_state_manager):
        self.game_state = game_state_manager
        self.police = pygame.font.Font("assets/police.otf", 50)

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

    def run(self):
        # mise en place de l'écran de connexion
        #fond = pygame.transform.smoothscale(pygame.image.load("assets/fond_connexion.png").convert(), (1920, 1080))
        resize_screen.draw_rect("gray25", pygame.rect.Rect(0, 0, 1920, 1080))

        fond_connexion = pygame.surface.Surface((800,600), pygame.SRCALPHA)
        pygame.draw.rect(fond_connexion, "grey15", pygame.rect.Rect(0, 0, 800, 600), border_radius=50)
        resize_screen.blit(fond_connexion, (1920//2-400, 1080//2-300))

        fond_email = pygame.surface.Surface((700, 100), pygame.SRCALPHA)
        pygame.draw.rect(fond_email, "grey50", pygame.rect.Rect(0, 0, 700, 100), border_radius=20)
        resize_screen.blit(fond_email, (1920//2-350, 1080//2-250))
        username_image = pygame.image.load("assets/username_image.png").convert_alpha()
        username_image = pygame.transform.smoothscale_by(username_image, 0.12)
        resize_screen.blit(username_image, (1920//2-350+5, 1080//2-250 + 10))

        fond_mdp = fond_email
        resize_screen.blit(fond_mdp, (1920 // 2 - 350, 1080 // 2 - 120))
        password_image = pygame.image.load("assets/password_image.png").convert_alpha()
        password_image = pygame.transform.smoothscale_by(password_image, 0.15)
        resize_screen.blit(password_image, (1920 // 2 - 350 + 10, 1080 // 2 - 120 + 10))

        fond_login = pygame.surface.Surface((700, 100), pygame.SRCALPHA)
        rect_login = pygame.rect.Rect(0, 0, 700, 100)
        pygame.draw.rect(fond_login, "dodgerblue3", rect_login, border_radius=20)
        rect_login.topleft = (1920 // 2 - 350, 1080 // 2 + 100)
        resize_screen.blit(fond_login, rect_login.topleft)

        login_message = self.police.render("se connecter au serveur", True, "white")
        resize_screen.blit(login_message, (1920//2 - 350 + 40, 1080//2 + 100 + 20))

        # définition texte zone
        username = TextZone(self.police)
        username.set_rect(pygame.rect.Rect(1920//2-350+5, 1080//2-250 + 10, 700, 100))
        username.set_largeur_max(580)

        password = TextZone(self.police)
        password.set_rect(pygame.rect.Rect(1920 // 2 - 350 + 10, 1080 // 2 - 120 + 10, 700, 100))
        password.set_largeur_max(900)
        password.hide_text()

        resize_screen.save_screen("fond connexion")
        tick = Tick()
        clock = pygame.time.Clock()
        while True:
            resize_screen.load_screen("fond connexion")
            resize_screen.blit(username.get_image(), (1920//2-350+100, 1080//2-250 + 15))
            resize_screen.blit(password.get_image(), (1920//2-350+100, 1080//2-120+15))

            notif_manager.work()

            resize_screen.flip()
            can_connect = tick.wait_during(30*5, "cooldown connexion")

            clock.tick(30)

            for event in pygame.event.get():
                username.work(event)
                password.work(event)
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()

                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        if rect_login.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)) and not username.est_vide() and not password.est_vide():
                            if can_connect:
                                resize_screen.save_screen("avant demande compte")
                                self.texte_fond("communication avec le serveur en cours...")
                                resize_screen.flip()
                                resultat = client.send_message(["connect", username.get_text(), password.get_text()]) # pas besoin de changement de page

                                # test résultat commande
                                if resultat != None:
                                    if resultat[0] == "new account":
                                        # génération fond
                                        resize_screen.load_screen("avant demande compte")
                                        resize_screen.draw_rect("grey15", pygame.rect.Rect((1920//2-400, 1080//2-300, 800, 600)), 50)

                                        # génération boutons et leur rect
                                        valider_btn_rect = pygame.rect.Rect(700, 600, 200, 100)
                                        retour_btn_rect = pygame.rect.Rect(1000, 600, 200, 100)
                                        resize_screen.draw_rect("dodgerblue3", valider_btn_rect, 20)
                                        resize_screen.draw_rect("dodgerblue3", retour_btn_rect, 20)

                                        # génération texte
                                        texte = self.police.render("Ce nom d'utilisateur n'existe pas.", True, "white")
                                        texte2 = self.police.render("Créer un compte ?", True, "white")
                                        texte = pygame.transform.smoothscale_by(texte, 0.8)
                                        texte2 = pygame.transform.smoothscale_by(texte2, 0.8)
                                        resize_screen.blit(texte, (625, 300))
                                        resize_screen.blit(texte2, (780, 400))

                                        texte = self.police.render("oui", True, "white")
                                        texte_rect = texte.get_rect()
                                        texte_rect.center = valider_btn_rect.center
                                        resize_screen.blit(texte, texte_rect.topleft)

                                        texte = self.police.render("non", True, "white")
                                        texte_rect = texte.get_rect()
                                        texte_rect.center = retour_btn_rect.center
                                        resize_screen.blit(texte, texte_rect.topleft)

                                        resize_screen.flip()

                                        clock_demande = pygame.time.Clock()
                                        boucle_demande = True
                                        while boucle_demande:
                                            clock_demande.tick(30)

                                            for event_demande in pygame.event.get():
                                                username.work(event_demande)
                                                password.work(event_demande)
                                                if event_demande.type == pygame.QUIT:
                                                    pygame.quit()
                                                    sys.exit()
                                                elif event_demande.type == pygame.MOUSEBUTTONDOWN:
                                                    if event.button == 1:
                                                        if retour_btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event_demande.pos)):
                                                            boucle_demande = False
                                                        elif valider_btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event_demande.pos)):
                                                            self.texte_fond("communication avec le serveur en cours...")
                                                            client.send_message(["create account", username.get_text(), password.get_text()]) # pas besoin de changement de page
                                                            boucle_demande = False

                                    elif resultat[0] == "oui":
                                        User.user.username = username.get_text()
                                        User.user.password = password.get_text()
                                        notif_manager.add_notif("connexion réussie : bienvenue " + username.get_text() + " !")
                                        self.game_state.state_actuel = "Accueil"
                                        return None

                                    elif resultat[0] == "non":
                                        notif_manager.add_notif("mot de passe incorrect")
                                        tick.reset_counts("cooldown connexion")
                                    else:
                                        raise ValueError("pb avec la réponse")
                            else:
                                # cooldown non terminé
                                notif_manager.add_notif("cooldown de connexion")