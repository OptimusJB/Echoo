from Screen import resize_screen
from Client import client
from User import user
from ArtisteView import ArtisteView
import pygame
pygame.init()

class ListArtisteView:
    def __init__(self, internal_state, recherche):
        self.internal_state = internal_state
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.recherche = recherche
        self.liste_artistes = []
        self.rects_artistes = []
        self.charged = False  # détermine si listen_entry peut fonctionner
        self.y_offset = 0
        self.y = 0

        self.rects_cache = [pygame.rect.Rect(20 + 600 + 10, 0, 1920 - 20 - 600 - 20, 100), pygame.rect.Rect(20 + 600 + 10, 100 + 900 - 80, 1920 - 20 - 600 - 20, 30)]

    def blit(self):
        resize_screen.draw_rect("grey30", self.rect_dimensions, 50)  # fond
        resize_screen.draw_rect("grey10", self.rects_cache[0])

        if not self.charged:
            texte = self.police.render("chargement des artistes...", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = self.rect_dimensions.center
            resize_screen.blit(texte, texte_rect.topleft)
            return None

        self.rects_artistes = []
        # blit des artistes
        self.y = 150
        for artiste in self.liste_artistes:
            texte = self.police.render(artiste, True, "white")
            texte_rect = texte.get_rect()
            texte_rect.size = (texte_rect.width + 20, texte_rect.height + 20)
            texte_rect.centerx = self.rect_dimensions.centerx
            texte_rect.y = self.y + self.y_offset
            self.rects_artistes.append(texte_rect)

            if texte_rect.colliderect(self.rect_dimensions):
                resize_screen.draw_rect("grey15", texte_rect, 20)
                resize_screen.blit(texte, (texte_rect.x + 10, texte_rect.y + 10))

            self.y = self.y + 100

        # blit des caches en haut et en bas
        resize_screen.draw_rect("grey10", self.rects_cache[0])
        resize_screen.draw_rect("grey10", self.rects_cache[1])

    def charger_artistes(self):
        resultat = client.send_message(["get artistes", user.username, self.recherche])
        if resultat == "crash":
            return "crash"
        self.liste_artistes = resultat
        self.charged = True

    def listen_entry(self, event):
        # check du chargement des artistes
        if not self.charged:
            # chargement des artistes
            if self.charger_artistes() == "crash":
                return "crash"
            self.blit() # pour charger les rects

        if event.type == pygame.MOUSEWHEEL:
            if self.rect_dimensions.collidepoint(resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())):
                # print(self.y, self.y_offset, self.rect_dimensions.height)
                if event.y < 0:
                    for i in range(abs(event.y)):
                        if self.y + self.y_offset > self.rect_dimensions.bottom - 20:
                            self.y_offset -= 45

                elif event.y > 0:
                    for i in range(abs(event.y)):
                        if self.y_offset < 0:
                            self.y_offset += 45

        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                for rect in self.rects_artistes:
                    if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        index_rect = self.rects_artistes.index(rect)
                        artiste = self.liste_artistes[index_rect]
                        self.internal_state.state_actuel = ArtisteView(self.internal_state, artiste)