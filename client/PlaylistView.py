from User import user
from Client import client
from Screen import resize_screen
import os
import pygame
pygame.init()

class PlaylistView:
    def __init__(self, internal_state, nom_playlist:str):
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.nom_playlist = nom_playlist
        self.playlist = {}  # de la forme {nom:[image, artiste, annee, album]}
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.playlist_charged = False
        self.icone_base = None
        self.liste_noms_musiques = []

    def delete_cache_png(self):
        for element in os.listdir("cache/"):
            if element[len(element)-4:] == ".png":
                os.remove("cache/" + element)

    def charger_playlist(self):
        self.playlist = {}
        # suppression des potentielles images du cache
        self.delete_cache_png()

        # récupération de la liste des musiques de la plyalist
        resultat = client.send_message(["get playlist content", user.username, self.nom_playlist])
        if resultat == "crash":
            return "crash"
        self.liste_noms_musiques = resultat # c'est une liste

        # chargement des infos des musiques
        for musique in self.liste_noms_musiques:
            resultat = client.send_message(["get music infos", user.username, self.nom_playlist])
            if resultat == "crash":
                return "crash"
            self.playlist[musique] = [None] + resultat

            # chargement de l'image (stocké dans cache avec le nom de la musique)
            if user.load_images:
                pass    # à continuer

        self.playlist_charged = True

    def get_icone_base(self):
        if self.icone_base == None:
            self.icone_base = pygame.image.load("assets/icone_base.png").convert_alpha()
            self.icone_base = pygame.transform.smoothscale(self.icone_base, (50, 50))
            surface_icone = pygame.surface.Surface(self.icone_base.get_size())
            surface_icone.fill((0, 0, 0))
            surface_icone.blit(self.icone_base, (0, 0))
            self.icone_base = surface_icone
        return self.icone_base

    def blit(self):
        resize_screen.draw_rect("grey20", self.rect_dimensions, 50)
        if not self.playlist_charged:
            texte = self.police.render("chargement de " + self.nom_playlist + "...", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = self.rect_dimensions.center
            resize_screen.blit(texte, texte_rect.topleft)
            return None

    def listen_entry(self):
        # check du chargement de la playlist
        if not self.playlist_charged:
            # chargement de la playlist
            if self.charger_playlist() == "crash":
                return "crash"

PlaylistView("truc", "truc").delete_cache_png()