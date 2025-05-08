from Screen import resize_screen
from Client import client
from User import user
from TextZone import TextZone
from NotifManager import notif_manager
from InternalState import internal_state
import pygame
pygame.init()

class ListPlaylistsView:
    """
    classe qui s'occupe de l'affichage des 
    """
    def __init__(self):
        self.y = 0
        self.y_offset = 0
        self.playlists = []
        self.liste_rects = []   # rect des playlists (même ordre que self.playlists)
        self.playlists_charged = False   # à mettre sur False s'il y a une mise à jour au niveau des playlists (ajout, suppression, modification du nom...)
        self.rect_dimensions = pygame.rect.Rect(20, 20, 600, 900)

        # création différents rects
        self.rect_haut = self.rect_dimensions.copy()
        self.rect_haut.height = 20
        self.rect_haut.y = 0

        self.rect_fond_playlists = self.rect_dimensions.copy()
        self.rect_fond_playlists.height = 700

        rect_fond_creation = self.rect_dimensions.copy()
        rect_fond_creation.y = -700
        rect_fond_creation.x = 0
        self.surface_creation = pygame.surface.Surface((self.rect_dimensions.width, self.rect_dimensions.height - 700), pygame.SRCALPHA)
        pygame.draw.rect(self.surface_creation, "grey15", rect_fond_creation, border_radius=50)
        self.rect_surface_creation = self.surface_creation.get_rect()
        self.rect_surface_creation.bottomleft = self.rect_dimensions.bottomleft

        # chargement police
        self.police = pygame.font.Font("assets/police.otf", 40)

        # chargement boutons
        self.create_btn = self.police.render("créer playlist", True, "white")
        self.create_btn_rect = self.create_btn.get_rect()
        self.create_btn_rect.size = (self.create_btn_rect.width + 20, self.create_btn_rect.height + 20)
        self.create_btn_rect.center = (20 + self.rect_dimensions.width//2, 870) # à changer au besoin

        self.create_text = TextZone(self.police)    # pour la création de la playlist
    
    def reset(self):
        self.playlists = []
        self.playlists_charged = False
        self.y_offset = 0
        self.create_text = TextZone(self.police)
        self.create_text.set_rect(pygame.rect.Rect(30, 735, 575, 80))
        self.create_text.set_largeur_max(575 - 30)
    
    def charger_playlists(self):
        print("chargement playlists...")
        resultat = client.send_message(["get playlists names", user.username])
        if resultat == "crash":
            return "crash"
        else:
            pass
        
        self.playlists = resultat
        self.playlists_charged = True
        print("playlists chargées : " + str(self.playlists))

    def blit(self):
        self.liste_rects = []   # pour éviter un crash
        mouse_pos = pygame.mouse.get_pos()
        resize_screen.draw_rect("grey20", self.rect_dimensions, 50)
        if not self.playlists_charged:
            # affichage texte "chargement"
            texte = self.police.render("chargement...", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = self.rect_dimensions.center
            resize_screen.blit(texte, texte_rect.topleft)
            return None
        
        # blit des playlists
        self.y = 120
        for element in self.playlists:
            texte = element
            if len(texte) > 21:
                texte = texte[:21] + "..."
            texte = self.police.render(texte, True, "white")
            texte_rect = texte.get_rect()
            texte_rect.size = (texte_rect.width + 20, texte_rect.height + 20)
            texte_rect.center = (320, self.y + self.y_offset)

            # test de si ça doit s'afficher ou pas
            if texte_rect.colliderect(self.rect_fond_playlists):
                color = "grey15"
                # on affiche la playlist en gris clair si la souris est dessus
                if texte_rect.collidepoint(resize_screen.get_calcul_mouse_cos(mouse_pos)):
                    color = "grey65"

                # affichage du fond en bleu si la playlist est sélectionnée ou en vert s'il y a une sélection
                if type(internal_state.state_actuel) == internal_state.get_playlist_type():
                    if internal_state.state_actuel.nom_playlist == element and not internal_state.state_actuel.load_via_album and not internal_state.state_actuel.load_via_recherche:
                        color = "dodgerblue3"

                    if internal_state.state_actuel.selection != None:
                        color = "darkolivegreen4"

                resize_screen.draw_rect(color, texte_rect, 20)
                resize_screen.blit(texte, (texte_rect.x + 10, texte_rect.y + 10))
                self.liste_rects.append(texte_rect)
            else:
                texte_rect.bottomright = (-1, -1)   # on met le rect à un endroit pas gênant
                self.liste_rects.append(texte_rect)
            self.y = self.y + texte_rect.height + 20

        # blit éléments création playlist

        resize_screen.blit(self.surface_creation, self.rect_surface_creation.topleft)
        resize_screen.draw_rect("grey10", self.rect_haut)   # non lié à la création de playlist, c'est le truc au dessus

        # changement de la couleur de la zone de texte si on passe la souris dessus
        couleur = "grey50"
        if self.create_text.rect.collidepoint(resize_screen.get_calcul_mouse_cos(mouse_pos)):
            couleur = "grey65"
        resize_screen.draw_rect(couleur, self.create_text.rect, 20)  # texte zone
        resize_screen.blit(self.create_text.get_image(), (self.create_text.rect.x + 10, self.create_text.rect.y + 10))
        resize_screen.draw_rect("dodgerblue3", self.create_btn_rect, 20)
        resize_screen.blit(self.create_btn, (self.create_btn_rect.x + 10, self.create_btn_rect.y + 10))
    
    def listen_entry(self, event):
        if not self.playlists_charged:
            # chargement des playlists
            if self.charger_playlists() == "crash":
                return "crash"
            self.blit()

        self.create_text.work(event)
        if event.type == pygame.MOUSEWHEEL:
            if self.rect_fond_playlists.collidepoint(resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())):
                if event.y < 0:
                    for i in range(abs(event.y)):
                        if self.y + self.y_offset > self.rect_fond_playlists.bottom - 20:
                            self.y_offset -= 45

                elif event.y > 0:
                    for i in range(abs(event.y)):
                        if self.y_offset < 0:
                            self.y_offset += 45

        elif event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                # on check d'abord l'insertion d'un titre dans une playlist
                if type(internal_state.state_actuel) == internal_state.get_playlist_type():
                    if internal_state.state_actuel.selection != None:
                        # test de collision
                        for rect in self.liste_rects:
                            if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                                playlist_choisie = self.playlists[self.liste_rects.index(rect)]
                                resultat = client.send_message(["insert to playlist", user.username, playlist_choisie, internal_state.state_actuel.selection])
                                if resultat == "crash":
                                    return "crash"
                                internal_state.state_actuel.playlist_charged = False
                                #internal_state.state_actuel.selection = None
                                return None
                        #internal_state.state_actuel.playlist_charged = False
                        internal_state.state_actuel.selection = None
                        return None

                # on check la création de playlist
                if self.create_btn_rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    if len(self.create_text.get_text()) > 0:
                        resultat = client.send_message(["create playlist", user.username, self.create_text.get_text()])
                        if resultat == "crash":
                            return "crash"
                        elif resultat == ["existe deja"]:
                            notif_manager.add_notif("la playlist '" + self.create_text.get_text() + "' existe déjà")
                        elif resultat == ["ok"]:
                            notif_manager.add_notif("playlist créée")
                            self.create_text.texte = ""
                            self.playlists_charged = False
                    else:
                        notif_manager.add_notif("le nom de playlist ne peut pas être vide")

                else:
                    # check des playlists si la zone de la création de playlist n'est pas touchée
                    if not self.rect_surface_creation.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        for rect in self.liste_rects:
                            if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                                playlist_choisie = self.playlists[self.liste_rects.index(rect)]
                                internal_state.load_playlist(playlist_choisie, False)

            elif event.button == 3:
                if not self.rect_surface_creation.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    for rect in self.liste_rects:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            # suppression playlist
                            nom_playlist = self.playlists[self.liste_rects.index(rect)]
                            resultat = client.send_message(["delete playlist", user.username, nom_playlist])
                            if resultat == "crash":
                                return "crash"
                            elif resultat == ["ok"]:
                                notif_manager.add_notif("playlist supprimée")
                                self.playlists_charged = False
playlist_manager = ListPlaylistsView()