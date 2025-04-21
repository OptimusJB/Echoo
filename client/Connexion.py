import pygame
import sys
from TextZone import TextZone
from Screen import resize_screen
pygame.init()
class Connexion:
    def __init__(self, game_state_manager):
        self.game_state = game_state_manager
        self.police = pygame.font.Font("assets/police.otf", 50)

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
        clock = pygame.time.Clock()
        while True:
            resize_screen.load_screen("fond connexion")
            resize_screen.blit(username.get_image(), (1920//2-350+100, 1080//2-250 + 15))
            resize_screen.blit(password.get_image(), (1920//2-350+100, 1080//2-120+15))
            resize_screen.flip()

            clock.tick(20)

            for event in pygame.event.get():
                username.work(event)
                password.work(event)
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()

                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        if rect_login.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            print("connexion")