from Screen import resize_screen
import pygame
pygame.init()

class TextZone:
    def __init__(self, police=pygame.font.Font):
        self.police = police
        self.rect = None
        self.clicked = False
        self.texte = ""
        self.color = "white"
        self.secret = False
        self.largeur_max = float("inf")
        self.prefixe = ""

    def set_rect(self, rect:pygame.rect.Rect):
        self.rect = rect

    def set_prefixe(self, prefixe:str):
        self.prefixe = prefixe

    def set_largeur_max(self, largeur:int):
        """
        largeur en pixel
        """
        self.largeur_max = largeur

    def set_color(self, color):
        self.color = color

    def hide_text(self):
        self.secret = not self.secret

    def est_vide(self):
        return len(self.texte) == 0

    def work(self, event):
        assert self.rect != None, "rect non initialisé"
        # calcul sélection zone de texte
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    self.clicked = True
                else:
                    self.clicked = False

        elif event.type == pygame.KEYDOWN and self.clicked:
            if event.key == pygame.K_BACKSPACE and len(self.texte) > 0:
                self.texte = self.texte[:len(self.texte)-1]

            else:
                if not self.secret:
                    texte = self.texte + self.prefixe
                else:
                    texte = "." * len(self.prefixe + self.texte)
                if self.police.size(texte)[0] < self.largeur_max:
                    if event.key == pygame.K_SPACE:
                        self.texte = self.texte + " "
                    elif len(pygame.key.name(event.key)) == 1:
                        self.texte = self.texte + event.unicode

    def get_image(self):
        if not self.secret:
            texte = self.prefixe + self.texte
        else:
            texte = "." * len(self.prefixe + self.texte)

        if pygame.time.get_ticks() // 1000 % 2 == 1 and self.clicked:
            texte = texte + "|"

        return self.police.render(texte, True, self.color)
    
    def get_rect(self):
        return self.rect

    def get_text(self):
        return self.texte