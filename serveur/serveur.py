import socketserver

class request_manager(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.settimeout(20)

        # récupération des données envoyées par le client
        nb_bytes = ""
        data = None
        while not data == "a":  # a est le séparateur
            data = str(self.request.recv(1), "utf-8")
            if data == "":
                break
            elif not data == "a":
                nb_bytes = nb_bytes + data


serveur = socketserver.TCPServer(("0.0.0.0", 25565), request_manager)
serveur.request_queue_size = 50
print("serveur lancé")
serveur.serve_forever()