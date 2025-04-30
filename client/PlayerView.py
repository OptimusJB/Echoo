from Screen import resize_screen
from NotifManager import notif_manager
from Client import client
from User import user
import pygame
pygame.init()

class PlayerView:
    def __init__(self):
        self.rect_dimensions = pygame.rect.Rect(0, 950, 1920, 1080-950)
        self.music_loaded = False
        self.playlist = []
        self.index_play = 0
        self.pause = False
        self.random = False
        self.loop = "false" # = false ou music ou playlist

        self.buttons = {
            "pause":pygame.image.load("assets/pause.png").convert_alpha(),
            "play":pygame.image.load("assets/play.png").convert_alpha(),
            "next":pygame.image.load("assets/next.png").convert_alpha(),
            "previous":pygame.image.load("assets/previous.png").convert_alpha(),
            "random_false":pygame.image.load("assets/random_false.png").convert_alpha(),
            "random_true":pygame.image.load("assets/random_true.png").convert_alpha(),
            "loop_false":pygame.image.load("assets/loop_false.png").convert_alpha(),
            "loop_music":pygame.image.load("assets/loop_music.png").convert_alpha(),
            "loop_playlist":pygame.image.load("assets/loop_playlist.png").convert_alpha()
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
    
    def reset(self):
        self.music_loaded = False
        self.playlist = []
        self.index_play = 0
        self.pause = False
    
    def blit(self):
        resize_screen.draw_rect("grey20", self.rect_dimensions)

        # si musique chargée
        if self.music_loaded:
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
    
    def listen_entry(self, event):
        if self.music_loaded:
            pass


    def play(self, index_music:int):
        resultat = client.send_message(["check quality", user.username, self.playlist[index_music], user.quality])
        if resultat == "crash":
            return "crash"
        elif resultat[0] == "None":
            notif_manager.add_notif("musique non disponible (pas de qualités en dessous de " + user.quality + "), passage à la musique suivante")
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
            pygame.mixer.music.load("cache/cache.ogg")
            pygame.mixer.music.play()

    def load(self, playlist:list, first:str):
        self.reset()
        playlist = list(playlist)
        if first in playlist:
            playlist.remove(first)
        playlist.insert(0, first)
        self.playlist = playlist

        if self.play(0) == "crash":
            return "crash"
        self.music_loaded = True
player = PlayerView()