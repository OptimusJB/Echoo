import pygame
pygame.init()

class KeyManager:
    def __init__(self):
        self.pressed = []

    def work(self, event):
        if event.type == pygame.KEYDOWN:
            if not pygame.key.name(event.key) in self.pressed:
                self.pressed.append(pygame.key.name(event.key))

    def get_pressed(self, touche):
        print(touche, self.pressed)
        if touche in self.pressed:
            self.pressed.remove(touche)
            return True
        return False

    def check_pressed(self, touches:list):  # ça ne supprime pas la touche, c'est juste un check
        """
        retourne True si l'une des touches passé en paramètre a été activée
        """
        for bouton in touches:
            if bouton in self.pressed:
                return True
        return False

key_manager = KeyManager()