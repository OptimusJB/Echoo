from Screen import resize_screen
from Client import client
from User import user
from PlaylistView import PlaylistView
import pygame
pygame.init()

class ArtisteView:
    def __init__(self, internal_state, artiste):
        self.internal_state = internal_state
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.artiste = artiste
        self.charged = False
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.liste_playlists = []
        self.rects_playlists = []

        self.rects_cache = [pygame.rect.Rect(20 + 600 + 10, 0, 1920 - 20 - 600 - 20, 100), pygame.rect.Rect(20 + 600 + 10, 100 + 900 - 80, 1920 - 20 - 600 - 20, 30)]

        self.y = 0
        self.y_offset = 0

    def blit(self):
        resize_screen.draw_rect("grey30", self.rect_dimensions, 50)  # fond

        # blit du nom de l'auteur
        titre = self.police.render("albums de " + self.artiste, True, "white")
        titre_rect = titre.get_rect()
        titre_rect.center = (self.rect_dimensions.centerx, 200 + self.y_offset)
        fond_titre = titre_rect.copy()
        fond_titre.size = (fond_titre.width + 80, fond_titre.height + 80)
        fond_titre.topleft = (fond_titre.x - 40, fond_titre.y - 40)
        resize_screen.draw_rect("grey20", fond_titre, 50)
        resize_screen.blit(titre, titre_rect.topleft)

        if not self.charged:
            texte = self.police.render("chargement des artistes...", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = self.rect_dimensions.center
            resize_screen.blit(texte, texte_rect.topleft)
            return None

        self.rects_playlists = []
        # blit des playlists de l'artiste
        self.y = 300
        for artiste in self.liste_playlists:
            texte = self.police.render(artiste, True, "white")
            texte_rect = texte.get_rect()
            texte_rect.size = (texte_rect.width + 20, texte_rect.height + 20)
            texte_rect.centerx = self.rect_dimensions.centerx
            texte_rect.y = self.y + self.y_offset
            self.rects_playlists.append(texte_rect)

            if texte_rect.colliderect(self.rect_dimensions):
                resize_screen.draw_rect("grey15", texte_rect, 20)
                resize_screen.blit(texte, (texte_rect.x + 10, texte_rect.y + 10))

            self.y = self.y + 100

        # blit des caches en haut et en bas
        resize_screen.draw_rect("grey10", self.rects_cache[0])
        resize_screen.draw_rect("grey10", self.rects_cache[1])

    def charger_playlists(self):
        resultat = client.send_message(["get playlists of artiste", user.username, self.artiste])
        if resultat == "crash":
            return "crash"
        self.liste_playlists = resultat
        self.charged = True

    def listen_entry(self, event):
        # check du chargement des playlists de l'artiste
        if not self.charged:
            # chargement des playlists de l'artiste
            if self.charger_playlists() == "crash":
                return "crash"
            self.blit()  # pour charger les rects

        if event.type == pygame.MOUSEWHEEL:
            if self.rect_dimensions.collidepoint(resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())):
                # print(self.y, self.y_offset, self.rect_dimensions.height)
                if event.y < 0:
                    for i in range(abs(event.y)):
                        if self.y + self.y_offset > self.rect_dimensions.bottom - 20:  # pas encore configuré
                            self.y_offset -= 45

                elif event.y > 0:
                    for i in range(abs(event.y)):
                        if self.y_offset < 0:
                            self.y_offset += 45

        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.rect_dimensions.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    for rect in self.rects_playlists:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            index_rect = self.rects_playlists.index(rect)
                            playlist_choisie = self.liste_playlists[index_rect]
                            self.internal_state.state_actuel = PlaylistView(self.internal_state, playlist_choisie, True, False)