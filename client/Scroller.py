import pygame
from Screen import resize_screen

class Scroller:
    """
    min et max doivent être des entiers positifs
    """
    def __init__(self, rect:pygame.rect.Rect, minimum:int=0, maximum:int=10):
        assert minimum >= 0 and maximum >= 0 and minimum <= maximum, "pb valeurs"
        self.min = minimum
        self.max = maximum
        self.scrolling = minimum

        self.rect = rect

        self.image = pygame.surface.Surface(self.rect.size)
        self.image.fill("grey50")

        self.clicked = False

    def set_scrolling(self, nombre:int):
        self.scrolling = nombre
        self.scrolling = max(self.min, self.scrolling)
        self.scrolling = min(self.max, self.scrolling)

    def get_pourcentage_scroll(self, minimum=None, maximum=None, scrolling=None):
        """
        min, max et scrolling doivent être des entiers
        retourne le pourcentage d'avancée du scrolling
        """
        if minimum == None and maximum == None and scrolling == None:
            minimum = self.min
            maximum = self.max
            scrolling = self.scrolling

        assert minimum >= 0 and maximum >= 0 and scrolling >= 0 and minimum <= maximum, "pb valeurs"

        scrolling = scrolling - minimum
        maximum = maximum - minimum
        return 100 / (maximum + 1) * scrolling  # max + 1 pour éviter la division par 0

    def pourcentage_to_scroll(self, pourcentage):
        """
        change self.scrolling par rapport au pourcentage passé en paramètre
        """
        minimum = self.min
        maximum = self.max
        maximum = maximum - minimum
        self.set_scrolling(maximum / 100 * pourcentage + minimum)

    def blit(self):
        if self.clicked:
            self.set_scrolling(resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())[1])
        self.rect.centery = self.scrolling    # vertical
        #self.rect.y = max(self.min, self.rect.y)
        #self.rect.y = min(self.max, self.rect.y)
        resize_screen.blit(self.image, self.rect.topleft)

    def listen_entry(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    self.clicked = True
        elif event.type == pygame.MOUSEBUTTONUP:
            self.clicked = False