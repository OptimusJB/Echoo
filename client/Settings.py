from Screen import resize_screen
import pygame
from Switch import Switch
from User import user
from NotifManager import notif_manager
pygame.init()

class Settings:
    def __init__(self, internal_state):
        self.rect_dimensions = pygame.rect.Rect(20 + 600 + 10, 100, 1920 - 20 - 600 - 20, 900 - 80)
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.internal_state = internal_state
        self.liste_switchs = [Switch(["oui", "non"], (self.rect_dimensions.centerx, 350), "charger images : "),
                              Switch(["min", "moyen", "max"], (self.rect_dimensions.centerx, 450), "qualité des musiques : ")]
        self.liste_switchs[0].set_mode({True:"oui", False:"non"}[user.load_images])
        self.liste_switchs[1].set_mode(user.quality)

        self.valider_txt = self.police.render("valider", True, "white")
        self.rect_valider = self.valider_txt.get_rect()
        self.rect_valider.width += 20
        self.rect_valider.height += 20
        self.rect_valider.center = (self.rect_dimensions.centerx, 550)

    def blit(self):
        # blit du fond
        resize_screen.draw_rect("grey35", self.rect_dimensions, 50)

        # blit du nom de la page
        titre = self.police.render("Paramètres", True, "white")
        titre_rect = titre.get_rect()
        titre_rect.center = (self.rect_dimensions.centerx, 200)
        fond_titre = titre_rect.copy()
        fond_titre.size = (fond_titre.width + 80, fond_titre.height + 80)
        fond_titre.topleft = (fond_titre.x - 40, fond_titre.y - 40)
        resize_screen.draw_rect("grey20", fond_titre, 50)
        resize_screen.blit(titre, titre_rect.topleft)

        # blit des switch
        for switch in self.liste_switchs:
            switch.blit()

        # blit du bouton valider
        resize_screen.draw_rect("dodgerblue3", self.rect_valider, 20)
        resize_screen.blit(self.valider_txt, (self.rect_valider.x + 10, self.rect_valider.y + 10))

    def listen_entry(self, event):
        for switch in self.liste_switchs:
            switch.listen_entry(event)

        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.rect_valider.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    # changement des paramètres puis sauvegarde
                    user.load_images = {"oui":True, "non":False}[self.liste_switchs[0].get_mode()]
                    user.quality = self.liste_switchs[1].get_mode()
                    user.save_settings()
                    notif_manager.add_notif("paramètres sauvegardés")
                    self.internal_state.load_rechercher()