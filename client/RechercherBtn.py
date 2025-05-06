from Screen import resize_screen
from InternalState import internal_state
from Rechercher import Rechercher
import pygame
pygame.init()

class RechercherBtn:
    def __init__(self):
        self.police = pygame.font.Font("assets/police.otf", 30)
        self.btn_image = self.police.render("Rechercher", True, "white")

        self.btn_rect = self.btn_image.get_rect()
        self.btn_rect.width += 20
        self.btn_rect.height += 20
        self.btn_rect.topleft = (20+600+10 + 30, 20)

    def blit(self):
        color = "grey35"
        if type(internal_state.state_actuel) == Rechercher:
            color = "dodgerblue3"
        resize_screen.draw_rect(color, self.btn_rect, 20)
        resize_screen.blit(self.btn_image, (self.btn_rect.x + 10, self.btn_rect.y + 10))

    def listen_entry(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    internal_state.state_actuel = Rechercher(internal_state)

    def reset(self):
        pass

rechercher_btn = RechercherBtn()