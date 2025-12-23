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
        self.curseur = 0

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
                    self.curseur = len(self.texte)
                else:
                    self.clicked = False

        elif event.type == pygame.KEYDOWN and self.clicked:
            if event.key == pygame.K_LEFT:
                self.curseur = max(0, self.curseur - 1)
            elif event.key == pygame.K_RIGHT:
                self.curseur = min(len(self.texte), self.curseur + 1)

            elif event.key == pygame.K_BACKSPACE and len(self.texte) > 0:
                if pygame.key.get_pressed()[pygame.K_LSHIFT]:
                    self.texte = ""
                    self.curseur = 0
                else:
                    self.texte = self._ajouter_element(self.texte, "backspace")
                    self.curseur = max(0, self.curseur - 1)

            else:
                if not self.secret:
                    texte = self.texte + self.prefixe
                else:
                    texte = "." * len(self.prefixe + self.texte)
                #if self.police.size(texte)[0] < self.largeur_max:
                if event.unicode.lower() in " azertyuiopmlkjhgfdsqwxcvbn0123456789*-+.:!?/§&é'(-è_çà)='" + '"':
                    self.texte = self._ajouter_element(self.texte, event.unicode)
                    self.curseur = min(len(self.texte), self.curseur + 1)

    def _ajouter_element(self, texte, caractere):
        if pygame.time.get_ticks() // 1000 % 2 == 1 and self.clicked or caractere != "|":
            # on met le "|"
            texte = texte.replace("", "&slesc&")
            texte = texte.split("&slesc&")
            # on enlève les espaces au début et à la fin
            texte.pop(0)
            texte.pop(len(texte) - 1)

            if caractere == "backspace":
                if self.curseur > 0:
                    texte.pop(self.curseur - 1)
            else:
                texte.insert(self.curseur, caractere)
            texte = "".join(texte)
        return texte

    def get_image(self):
        if not self.secret:
            texte = self._ajouter_element(self.texte, "|")
            texte = self.prefixe + texte
        else:
            texte = "." * len(self.texte)
            texte = self._ajouter_element(texte, "|")
            texte = "." * len(self.prefixe) + texte

        texte = self.police.render(texte, True, self.color)
        surface = pygame.surface.Surface((self.rect.size[0], texte.size[1]), pygame.SRCALPHA)
        texte_rect = texte.get_rect()
        if texte_rect.width > surface.size[0] - 20:
            texte_rect.right = surface.width - 20
        else:
            texte_rect.left = 0
        surface.blit(texte, (texte_rect.x, 0))
        return surface
    
    def get_rect(self):
        return self.rect

    def get_text(self):
        return self.texte