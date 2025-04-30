class User:
    def __init__(self):
        self.username = None
        self.password = None
        self.load_images = True
        self.quality = "max"    # = 'max' ou 'moyen' ou 'min'

user = User()