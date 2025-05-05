from Screen import resize_screen
from TextZone import TextZone
import pygame
pygame.init()

class Rechercher:
    def __init__(self):
        self.mode = "selection" # = selection, titre, artiste
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.police = pygame.font.Font("assets/police.otf", 30)

        # chargement des images
        self.artiste_image = pygame.image.load("assets/username_image.png").convert_alpha()
        self.artiste_image = pygame.transform.smoothscale_by(self.artiste_image, 0.4)
        self.titre_image = pygame.image.load("assets/note_musique.png").convert_alpha()
        self.titre_image = pygame.transform.smoothscale_by(self.titre_image, 0.6)

        self.bouton1 = pygame.rect.Rect(self.rect_dimensions.x + 275, self.rect_dimensions.y + 150, 350, 350)
        self.bouton2 = self.bouton1.copy()
        self.bouton2.x += 400

    def blit(self):
        # blit du fond
        resize_screen.draw_rect("grey35", self.rect_dimensions, 50)

        if self.mode == "selection":
            # blit des boutons
            resize_screen.draw_rect("grey25", self.bouton1, 50)
            rect_image = self.titre_image.get_rect()
            rect_image.center = (self.bouton1.centerx, self.bouton1.centery - 50)
            resize_screen.blit(self.titre_image, rect_image.topleft)

            texte = self.police.render("chercher un titre", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.midbottom = (self.bouton1.centerx, self.bouton1.bottom - 20)
            resize_screen.blit(texte, texte_rect)
            
            resize_screen.draw_rect("grey25", self.bouton2, 50)
            rect_image = self.artiste_image.get_rect()
            rect_image.center = (self.bouton2.centerx, self.bouton2.centery - 35)
            resize_screen.blit(self.artiste_image, rect_image.topleft)

            texte = self.police.render("chercher un artiste", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.midbottom = (self.bouton2.centerx, self.bouton2.bottom - 20)
            resize_screen.blit(texte, texte_rect)
            
        elif self.mode == "titre":
            pass
        elif self.mode == "artiste":
            pass
        else:
            raise ValueError("self.mode invalide")

    def listen_entry(self, event):
        pass