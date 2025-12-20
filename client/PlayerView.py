import os

from Screen import resize_screen
from NotifManager import notif_manager
from Client import client
from InternalState import internal_state
import random
from User import user
from KeyManager import key_manager
import pygame
pygame.init()

log = True

class PlayerView:
    def __init__(self):
        self.mutagen_works = True
        self.rect_dimensions = pygame.rect.Rect(0, 950, 1920, 1080-950)
        self.police = pygame.font.Font("assets/police.otf", 30)
        self.police_small = pygame.font.Font("assets/police.otf", 20)
        self.music_loaded = False
        self.real_playlist = []     # playlist de base (liste de noms)
        self.playlist = []  # playlist mais qui peut être mélangé
        self.index_play = 0
        self.pause = False
        self.old_random = None  # sert pour self.check_random
        self.random = False
        self.loop = "false" # = false ou music ou playlist
        self.time_music = 0    # ticks pygame. Utilisé par la barre
        self.sound_length = None    # utilisé pour le calcul de la longueur
        self.time_pause = 0
        self.piste_infos = None

        self.icone_base = None

        self.rect_barre_fond = pygame.rect.Rect(0, 0, 650, 10)
        self.rect_barre_fond.center = (self.rect_dimensions.centerx, self.rect_dimensions.centery + 30)

        self.rect_hitbox_barre = self.rect_barre_fond.copy()
        self.rect_hitbox_barre.height = 30  # à changer au besoin
        self.rect_hitbox_barre.center = (self.rect_dimensions.centerx, self.rect_dimensions.centery + 30)

        self.old_music = None   # utilisé par self.play() (pour ne pas recharger exactement la même musique)
        self.old_quality = None

        self.buttons = {
            "pause":pygame.image.load("assets/pause.png").convert_alpha(),
            "play":pygame.image.load("assets/play.png").convert_alpha(),
            "next":pygame.image.load("assets/next.png").convert_alpha(),
            "previous":pygame.image.load("assets/previous.png").convert_alpha(),
            "random_false":pygame.image.load("assets/random_false.png").convert_alpha(),
            "random_true":pygame.image.load("assets/random_true.png").convert_alpha(),
            "loop_false":pygame.image.load("assets/loop_false.png").convert_alpha(),
            "loop_music":pygame.image.load("assets/loop_music.png").convert_alpha(),
            "loop_playlist":pygame.image.load("assets/loop_playlist.png").convert_alpha(),
            "moins":pygame.image.load("assets/moins.png").convert_alpha(),
            "plus":pygame.image.load("assets/plus.png").convert_alpha()
        }

        # resize
        for element in self.buttons.keys():
            self.buttons[element] = pygame.transform.smoothscale(self.buttons[element], (50, 50))

        # création des rects des boutons
        self.buttons_rect = {}
        for element in self.buttons.keys():
            self.buttons_rect[element] = self.buttons[element].get_rect()

        # changement des positions des rects
        self.buttons_rect["play"].center = (self.rect_dimensions.centerx, self.rect_dimensions.centery - 25)
        self.buttons_rect["pause"].center = self.buttons_rect["play"].center
        self.buttons_rect["next"].topleft = (self.buttons_rect["play"].right + 20 + 20, self.buttons_rect["play"].top)
        self.buttons_rect["previous"].topright = (self.buttons_rect["play"].left - 17 - 20, self.buttons_rect["play"].top)

        self.buttons_rect["random_false"].topright = (self.buttons_rect["previous"].left - 17 - 20, self.buttons_rect["play"].top)
        self.buttons_rect["random_true"] = self.buttons_rect["random_false"].copy()

        self.buttons_rect["loop_false"].topleft = (self.buttons_rect["next"].right + 20 + 20, self.buttons_rect["play"].top)
        self.buttons_rect["loop_music"] = self.buttons_rect["loop_false"].copy()
        self.buttons_rect["loop_playlist"] = self.buttons_rect["loop_false"].copy()

        self.buttons_rect["moins"].midright = (self.rect_dimensions.right - 20, self.rect_dimensions.centery)
        self.buttons_rect["plus"].midright = (self.buttons_rect["moins"].left - 100, self.rect_dimensions.centery)
    
    def reset(self):
        if pygame.mixer.music.get_busy():   # pour la fin de playlist
            pygame.mixer.music.stop()
        self.music_loaded = False
        self.real_playlist = []
        self.playlist = []
        self.index_play = 0
        self.pause = False
        self.old_random = None
        self.time_music = 0
        #self.sound_length = None

    def get_music_length(self):
        # test avec mutagen d'abord (beaucoup plus rapide que pygame)
        try:
            if self.mutagen_works:
                from mutagen.oggvorbis import OggVorbis
                if self.sound_length == None:
                    self.sound_length = OggVorbis("cache/cache.ogg")
                return self.sound_length.info.length * 1000 # return un temps en ms

        except Exception as error:
            print("échec de la récupération de la longueur avec mutagen : " + str(error))
            print("utilisation de pygame à la place")
            self.mutagen_works = False
            self.sound_length = None

        if self.sound_length == None:
            self.sound_length = pygame.mixer.Sound("cache/cache.ogg")
        return self.sound_length.get_length()*1000

    def affichage_full_screen(self):
        # on check si user.load_image est à True et si l'image existe (important si user.load_image était auparavant à False (cache.png pas forcément chargé)
        if not user.load_images or not "cache.png" in os.listdir("cache/"):
            return
        image = pygame.image.load("cache/cache.png").convert_alpha()
        image = pygame.transform.smoothscale(image, (700, 700))
        rect_image = image.get_rect()
        rect_image.center = (1920//2, 1080//2)

        fond = pygame.surface.Surface((1920, 1080))
        fond.fill((0,0,0))
        fond.set_alpha(255//2)
        resize_screen.blit(fond, (0,0))
        resize_screen.blit(image, rect_image)

        clock = pygame.time.Clock()
        boucle = True
        while boucle:
            resize_screen.flip()
            for event in pygame.event.get():
                if event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        if not rect_image.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                            boucle = False
            clock.tick(30)
    def previous_music(self):
        if self.loop == "music" or pygame.time.get_ticks() - self.time_music >= 5000:
            #print("a", self.loop, pygame.time.get_ticks() - self.time_music)
            if self.play(self.index_play) == "crash":
                return "crash"
        elif self.loop == "playlist":
            self.index_play = (self.index_play - 1) % len(self.playlist)
            if self.play(self.index_play) == "crash":
                return "crash"
        elif self.loop == "false":
            self.index_play = self.index_play - 1
            if self.index_play < 0:
                self.reset()
            else:
                if self.play(self.index_play) == "crash":
                    return "crash"
        else:
            raise ValueError("problème avec la valeur de self.loop")

    def next_music(self):
        if self.loop == "music":
            if self.play(self.index_play) == "crash":
                return "crash"
        elif self.loop == "playlist":
            self.index_play = (self.index_play + 1) % len(self.playlist)
            if self.play(self.index_play) == "crash":
                return "crash"
        elif self.loop == "false":
            self.index_play = self.index_play + 1
            if self.index_play >= len(self.playlist):
                self.reset()
            else:
                if self.play(self.index_play) == "crash":
                    return "crash"
        else:
            raise ValueError("problème avec la valeur de self.loop")

    def check_random(self):
        """
        aléatoire : la piste en cours de lecture est mise en premier, le reste est mélangé
        pas aléatoire : l'index est modifié pour qu'il soit en raccord avec la piste en cours de lecture
        """
        if self.old_random == self.random:
            return None
        if not self.random:
            piste_actuelle = self.playlist[self.index_play]
            self.playlist = list(self.real_playlist)
            self.index_play = self.playlist.index(piste_actuelle)
        else:
            piste_actuelle = self.playlist[self.index_play]
            self.playlist.remove(piste_actuelle)
            random.shuffle(self.playlist)
            self.playlist.insert(0, piste_actuelle)
            self.index_play = 0

        self.old_random = self.random

    def convert_time(self, temps):
        """
        le temps fourni est en secondes
        """
        temps = int(temps)
        minutes = 0
        secondes = temps
        minutes = secondes // 60
        secondes = secondes % 60
        return str(minutes) + ":" + str(secondes).zfill(2)

    
    def blit(self):
        """
        cette méthode fait également d'autres truc à part le blit (test de si la musique est finie)
        """
        resize_screen.draw_rect("grey20", self.rect_dimensions)

        # si musique chargée
        if self.music_loaded:
            #print("temps : " + str(pygame.mixer.music.get_pos()))

            # blit des éléments
            if self.pause:
                resize_screen.blit(self.buttons["play"], self.buttons_rect["play"].topleft)
            else:
                resize_screen.blit(self.buttons["pause"], self.buttons_rect["pause"].topleft)
            resize_screen.blit(self.buttons["next"], self.buttons_rect["next"].topleft)
            resize_screen.blit(self.buttons["previous"], self.buttons_rect["previous"].topleft)

            if self.random:
                resize_screen.blit(self.buttons["random_true"], self.buttons_rect["random_true"].topleft)
            else:
                resize_screen.blit(self.buttons["random_false"], self.buttons_rect["random_false"].topleft)

            if self.loop == "false":
                resize_screen.blit(self.buttons["loop_false"], self.buttons_rect["loop_false"].topleft)
            elif self.loop == "music":
                resize_screen.blit(self.buttons["loop_music"], self.buttons_rect["loop_music"].topleft)
            elif self.loop == "playlist":
                resize_screen.blit(self.buttons["loop_playlist"], self.buttons_rect["loop_playlist"].topleft)
            else:
                raise ValueError("problème avec la valeur de self.loop")

            # blit de la barre (et non, je ne parle pas de la prof d'allemand)
            resize_screen.draw_rect("grey30", self.rect_barre_fond, 50)

            rect_barre = self.rect_barre_fond.copy()
            decalage = pygame.time.get_ticks()
            if self.pause:
                decalage = self.time_pause
            rect_barre.width = min(650, int(650/self.get_music_length()*(decalage - self.time_music)))

            # test de si la souris est sur l'écran
            color = "white"
            if self.rect_hitbox_barre.collidepoint(resize_screen.get_calcul_mouse_cos(pygame.mouse.get_pos())):
                color = "dodgerblue3"
            resize_screen.draw_rect(color, rect_barre, 50)

            # blit du temps
            temps_total = self.get_music_length()/1000  # en secondes
            if self.pause:
                temps = self.time_pause - self.time_music
            else:
                temps = pygame.time.get_ticks() - self.time_music

            temps_image = self.police.render(self.convert_time(temps//1000), True, "white")
            temps_rect = temps_image.get_rect()
            temps_rect.midright = (self.rect_barre_fond.x - 20, self.rect_barre_fond.centery)
            resize_screen.blit(temps_image, temps_rect.topleft)

            temps_image = self.police.render(self.convert_time(temps_total), True, "white")
            temps_rect = temps_image.get_rect()
            temps_rect.midleft = (self.rect_barre_fond.right + 20, self.rect_barre_fond.centery)
            resize_screen.blit(temps_image, temps_rect.topleft)

            # blit des infos de la piste
            # image
            rect_image = self.piste_infos[0].get_rect()
            rect_image.midleft = (self.rect_dimensions.x + 20, self.rect_dimensions.centery)
            resize_screen.blit(self.piste_infos[0], rect_image)

            # titre
            titre_final = self.playlist[self.index_play]
            if len(titre_final) > 22:
                titre_final = titre_final[:22] + "..."

            titre = self.police.render(titre_final, True, "white")
            titre_rect = titre.get_rect()
            titre_rect.midleft = (rect_image.centerx + 50, rect_image.centery - 10)
            resize_screen.blit(titre, titre_rect.topleft)

            # artiste
            artiste_final = self.piste_infos[1]
            if len(artiste_final) > 30:
                artiste_final = artiste_final[:30] + "..."
            artiste = self.police_small.render(artiste_final, True, "white")
            artiste_rect = artiste.get_rect()
            artiste_rect.topleft = (titre_rect.x, titre_rect.bottom + 1)
            resize_screen.blit(artiste, artiste_rect.topleft)

            # blit des éléments du volume
            resize_screen.blit(self.buttons["moins"], self.buttons_rect["moins"].topleft)
            resize_screen.blit(self.buttons["plus"], self.buttons_rect["plus"].topleft)
            texte = self.police.render(str(int(user.volume*100)) + "%", True, "white")
            texte_rect = texte.get_rect()
            texte_rect.center = (self.buttons_rect["moins"].left - 50, self.rect_dimensions.centery)
            resize_screen.blit(texte, texte_rect.topleft)

            # test de si la musique est finie
            if not self.pause and not pygame.mixer.music.get_busy():
                # la musique est finie
                if self.next_music() == "crash":
                    return "crash"

    def mise_en_pause(self):
        if self.pause:
            pygame.mixer.music.unpause()
        else:
            pygame.mixer.music.pause()
        self.pause = not self.pause

        # mise à jour de la variable pour la barre
        if self.pause:
            self.time_pause = pygame.time.get_ticks()
        else:
            self.time_music = self.time_music + (pygame.time.get_ticks() - self.time_pause)
            self.time_pause = 0

    def switch_random(self):
        self.random = not self.random
        self.check_random()

    def switch_loop(self):
        if self.loop == "false":
            self.loop = "music"
        elif self.loop == "music":
            self.loop = "playlist"
        elif self.loop == "playlist":
            self.loop = "false"
        else:
            raise ValueError("problème avec la valeur de self.loop")

    def volume_plus(self):
        user.volume = round(user.volume + 0.1, 2)
        if user.volume > 1:
            user.volume = 1.0
        user.save_settings()
        pygame.mixer.music.set_volume(user.volume)

    def volume_moins(self):
        user.volume = round(user.volume - 0.1, 2)
        if user.volume < 0:
            user.volume = 0.0
        user.save_settings()
        pygame.mixer.music.set_volume(user.volume)

    def listen_entry(self, event):
        if self.music_loaded:
            if event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:
                    artiste_final = self.piste_infos[1]
                    if len(artiste_final) > 30:
                        artiste_final = artiste_final[:30] + "..."

                    if pygame.rect.Rect((110, 1029), self.police_small.size(artiste_final)).collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        # artiste touché, on charge sa page
                        internal_state.load_artiste(self.piste_infos[1])

                    elif self.buttons_rect["play"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        self.mise_en_pause()

                    elif self.buttons_rect["random_false"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        self.switch_random()

                    elif self.buttons_rect["loop_false"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        self.switch_loop()

                    elif self.buttons_rect["next"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        if self.next_music() == "crash":
                            return "crash"

                    elif self.buttons_rect["previous"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        if self.previous_music() == "crash":
                            return "crash"

                    elif self.rect_hitbox_barre.collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        # changement de la position
                        mouse_pos_x = resize_screen.get_calcul_mouse_cos(event.pos)[0]
                        barre_x = mouse_pos_x - self.rect_barre_fond.x
                        pos_musique = min(self.get_music_length()/650*barre_x, self.get_music_length())
                        pygame.mixer.music.set_pos(pos_musique/1000)    # le son se met automatiquement à jour
                        if self.pause:
                            self.time_music = self.time_pause - pos_musique
                        else:
                            self.time_music = pygame.time.get_ticks() - pos_musique

                    elif pygame.rect.Rect(20, 975, 80, 80).collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        # image full screen
                        self.affichage_full_screen()

                    elif self.buttons_rect["plus"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        self.volume_plus()

                    elif self.buttons_rect["moins"].collidepoint(resize_screen.get_calcul_mouse_cos(event.pos)):
                        self.volume_moins()

            elif event.type == pygame.KEYDOWN:
                if pygame.key.get_pressed()[pygame.K_LSHIFT]:
                    if event.key == pygame.K_RIGHT:
                        if self.next_music() == "crash":
                            return "crash"
                    elif event.key == pygame.K_LEFT:
                        if self.previous_music() == "crash":
                            return "crash"
                    elif event.key == pygame.K_UP:
                        self.volume_plus()
                    elif event.key == pygame.K_DOWN:
                        self.volume_moins()
                    elif event.key == pygame.K_SPACE:
                        self.mise_en_pause()
                    elif event.key == pygame.K_r:
                        self.switch_random()
                    elif event.key == pygame.K_l:
                        self.switch_loop()

    def get_icone_base(self):
        if self.icone_base == None:
            self.icone_base = pygame.image.load("assets/icone_base.png").convert_alpha()
            self.icone_base = pygame.transform.smoothscale(self.icone_base, (80, 80))
        return self.icone_base

    def play(self, index_music:int, disable_loop=False):
        if disable_loop:
            # on enlève la boucle pour éviter le blocage si aucune musique ne supporte la qualité choisie
            self.loop = "false"
        self.pause = False
        if pygame.mixer.music.get_busy():
            pygame.mixer.music.stop()

        if self.playlist[index_music] == self.old_music and user.quality == self.old_quality:
            # on charge directement la musique, on suppose que self.piste_infos est le même
            pygame.mixer.music.unload()
            self.get_music_length()  # on charge en mémoire
            pygame.mixer.music.load("cache/cache.ogg")
            pygame.mixer.music.play()
            self.time_music = pygame.time.get_ticks()
            self.music_loaded = True
            return None

        self.sound_length = None
        # récupération de la musique
        resultat = client.send_message(["check quality", user.username, self.playlist[index_music], user.quality])
        if resultat == "crash":
            return "crash"
        elif resultat[0] == "None":
            notif_manager.add_notif("musique non disponible (pas de qualités en dessous de " + user.quality + "), passage à la musique suivante")
            if self.next_music() == "crash":    # note : le logiciel peut crash recursion limit si la playlist est trop grande
                return "crash"
            return None
        else:
            if resultat[0] != user.quality:
                notif_manager.add_notif("qualité " + user.quality + " non disponible. qualité actuelle : " + resultat[0])

            quality = resultat[0]
            # chargement de la musique
            resultat = client.ask_music(user.username, self.playlist[index_music], quality)
            if resultat == "crash":
                return "crash"

            # enregistrement de la musique dans le cache
            pygame.mixer.music.unload()
            fichier = open("cache/cache.ogg", "wb")
            fichier.write(resultat)
            fichier.close()
            resultat = None  # on libère la mémoire

            # musique
            self.piste_infos = None
            # récupération des infos de la musique
            resultat = client.send_message(["get music infos", user.username, self.playlist[index_music]])
            if resultat == "crash":
                return "crash"
            self.piste_infos = [None] + resultat

            # récupération de l'image de la musique
            musique = self.playlist[index_music]
            if user.load_images:
                # check si une image du même nom est dans le cache (économie de données)
                resultat = client.send_message(["get cover name", user.username, musique])
                if resultat == "crash":
                    return "crash"

                # modification de la chaine de caractère comme dans PlaylistView
                resultat = "'" + resultat[0] + "'" + ".png"
                resultat = resultat.replace("/", "&sl&")

                if resultat in os.listdir("cache/"):
                    if log:
                        print("utilisation du fichier au même nom présent dans le cache")
                    # on copie le fichier et on l'appelle "cache.png"
                    fichier = open("cache/" + resultat, "rb")
                    fichier_read = fichier.read()
                    fichier.close()

                    fichier = open("cache/cache.png", "wb")
                    fichier.write(fichier_read)
                    fichier.close()

                    resultat = None  # on libère la mémoire
                    fichier_read = None

                else:
                    if log:
                        print("récupération de l'image de la musique jouée sur le serveur")
                    resultat = client.ask_music_image(user.username, musique)
                    if resultat == "crash":
                        return "crash"

                    # écriture du fichier dans le cache
                    # print("ecriture")
                    fichier = open("cache/cache.png", "wb")
                    fichier.write(resultat)
                    fichier.close()
                    resultat = None  # on libère la mémoire

                # chargement dans le dictionnaire
                self.piste_infos[0] = pygame.image.load("cache/cache.png").convert_alpha()
                self.piste_infos[0] = pygame.transform.smoothscale(self.piste_infos[0], (80, 80))
            else:
                self.piste_infos[0] = self.get_icone_base()

            self.get_music_length()  # on charge en mémoire
            pygame.mixer.music.load("cache/cache.ogg")
            pygame.mixer.music.play()
            self.time_music = pygame.time.get_ticks()

            self.old_music = self.playlist[index_music]
            self.old_quality = user.quality

            self.music_loaded = True

    def load(self, playlist:list, first:str):
        self.reset()
        self.real_playlist = list(playlist)
        self.playlist = list(playlist)

        self.index_play = self.playlist.index(first)
        self.check_random()

        if self.play(self.index_play, disable_loop=True) == "crash":
            return "crash"

        # lancement de la playlist
player = PlayerView()