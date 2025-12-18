from User import user
from Client import client
from Screen import resize_screen
import os
from Scroller import Scroller
import pygame
pygame.init()

log = True
class PlaylistView:
    def __init__(self, internal_state, nom_playlist:str, load_via_album=False, load_via_recherche=False):
        # load_via_album = True ou load_via_recherche != True, pas les deux (load_via_recherche est un str)
        self.selection = None   # pour l'ajout dans une playlist, c'est un str
        self.selection_move = None # pour le déplacement, c'est un index
        self.selection_move_image = None
        self.internal_state = internal_state
        self.y = 0
        self.y_offset = 0
        self.police = pygame.font.Font("assets/police.otf", 40)
        self.police_mid = pygame.font.Font("assets/police.otf", 30)   # la même mais en plus petit
        self.police_small = pygame.font.Font("assets/police.otf", 20)   # la même mais en encore plus petit
        self.nom_playlist = nom_playlist
        self.playlist = {}  # de la forme {nom:[image, artiste, annee, album]}
        self.rect_dimensions = pygame.rect.Rect(20+600+10, 100, 1920-20-600-20, 900-80)
        self.rects_cache = [pygame.rect.Rect(20+600+10, 0, 1920-20-600-20, 100), pygame.rect.Rect(20+600+10, 100+900-80, 1920-20-600-20, 30)]
        self.playlist_charged = False
        self.icone_base = None
        self.liste_noms_musiques = []
        self.load_via_album = load_via_album # détermine si la playlist est chargée via une playlist ou via un nom d'album
        self.load_via_recherche = load_via_recherche    # égal à True ou un str représentant la recherche

        self.dico_cover = {}    # clé = nom cover, valeur = tuple (image_de_base, image_dimension_80_80)
        self.musics_cover = {}  # clé = musique, valeur = nom cover

        # définition rects cliquables
        self.rects_image = []
        self.rects_artiste = []
        self.rects_play = []
        self.rects_titre = []
        self.rects_album = []

        # temps offset
        self.temps_offset = 0

        # scroller
        self.scroller = Scroller(pygame.rect.Rect(1920 - 50, 0, 25, 50), self.rect_dimensions.top + 25 + 15, self.rect_dimensions.bottom - 40)

    def delete_cache_png(self):
        for element in os.listdir("cache/"):
            if element[len(element)-4:] == ".png" and not element == "cache.png":
                os.remove("cache/" + element)

    def old_charger_playlist(self):
        self.dico_cover = {}
        self.musics_cover = {}
        self.selection = None
        self.selection_move = None
        self.playlist = {}

        # suppression des potentielles images du cache
        #self.delete_cache_png()

        # check de load_via_recherche
        if not self.load_via_recherche == False:
            resultat = client.send_message(["get musics with", user.username, self.load_via_recherche])
            if resultat == "crash":
                return "crash"
            self.liste_noms_musiques = resultat # c'est une liste

        # check de load_via_album
        elif self.load_via_album:
            resultat = client.send_message(["get playlist content via album", user.username, self.nom_playlist])
            if resultat == "crash":
                return "crash"
            self.liste_noms_musiques = resultat # c'est une liste

        else:
            # récupération de la liste des musiques de la playlist
            resultat = client.send_message(["get playlist content", user.username, self.nom_playlist])
            if resultat == "crash":
                return "crash"
            self.liste_noms_musiques = resultat # c'est une liste

        # chargement des infos des musiques
        time = 0
        for musique in self.liste_noms_musiques:
            resultat = client.send_message(["get music infos", user.username, musique])
            if resultat == "crash":
                return "crash"

            # date str --> int
            resultat[1] = int(resultat[1])
            self.playlist[musique] = [None] + resultat

            # chargement de l'image (stocké dans cache avec le nom de la musique)
            if user.load_images:
                # récupération nom de l'image
                nom_image = "'" + client.send_message(["get cover name", user.username, musique])[0] + "'"
                nom_image = nom_image.replace("/", "&sl&")
                if nom_image == "crash":
                    return "crash"

                if not nom_image in self.dico_cover.keys():
                    # check si l'image est toujours dans le cache
                    if log:
                        print(nom_image + " :")
                    if nom_image + ".png" in os.listdir("cache/"):
                        if log:
                            print("image déjà dans le cache")
                    else:
                        if log:
                            print("importation image")
                        resultat = client.ask_music_image(user.username, musique)
                        if resultat == "crash":
                            return "crash"

                        # écriture du fichier dans le cache
                        fichier = open("cache/" + nom_image + ".png", "wb")
                        fichier.write(resultat)
                        fichier.close()
                        resultat = None # on libère la mémoire

                    self.dico_cover[nom_image] = pygame.image.load("cache/" + nom_image + ".png").convert_alpha()
                    self.dico_cover[nom_image] = (self.dico_cover[nom_image], pygame.transform.smoothscale(self.dico_cover[nom_image], (80, 80)))

                self.musics_cover[musique] = nom_image

                # chargement dans le dictionnaire
                self.playlist[musique][0] = self.dico_cover[nom_image][1]
            else:
                self.playlist[musique][0] = self.get_icone_base()

        self.playlist_charged = True

    def check_images_opti(self):
        """
        fonction qui demande et charge automatiquement les images des musiques de la playlist
        """
        a_charger = []
        # on check s'il y a des images à demander par requête
        if user.load_images:
            for musique in self.liste_noms_musiques:
                nom_image = self.playlist[musique][4]
                if not nom_image in self.dico_cover.keys() and not nom_image in a_charger:
                    # check si l'image est toujours dans le cache
                    if log:
                        print(nom_image + " :")
                    if nom_image + ".png" in os.listdir("cache/"):
                        if log:
                            print("image déjà dans le cache, donc on l'importe directement dans dico cover")
                        self.dico_cover[nom_image] = pygame.image.load("cache/" + nom_image + ".png").convert_alpha()
                        self.dico_cover[nom_image] = (self.dico_cover[nom_image],pygame.transform.smoothscale(self.dico_cover[nom_image],(80, 80)))
                    else:
                        if log:
                            print("importation image")
                        a_charger.append(nom_image)

            # on envoie la requête
            if len(a_charger) > 0:
                if log:
                    print("envoi d'une requête pour récupérer les images manquantes")
                    print(a_charger)
                resultat = client.send_message(["get images opti", user.username] + a_charger, True)
                if resultat == "crash":
                    return "crash"

                # on charge les images
                for i in range(len(a_charger)):
                    # écriture du fichier dans le cache
                    fichier = open("cache/" + a_charger[i] + ".png", "wb")
                    fichier.write(resultat[i])
                    fichier.close()

                    self.dico_cover[a_charger[i]] = pygame.image.load("cache/" + a_charger[i] + ".png").convert_alpha()
                    self.dico_cover[a_charger[i]] = (self.dico_cover[a_charger[i]], pygame.transform.smoothscale(self.dico_cover[a_charger[i]], (80, 80)))

            resultat = None  # on libère la mémoire

        # on refait un parcours pour charger les images
        for musique in self.liste_noms_musiques:
            if user.load_images:
                nom_image = self.playlist[musique][4]

                self.musics_cover[musique] = nom_image

                # chargement dans le dictionnaire
                self.playlist[musique][0] = self.dico_cover[nom_image][1]
            else:
                self.playlist[musique][0] = self.get_icone_base()

    def charger_playlist(self):
        self.dico_cover = {}
        self.musics_cover = {}
        self.selection = None
        self.selection_move = None
        self.playlist = {}

        # check de load_via_recherche
        if not self.load_via_recherche == False:
            resultat = client.send_message(["get musics with opti", user.username, self.load_via_recherche])
            if resultat == "crash":
                return "crash"

        # check de load_via_album
        elif self.load_via_album:
            resultat = client.send_message(["get playlist content via album opti", user.username, self.nom_playlist])
            if resultat == "crash":
                return "crash"

        else:
            # récupération de la liste des musiques de la playlist
            resultat = client.send_message(["get playlist content opti", user.username, self.nom_playlist])
            if resultat == "crash":
                return "crash"

        for i in range(len(resultat)):
            resultat[i] = resultat[i].split("&slinfo&")

        self.liste_noms_musiques = []

        # on met les infos dans self.playlist
        for musique in resultat:
            self.liste_noms_musiques.append(musique[0])

            # date str --> int
            musique[2] = int(musique[2])
            self.playlist[musique[0]] = [None] + musique[1:]

        # on charge les images
        if self.check_images_opti() == "crash":
            return "crash"

        self.playlist_charged = True

    def get_icone_base(self):
        if self.icone_base == None:
            self.icone_base = pygame.image.load("assets/icone_base.png").convert_alpha()
            self.icone_base = pygame.transform.smoothscale(self.icone_base, (80, 80))
        return self.icone_base

    def maj_offset(self):
        if self.temps_offset > 0:
            for i in range((abs(self.temps_offset) // 5 + 1)):
                if self.y_offset < 0:   # condition scroll
                    self.y_offset += 25
            for i in range((abs(self.temps_offset) // 5) + 1):
                if self.temps_offset > 0:
                    self.temps_offset -= 1

        elif self.temps_offset < 0:
            for i in range((abs(self.temps_offset) // 5 + 1)):
                if self.y + self.y_offset > self.rect_dimensions.bottom - 20:   # condition scroll
                    self.y_offset -= 25
            for i in range((abs(self.temps_offset) // 5) + 1):
                if self.temps_offset < 0:
                    self.temps_offset += 1


    def blit(self):
        # mise à jour du offset
        if self.scroller.clicked:
            self.temps_offset = 0
            pourcentage = self.scroller.get_pourcentage_scroll()
            minimum = 0
            maximum = max(self.y - (self.rect_dimensions.bottom - 20), 0)  # ça met 0 si l'autre est négatif (pas assez de musiques)
            self.y_offset = maximum / 100 * pourcentage * -1

        self.maj_offset()

        resize_screen.draw_rect("grey30", self.rect_dimensions, 50) # fond

        # blit du nom de la playlist
        titre = self.police.render(self.nom_playlist, True, "white")
        titre_rect = titre.get_rect()
        titre_rect.center = (self.rect_dimensions.centerx, 200 + self.y_offset)
        fond_titre = titre_rect.copy()
        fond_titre.size = (fond_titre.width + 80, fond_titre.height + 80)
        fond_titre.topleft = (fond_titre.x - 40, fond_titre.y - 40)
        resize_screen.draw_rect("grey20", fond_titre, 50)
        resize_screen.blit(titre, titre_rect.topleft)

        # blit du cache en haut pour le titre au cas où le offset n'est pas égal à 0
        resize_screen.draw_rect("grey10", self.rects_cache[0])

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
        self.rects_album = []

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
        for musique in self.liste_noms_musiques:
            compteur += 1
            # blit du potentiel fond différent
            rect_titre = pygame.rect.Rect(600 + 20 + 10, self.y - 10 + self.y_offset, 1920-20-600-20, 80 + 10 + 10)
            if rect_titre.collidepoint(mouse_pos):
                resize_screen.draw_rect("grey65", rect_titre, 20)
            self.rects_titre.append(rect_titre)

            # blit des infos
            # compteur
            if not rect_titre.collidepoint(mouse_pos):
                texte = self.police_mid.render(str(compteur), True, "white")
                resize_screen.blit(texte, (650, self.y + 20 + self.y_offset))

            # image
            image_rect = self.playlist[musique][0].get_rect()
            image_rect.topleft = (750, self.y + self.y_offset)
            self.rects_image.append(image_rect)

            if image_rect.colliderect(self.rect_dimensions):
                resize_screen.blit(self.playlist[musique][0], image_rect)

            # titre
            titre_final = musique
            if len(musique) > 25:
                titre_final = titre_final[:25] + "..."

            titre = self.police_mid.render(titre_final, True, "white")
            titre_rect = titre.get_rect()
            titre_rect.midleft = (image_rect.centerx + 50, image_rect.centery-10)

            if titre_rect.colliderect(self.rect_dimensions):
                resize_screen.blit(titre, titre_rect.topleft)

            # artiste
            artiste_final = self.playlist[musique][1]
            if len(artiste_final) > 35:
                artiste_final = artiste_final[:35] + "..."
            artiste = self.police_small.render(artiste_final, True, "white")
            artiste_rect = artiste.get_rect()
            artiste_rect.topleft = (titre_rect.x, titre_rect.bottom + 1)
            self.rects_artiste.append(artiste_rect)

            if artiste_rect.colliderect(self.rect_dimensions):
                resize_screen.blit(artiste, artiste_rect.topleft)

            # album
            album_final = self.playlist[musique][3]
            if len(album_final) > 28:
                album_final = album_final[:28] + "..."
            album = self.police_mid.render(album_final, True, "white")
            album_rect = album.get_rect()
            album_rect.midleft = (1350, image_rect.centery)
            self.rects_album.append(album_rect)

            if album_rect.colliderect(self.rect_dimensions):
                resize_screen.blit(album, album_rect.topleft)

            # bouton play (ne s'affiche que quand on passe la souris sur le titre)
            rect_triangle = triangle.get_rect()
            rect_triangle.midright = (image_rect.x - 25, image_rect.centery)
            self.rects_play.append(rect_triangle)

            if rect_titre.collidepoint(mouse_pos):
                resize_screen.blit(triangle, rect_triangle.topleft)

            self.y = self.y + 100

        # blit des caches en haut et en bas
        resize_screen.draw_rect("grey10", self.rects_cache[0])
        resize_screen.draw_rect("grey10", self.rects_cache[1])

        # test pour la sélection de déplacement
        if pygame.mouse.get_pressed()[0] and self.selection_move != None:
            rect_selection = self.selection_move_image.get_rect()
            rect_selection.center = resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())
            resize_screen.blit(self.selection_move_image, rect_selection.topleft)

        # blit du scroller
        #print(self.y, self.y_offset)
        if not self.scroller.clicked:
            self.scroller.pourcentage_to_scroll(self.scroller.get_pourcentage_scroll(0, max(self.y - (self.rect_dimensions.bottom - 20), 0), max(self.y_offset * -1, 0)))
        self.scroller.blit()

    def listen_entry(self, event):
        # check du chargement de la playlist
        if not self.playlist_charged:
            # chargement de la playlist
            if self.charger_playlist() == "crash":
                return "crash"
            self.blit()

        # listen_entry du scroller
        self.scroller.listen_entry(event)

        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1 and not self.scroller.clicked:
                if self.rect_dimensions.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                    # test des rects play
                    for rect in self.rects_play:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            index_rect = self.rects_play.index(rect)

                            from PlayerView import player   # chargement ici pour éviter le circular import
                            if player.load(self.liste_noms_musiques, self.liste_noms_musiques[index_rect]) == "crash":
                                return "crash"
                            return None

                    # test des rects album
                    for rect in self.rects_album:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            index_rect = self.rects_album.index(rect)
                            # on charge la playlist en lien avec l'album
                            self.internal_state.state_actuel = PlaylistView(self.internal_state, self.playlist[self.liste_noms_musiques[index_rect]][3], True)
                            return None

                    # test des rects artistes
                    for rect in self.rects_artiste:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            index_rect = self.rects_artiste.index(rect)
                            # on charge la page de l'artiste
                            self.internal_state.load_artiste(self.playlist[self.liste_noms_musiques[index_rect]][1])
                            return None

                    # test des rects de fond pour le déplacement si les deux autres n'ont rien retourné
                    if not self.internal_state.state_actuel.load_via_album and self.internal_state.state_actuel.load_via_recherche == False:
                        for rect in self.rects_titre:
                            if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                                index_rect = self.rects_titre.index(rect)
                                self.selection_move = index_rect
                                if user.load_images:
                                    self.selection_move_image = self.dico_cover[self.musics_cover[self.liste_noms_musiques[index_rect]]][1]
                                else:
                                    self.selection_move_image = self.get_icone_base()
                                self.selection_move_image = pygame.transform.smoothscale(self.selection_move_image, (80, 80))
                                self.selection_move_image.set_alpha(255//2)

            elif event.button == 3:
                # test des rects de fond
                if not self.load_via_album and not self.load_via_recherche:
                    for rect in self.rects_titre:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            index_rect = self.rects_titre.index(rect)
                            # on supprime la playlist et on recharge
                            nom_musique = self.liste_noms_musiques[index_rect]
                            resultat = client.send_message(["delete from playlist", user.username, self.nom_playlist, index_rect])
                            if resultat == "crash":
                                return "crash"
                            self.selection = None
                            self.selection_move = None
                            self.playlist_charged = False
                            return None

            elif event.button == 2:
                # test des rects de fond
                for rect in self.rects_titre:
                    if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        index_rect = self.rects_titre.index(rect)
                        self.selection = self.liste_noms_musiques[index_rect]

        elif event.type == pygame.MOUSEBUTTONUP:
            if event.button == 1:
                if self.selection_move != None:
                    # test du rect touché
                    for rect in self.rects_titre:
                        if rect.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            index_rect = self.rects_titre.index(rect)

                            if not index_rect == self.selection_move:
                                # envoi du move au serveur
                                resultat = client.send_message(["deplacement", user.username, self.nom_playlist, self.selection_move, index_rect])
                                if resultat == "crash":
                                    return "crash"
                                self.playlist_charged = False
                                return None
                    self.selection_move = None

        elif event.type == pygame.MOUSEWHEEL:
            if self.rect_dimensions.collidepoint(resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())):
                #print(self.y, self.y_offset, self.rect_dimensions.height)
                if event.y < 0:
                    for i in range(abs(event.y)):
                        if self.y + self.y_offset > self.rect_dimensions.bottom - 20:
                        #if self.rects_image[len(self.rects_image)-1].y + 80 > self.rect_dimensions.height + 100:
                            self.temps_offset -= 5
                            #self.y_offset -= 45

                elif event.y > 0:
                    for i in range(abs(event.y)):
                        if self.y_offset < 0:
                            self.temps_offset += 5
                            #self.y_offset += 45