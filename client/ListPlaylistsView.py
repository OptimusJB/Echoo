from Screen import resize_screen
from Client import client
from User import user
from TextZone import TextZone
import pygame
pygame.init()

class ListPlaylistsView:
    """
    classe qui s'occupe de l'affichage des 
    """
    def __init__(self):
        self.y_offset = 0
        self.playlists = []
        self.liste_rects = []   # rect des playlists (même ordre que self.playlists)
        self.playlists_charged = False   # à mettre sur False s'il y a une mise à jour au niveau des playlists (ajout, suppression, modification du nom...)
        self.rect_dimensions = pygame.rect.Rect(20, 20, 600, 900)

        self.police = pygame.font.Font("assets/police.otf", 40)

        # chargement boutons
        self.create_btn = self.police.render("créer playlist", True, "white")
        self.create_btn_rect = self.create_btn.get_rect()
        self.create_btn_rect.size = (self.create_btn_rect.width + 20, self.create_btn_rect.height + 20)
        self.create_btn_rect.center = (20 + self.rect_dimensions.width//2, 880) # à changer au besoin

        self.create_text = TextZone(self.police)
    
    def reset(self):
        self.playlists = []
        self.playlists_charged = False
        self.y_offset = 0
    
    def charger_playlists(self):
        resultat = client.send_message(["get playlists", user.username])
        if resultat == "crash":
            return "crash"
        self.playlists = resultat
        self.playlists_charged = True
        print("playlists chargées : " + str(self.playlists))

    def blit(self):
        resize_screen.draw_rect("grey20", self.rect_dimensions, 50)
        if not self.playlists_charged:
            # affichage texte "chargement"
            texte = self.police.render("chargement...", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = self.rect_dimensions.center
            resize_screen.blit(texte, texte_rect.topleft)
        
        # blit éléments création playlist
        rect_fond = self.rect_dimensions.copy()
        bottom_rect = rect_fond.bottom
        rect_fond.height = 150
        rect_fond.width = rect_fond.width - 100
        rect_fond.x = rect_fond.x + 50
        rect_fond.bottom = bottom_rect
        resize_screen.draw_rect("red", rect_fond)

        resize_screen.draw_rect("dodgerblue3", self.create_btn_rect, 20)
        resize_screen.blit(self.create_btn, (self.create_btn_rect.x + 10, self.create_btn_rect.y + 10))
        
        # blit des playlists
        self.liste_rects = []
        y = 50
        for element in self.playlists:
            texte = self.police.render(element, True, "white")
            texte_rect = texte.get_rect()
            texte_rect.size = (texte_rect.width + 20, texte_rect.height + 20)
            texte_rect.topleft = (20, y + y_offset)
            resize_screen.blit(texte, (texte_rect.x + 10, texte_rect.y + 10))
            self.liste_rects.append(texte_rect)
            y = y + 50
    
    def listen_entry(self, event):
        if not self.playlists_charged:
            # chargement des playlists
            if self.charger_playlists() == "crash":
                return "crash"
            
        
playlist_manager = ListPlaylistsView()