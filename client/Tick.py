class Tick:
    """
    Classe qui contient différentes méthodes permettant de passer des frames
    toutes les méthodes sont faites pour se mettre dans un if à chaque frame
    ex : if do_during(5, "1") = le contenu du if s'exécutera sur 5 frames, puis ne s'exécutera plus (sauf avec reset)
    """
    def __init__(self):
        self.counts = {}

    def reset_counts(self, id=None):
        """
        reset tous les counts, ou un seul si id est spécifié
        """
        if id == None:
            self.counts = {}
        else:
            self.counts.pop(id)

    def do_during(self, ticks, id):
        """
        créé pour se mettre dans un if
        return True les ticks premières fois que la fonction est exécutée, return False sinon
        """
        if not id in self.counts.keys():
            self.counts[id] = 1
        else:
            self.counts[id] = self.counts[id] + 1

        if self.counts[id] > ticks:
            return False
        return True

    def wait_during(self, ticks, id):
        """
        créé pour se mettre dans un if
        return False les ticks premières fois que la fonction est exécutée, return True sinon
        """
        if not id in self.counts.keys():
            self.counts[id] = 1
        else:
            self.counts[id] = self.counts[id] + 1   # attention, c'est de plus en plus grand

        if self.counts[id] > ticks:
            return True
        return False

    def do_until(self, number, id):
        """
        créé pour se mettre dans un if
        return True tant que finish n'a pas été exécuté number fois, return False sinon
        """
        if not id in self.counts.keys():
            self.counts[id] = 0

        if self.counts[id] >= number:
            return False
        return True

    def wait_until(self, number, id):
        """
        créé pour se mettre dans un if
        return False tant que finish n'a pas été exécuté number fois, return True sinon
        """
        if not id in self.counts.keys():
            self.counts[id] = 0

        if self.counts[id] >= number:
            return True
        return False

    def finish(self, id):
        assert id in self.counts.keys(), "cet id n'est pas présent dans le dictionnaire des id"
        self.counts[id] = self.counts[id] + 1

    def do_every(self, ticks:int, id):
        """
        créé pour se mettre dans un if
        retourne True 1 fois toutes les ticks frames
        retourne False sinon
        """
        if not id in self.counts.keys():
            self.counts[id] = 1
        else:
            self.counts[id] = self.counts[id] + 1

        if self.counts[id] >= ticks:
            self.counts[id] = 0
            return True
        return False

    def do_once(self, ticks:int, id):
        """
        retourne True quand le nombre de ticks passé est égal à ticks
        """
        if not id in self.counts.keys():
            self.counts[id] = 1
        else:
            self.counts[id] = self.counts[id] + 1

        if self.counts[id] == ticks:
            return True
        return False