from Screen import resize_screen
import pygame
pygame.init()

class NotifManager:
    """
    permet l'affichage de notification
    """
    def __init__(self, temps_affichage):
        """
        le temps d'affichage est en ms
        """
        self.liste_notifs = []
        self.temps_affichage = temps_affichage

    def work(self):
        a_virer = []
        y = 1000
        for notif in self.liste_notifs:
            if notif.is_outdated(self.temps_affichage):
                a_virer.append(notif)
            else:
                notif.blit((1920//2, y))
                y = y - 100

        for element in a_virer:
            self.liste_notifs.remove(element)

    def add_notif(self, texte):
        self.liste_notifs.append(Notif(texte))

class Notif:
    """
    classe Notif de base
    """
    def __init__(self, texte):
        self.base_time = None
        self.texte = texte
        self.police = pygame.font.Font("assets/police.otf", 30)

    def blit(self, pos:tuple):
        assert type(pos) == tuple, "pos doit être un tuple"

        # mise en place du temps lors du premier blit
        if self.base_time == None:
            self.base_time = pygame.time.get_ticks()

        texte = self.police.render(self.texte, True, "white")
        texte_rect = texte.get_rect()
        texte_rect.width = texte_rect.width + 40
        texte_rect.height = texte_rect.height + 40
        texte_rect.center = pos
        resize_screen.draw_rect("grey30", texte_rect, 20)
        resize_screen.blit(texte, (texte_rect.x + 20, texte_rect.y + 20))

    def is_outdated(self, time:int):
        """
        retourne True si le temps d'apparition est dépassé, False sinon
        time en ms
        """
        if self.base_time == None:
            return False
        return pygame.time.get_ticks() - self.base_time > time

notif_manager = NotifManager(3000)
