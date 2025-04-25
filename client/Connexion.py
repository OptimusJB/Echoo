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

    def change_server_ip(self):
        """
        boucle qui s'enclenche quand l'utilisateur clique sur l'ip en haut à gauche sur l'écran de connexion
        """
        # chargement du fond
        resize_screen.load_screen("fond connexion")   # pour enlever les potentiels messages dynamiques
        resize_screen.draw_rect("grey15", pygame.rect.Rect((1920 // 2 - 400, 1080 // 2 - 300, 800, 600)), 50)

        texte_ip = TextZone(self.police)
        texte_port = TextZone(self.police)
        texte_ip.set_largeur_max(570)
        texte_port.set_largeur_max(570)
        texte_ip.set_prefixe("ip : ")
        texte_port.set_prefixe("port : ")

        ip_rect = pygame.rect.Rect(1920 // 2 - 350, 1080 // 2 - 250 + 100, 700, 100)
        port_rect = pygame.rect.Rect(1920 // 2 - 350, 1080 // 2 - 120 + 100, 700, 100)
        texte_ip.set_rect(ip_rect)
        texte_port.set_rect(port_rect)

        # blit du fond
        resize_screen.draw_rect("grey50", ip_rect, 20)
        resize_screen.draw_rect("grey50", port_rect, 20)

        # blit texte
        texte = self.police.render("nouveau serveur", True, "white")
        resize_screen.blit(texte, (1920 // 2 - texte.get_size()[0] // 2, 280))

        # génération boutons valider et retour
        valider_btn = self.police.render("valider", True, "white")
        valider_btn_rect = valider_btn.get_rect()
        valider_btn_rect.size = (valider_btn_rect.width + 20, valider_btn_rect.height + 20)
        valider_btn_rect.topleft = (700, 680)

        retour_btn = self.police.render("retour", True, "white")
        retour_btn_rect = retour_btn.get_rect()
        retour_btn_rect.size = (retour_btn_rect.width + 20, retour_btn_rect.height + 20)
        retour_btn_rect.topleft = (1000, 680)

        # blit des deux boutons
        resize_screen.draw_rect("dodgerblue3", valider_btn_rect, 20)
        resize_screen.blit(valider_btn, (valider_btn_rect.x + 10, valider_btn_rect.y + 10))
        resize_screen.draw_rect("dodgerblue3", retour_btn_rect, 20)
        resize_screen.blit(retour_btn, (retour_btn_rect.x + 10, retour_btn_rect.y + 10))

        resize_screen.save_screen("fond changement ip")

        boucle_ip = True
        clock_ip = pygame.time.Clock()
        while boucle_ip:
            resize_screen.load_screen("fond changement ip")
            resize_screen.blit(texte_ip.get_image(), (ip_rect.x + 10, ip_rect.y + 15))
            resize_screen.blit(texte_port.get_image(), (port_rect.x + 10, port_rect.y + 15))

            notif_manager.work()
            resize_screen.flip()
            for event in pygame.event.get():
                texte_ip.work(event)
                texte_port.work(event)

                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()

                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        if retour_btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            boucle_ip = False
                        elif valider_btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            # vérification port
                            try:
                                int(texte_port.get_text())
                                client.change_ip(texte_ip.get_text(), int(texte_port.get_text()))
                                boucle_ip = False
                                notif_manager.add_notif("ip serveur modifié")
                            except:
                                notif_manager.add_notif("port invalide")

            clock_ip.tick(30)
            
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
        username.set_rect(pygame.rect.Rect(1920//2-350+5, 1080//2-250, 700, 100))
        username.set_largeur_max(570)

        password = TextZone(self.police)
        password.set_rect(pygame.rect.Rect(1920 // 2 - 350 + 10, 1080 // 2 - 120, 700, 100))
        password.set_largeur_max(570)
        password.hide_text()

        resize_screen.save_screen("fond connexion")
        tick = Tick()
        clock = pygame.time.Clock()
        while True:
            resize_screen.load_screen("fond connexion")
            resize_screen.blit(username.get_image(), (1920//2-350+100, 1080//2-250 + 15))
            resize_screen.blit(password.get_image(), (1920//2-350+100, 1080//2-120+15))

            # génération bouton ip
            ip_info = client.get_ip()
            texte_ip = self.police.render("serveur : " + ip_info[0] + ":" + str(ip_info[1]), True, "white")
            texte_ip_rect = texte_ip.get_rect()
            texte_ip_rect.width = texte_ip_rect.width + 20
            texte_ip_rect.height = texte_ip_rect.height + 20
            texte_ip_rect.topleft = (20, 20)
            resize_screen.draw_rect("grey15", texte_ip_rect, 20)
            resize_screen.blit(texte_ip, (texte_ip_rect.x + 10, texte_ip_rect.y + 10))

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
                        if texte_ip_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            # modification de l'ip du serveur
                            self.change_server_ip()
                        elif rect_login.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)) and not username.est_vide() and not password.est_vide():
                            if can_connect:
                                resultat = client.send_message(["connect", username.get_text(), password.get_text()]) # pas besoin de changement de page

                                # test résultat commande
                                if resultat != None:
                                    if resultat[0] == "new account":    # pop up demande de création de nouveau compte
                                        # génération fond
                                        resize_screen.load_screen("fond connexion")
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

                                        resize_screen.save_screen("fond création compte")

                                        pygame.event.get()
                                        clock_demande = pygame.time.Clock()
                                        boucle_demande = True
                                        while boucle_demande:
                                            resize_screen.load_screen("fond création compte")
                                            notif_manager.work()
                                            resize_screen.flip()
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
                                                            client.send_message(["create account", username.get_text(), password.get_text()]) # pas besoin de changement de page
                                                            notif_manager.add_notif("compte créé")
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