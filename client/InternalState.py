from Rechercher import Rechercher
from ArtisteView import ArtisteView
from PlaylistView import PlaylistView
from ListArtisteView import ListArtisteView
from Settings import Settings

class InternalState:
    def __init__(self):
        self.state_actuel = Rechercher(self)

    def reset(self):
        self.state_actuel = Rechercher(self)

    def load_rechercher(self):
        self.state_actuel = Rechercher(self)

    def get_rechercher_type(self):
        return Rechercher

    def load_liste_artiste(self, recherche):
        self.state_actuel = ListArtisteView(self, recherche)

    def load_artiste(self, artiste):    # pour éviter l'import dans les deux fichiers
        self.state_actuel = ArtisteView(self, artiste)

    def load_playlist(self, nom_playlist, load_via_album=False, load_via_recherche=False):
        self.state_actuel = PlaylistView(self, nom_playlist, load_via_album, load_via_recherche)

    def get_playlist_type(self):
        return PlaylistView

    def load_settings(self):
        self.state_actuel = Settings(self)

    def get_settings_type(self):
        return Settings

internal_state = InternalState()