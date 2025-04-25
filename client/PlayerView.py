from Screen import resize_screen
import pygame
pygame.init()

class PlayerView:
    def __init__(self):
        self.rect_dimensions = pygame.rect.Rect(0, 950, 1920, 1080-950)
    
    def reset(self):
        pass
    
    def blit(self):
        resize_screen.draw_rect("grey20", self.rect_dimensions)
    
    def listen_entry(self, event):
        pass

player = PlayerView()