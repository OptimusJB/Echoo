from Screen import resize_screen
from TextZone import TextZone
from Client import client
import pygame
pygame.init()

class Rechercher:
    def __init__(self, internal_state):
        self.internal_state = internal_state
        self.mode = "selection" # = selection, titre, artiste
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.police = pygame.font.Font("assets/police.otf", 30)
        self.recherche = TextZone(self.police)
        self.recherche.set_rect(pygame.rect.Rect(1920//2 - 300, 1080//2 + 200, 1000, 65))
        self.recherche.set_prefixe("rechercher : ")
        self.recherche.set_largeur_max(960)

        # chargement bouton rechercher
        self.rechercher_btn_rect = pygame.rect.Rect(0, 0, 200, 65)
        self.rechercher_btn_rect.midleft = (self.recherche.get_rect().right + 10, self.recherche.get_rect().centery)

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

        # blit des boutons
        color = {"selection":"grey25", "titre":"dodgerblue3", "artiste":"grey25"}[self.mode]
        resize_screen.draw_rect(color, self.bouton1, 50)
        rect_image = self.titre_image.get_rect()
        rect_image.center = (self.bouton1.centerx, self.bouton1.centery - 50)
        resize_screen.blit(self.titre_image, rect_image.topleft)

        texte = self.police.render("chercher un titre", True, "white")
        texte_rect = texte.get_rect()
        texte_rect.midbottom = (self.bouton1.centerx, self.bouton1.bottom - 20)
        resize_screen.blit(texte, texte_rect)

        color = {"selection": "grey25", "titre": "grey25", "artiste": "dodgerblue3"}[self.mode]
        resize_screen.draw_rect(color, self.bouton2, 50)
        rect_image = self.artiste_image.get_rect()
        rect_image.center = (self.bouton2.centerx, self.bouton2.centery - 35)
        resize_screen.blit(self.artiste_image, rect_image.topleft)

        texte = self.police.render("chercher un artiste", True, "white")
        texte_rect = texte.get_rect()
        texte_rect.midbottom = (self.bouton2.centerx, self.bouton2.bottom - 20)
        resize_screen.blit(texte, texte_rect)
            
        if self.mode != "selection":
            # blit de la barre de recherche
            resize_screen.draw_rect("grey50", self.recherche.get_rect(), 20)
            rect_image = self.recherche.get_rect()
            resize_screen.blit(self.recherche.get_image(), (rect_image.x + 10, rect_image.y + 10))

            # blit du bouton rechercher
            resize_screen.draw_rect("grey50", self.rechercher_btn_rect, 20)
            resize_screen.blit(self.police.render("recherche", True, "white"), (self.rechercher_btn_rect.x + 25, self.rechercher_btn_rect.y + 10))


    def listen_entry(self, event):
        self.recherche.work(event)
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.bouton1.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    self.mode = "titre"
                    self.recherche.texte = ""
                elif self.bouton2.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    self.mode = "artiste"
                    self.recherche.texte = ""

                elif self.rechercher_btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    if self.mode == "titre":
                        # chargement de la playlist de recherche
                        self.internal_state.load_playlist("recherche", False, self.recherche.texte)

                    elif self.mode == "artiste":
                        # chargement du screen d'affichage des artistes
                        self.internal_state.load_liste_artiste(self.recherche.texte)