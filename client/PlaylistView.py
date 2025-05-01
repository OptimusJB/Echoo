from User import user
from Client import client
from Screen import resize_screen
from PlayerView import player
import os
import pygame
pygame.init()

class PlaylistView:
    def __init__(self, internal_state, nom_playlist:str, load_via_album:bool):
        self.y = 0
        self.y_offset = 0
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.police_mid = pygame.font.Font("assets/police.otf", 30)   # la même mais en plus petit
        self.police_small = pygame.font.Font("assets/police.otf", 20)   # la même mais en encore plus petit
        self.nom_playlist = nom_playlist
        self.playlist = {}  # de la forme {nom:[image, artiste, annee, album]}
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.playlist_charged = False
        self.icone_base = None
        self.liste_noms_musiques = []
        self.load_via_album = load_via_album # détermine si la playlist est chargée via une playlist ou via un nom d'album

        # définition rects cliquables
        self.rects_image = []
        self.rects_artiste = []
        self.rects_play = []
        self.rects_titre = []

    def delete_cache_png(self):
        for element in os.listdir("cache/"):
            if element[len(element)-4:] == ".png" and not element == "cache.png":
                os.remove("cache/" + element)

    def charger_playlist(self):
        self.playlist = {}
        # suppression des potentielles images du cache
        self.delete_cache_png()

        # récupération de la liste des musiques de la playlist
        resultat = client.send_message(["get playlist content", user.username, self.nom_playlist])
        if resultat == "crash":
            return "crash"
        self.liste_noms_musiques = resultat # c'est une liste

        # chargement des infos des musiques
        for musique in self.liste_noms_musiques:
            resultat = client.send_message(["get music infos", user.username, musique])
            if resultat == "crash":
                return "crash"

            # date str --> int
            resultat[1] = int(resultat[1])
            self.playlist[musique] = [None] + resultat

            # chargement de l'image (stocké dans cache avec le nom de la musique)
            if user.load_images:
                resultat = client.ask_music_image(user.username, musique)
                if resultat == "crash":
                    return "crash"

                # écriture du fichier dans le cache
                fichier = open("cache/" + musique + ".png", "wb")
                fichier.write(resultat)
                fichier.close()

                # chargement dans le dictionnaire
                self.playlist[musique][0] = pygame.image.load("cache/" + musique + ".png").convert_alpha()
                self.playlist[musique][0] = pygame.transform.smoothscale(self.playlist[musique][0], (80, 80))
            else:
                self.playlist[musique][0] = self.get_icone_base()

        self.playlist_charged = True

    def get_icone_base(self):
        if self.icone_base == None:
            self.icone_base = pygame.image.load("assets/icone_base.png").convert_alpha()
            self.icone_base = pygame.transform.smoothscale(self.icone_base, (80, 80))
        return self.icone_base

    def blit(self):
        resize_screen.draw_rect("grey30", self.rect_dimensions, 50) # fond

        # blit du nom de la playlist
        titre = self.police.render(self.nom_playlist, True, "white")
        titre_rect = titre.get_rect()
        titre_rect.center = (self.rect_dimensions.centerx, 200)
        fond_titre = titre_rect.copy()
        fond_titre.size = (fond_titre.width + 80, fond_titre.height + 80)
        fond_titre.topleft = (fond_titre.x - 40, fond_titre.y - 40)
        resize_screen.draw_rect("grey20", fond_titre, 50)
        resize_screen.blit(titre, titre_rect.topleft)

        if not self.playlist_charged:
            texte = self.police.render("chargement de " + self.nom_playlist + "...", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = self.rect_dimensions.center
            resize_screen.blit(texte, texte_rect.topleft)
            return None

        # reset des listes
        self.rects_play = []
        self.rects_image = []
        self.rects_artiste = []
        self.rects_titre = []

        # blit des éléments en haut
        texte = self.police_mid.render("#", True, "white")
        resize_screen.blit(texte, (650, 300 + self.y_offset))
        texte = self.police_mid.render("titre" ,True, "white")
        resize_screen.blit(texte, (750, 300 + self.y_offset))
        texte = self.police_mid.render("album", True, "white")
        resize_screen.blit(texte, (1350, 300 + self.y_offset))

        # génération du triangle
        triangle = pygame.surface.Surface((100, 100), pygame.SRCALPHA)
        pygame.draw.polygon(triangle, "white", [(0, 0), (100, 50), (0, 100)])
        triangle = pygame.transform.smoothscale_by(triangle, 0.3)

        mouse_pos = resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())
        self.y = 350
        compteur = 0
        for musique in self.playlist.keys():
            compteur += 1
            # blit du potentiel fond différent
            rect_titre = pygame.rect.Rect(600 + 20 + 10, self.y - 10, 1920-20-600-20, 80 + 10 + 10 + self.y_offset)
            if rect_titre.collidepoint(mouse_pos):
                resize_screen.draw_rect("grey65", rect_titre, 20)
            self.rects_titre.append(rect_titre)

            # blit des infos
            # compteur
            texte = self.police_mid.render(str(compteur), True, "white")
            resize_screen.blit(texte, (650, self.y + 20 + self.y_offset))

            # image
            image_rect = self.playlist[musique][0].get_rect()
            image_rect.topleft = (750, self.y + self.y_offset)
            self.rects_image.append(image_rect)
            resize_screen.blit(self.playlist[musique][0], image_rect)

            # titre
            titre_final = musique
            if len(musique) > 25:
                titre_final = titre_final[:25] + "..."

            titre = self.police_mid.render(titre_final, True, "white")
            titre_rect = titre.get_rect()
            titre_rect.midleft = (image_rect.centerx + 50, image_rect.centery-10 + self.y_offset)
            resize_screen.blit(titre, titre_rect.topleft)

            # artiste
            artiste_final = self.playlist[musique][1]
            if len(artiste_final) > 35:
                artiste_final = artiste_final[:35] + "..."
            artiste = self.police_small.render(artiste_final, True, "white")
            artiste_rect = artiste.get_rect()
            artiste_rect.topleft = (titre_rect.x, titre_rect.bottom + 1 + self.y_offset)
            self.rects_artiste.append(artiste_rect)
            resize_screen.blit(artiste, artiste_rect.topleft)

            # album
            album_final = self.playlist[musique][3]
            if len(album_final) > 28:
                album_final = album_final[:28] + "..."
            album = self.police_mid.render(album_final, True, "white")
            album_rect = album.get_rect()
            album_rect.midleft = (1350, image_rect.centery + self.y_offset)
            resize_screen.blit(album, album_rect.topleft)

            # bouton play (ne s'affiche que quand on passe la souris sur le titre)
            rect_triangle = triangle.get_rect()
            rect_triangle.midright = (image_rect.x - 25, image_rect.centery)
            self.rects_play.append(rect_triangle)

            if rect_titre.collidepoint(mouse_pos):
                resize_screen.blit(triangle, rect_triangle.topleft)

            self.y = self.y + 100

    def listen_entry(self, event):
        # check du chargement de la playlist
        if not self.playlist_charged:
            # chargement de la playlist
            if self.charger_playlist() == "crash":
                return "crash"

        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                # test des rects play
                for rect in self.rects_play:
                    if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        index_rect = self.rects_play.index(rect)
                        if player.load(self.liste_noms_musiques, self.liste_noms_musiques[index_rect]) == "crash":
                            return "crash"