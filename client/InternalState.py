from PlaylistView import PlaylistView
from Rechercher import Rechercher
class InternalState:
    def __init__(self):
        self.state_actuel = Rechercher(self)

    def reset(self):
        self.state_actuel = Rechercher(self)

internal_state = InternalState()