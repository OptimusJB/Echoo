from Screen import resize_screen
import pygame
pygame.init()

class Switch:
    def __init__(self, liste_modes:list, center:tuple, prefixe=""):
        self.liste_modes = liste_modes
        self.index_mode = 0   # index de self.liste_modes
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.rect = pygame.rect.Rect(-10, -10, 2, 2)    # hors écran
        self.center = center
        self.prefixe = prefixe

    def blit(self):
        texte = self.police.render(self.prefixe + str(self.liste_modes[self.index_mode]), True, "white")
        self.rect = texte.get_rect()
        self.rect.width += 20
        self.rect.height += 20
        self.rect.center = self.center

        resize_screen.draw_rect("grey20", self.rect, 20)
        resize_screen.blit(texte, (self.rect.x + 10, self.rect.y + 10))

    def listen_entry(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    self.index_mode = (self.index_mode + 1) % len(self.liste_modes)

    def get_mode(self):
        return self.liste_modes[self.index_mode]

    def set_mode(self, mode):   # mode n'est pas un index, c'est l'une des valeurs dans self.liste_modes
        assert mode in self.liste_modes, "le mode en paramètre n'est pas dans self.liste_modes"
        self.index_mode = self.liste_modes.index(mode)