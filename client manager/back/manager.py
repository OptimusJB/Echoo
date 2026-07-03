import json
import sqlite3
import os

def choix_multiple(question:str, reponses:list):
    question = question + " ("
    for index_element in range(len(reponses)):
        question = question + str(reponses[index_element])
        if not index_element == len(reponses) - 1:
            question = question + "/"
    question = question + ") : "

    reponse = input(question)
    while not reponse in reponses:
        reponse = input(question)
    return reponse

def choix_type(question:str, type_reponse):
    question = question + " : "
    reponse = None
    while not type(reponse) == type_reponse:
        try:
            reponse = type_reponse(input(question))
        except ValueError:
            pass
    return reponse

def main():
    print("Echoo Server Manager cli")
    # on récupère la base de données
    if not "server_data.db" in os.listdir():
        print("Base de données introuvable. Vérifiez que le fichier 'server_data.db' (généré par le manager graphique) se trouve dans le même dossier")
        return
    
    database = sqlite3.connect("server_data.db")
    database.execute("PRAGMA foreign_keys = ON")
    cursor = database.cursor()

    # on récupère les options
    try:
        fichier_options = open("server_settings.txt", "r")
    except:
        print("Échec de l'ouverture des options serveur. Vérifiez que le fichier 'server_settings.txt' (généré par le manager graphique) se trouve dans le même dossier")
        return
    
    server_options = json.load(fichier_options)
    fichier_options.close()

    if server_options["chemins relatifs"] == 0:
        print("""le mode chemins relatifs est désactivé, voulez-vous l'activer ?
note : Après activation, la version graphique pourra ne pas pouvoir supprimer les images de playlists utilisateur.""")
        reponse = choix_multiple("réponse", ["o", "n"])
        if reponse == "o":
            server_options["chemins relatifs"] = 1
            try:
                fichier_options = open("server_settings.txt", "w")
            except:
                print("Échec de la modification des options serveur")
                return
            
            json.dump(server_options, fichier_options)
            fichier_options.close()
            print("Options modifiées.")
    
    while True:
        print("""
1 : ajouter artiste
2 : ajouter album
3 : ajouter musiques
4 : supprimer artiste
5 : supprimer album
6 : supprimer musiques
7 : désactiver le mode chemins relatifs
8 : quitter""")
        reponse = choix_multiple("reponse", ['1', '2', '3', '4', '5', '6', '7', '8'])
        reponse = int(reponse)
        print("\n\n\n\n\n\n\n")
        if reponse == 1:
            nom = input("Nom artiste : ")
            chemin_image = input("Chemin de l'image : ")
            if not chemin_image:
                chemin_image = None # au cas où
            cursor.execute("INSERT INTO Artistes(nom, image) VALUES(?, ?)", [nom, chemin_image])
            database.commit()
            print("Artiste ajouté. Son id est " + str(cursor.lastrowid))
        
        elif reponse == 2:
            id_artiste = choix_type("Id de l'artiste lié", int)
            nom = input("Nom album : ")
            annee = choix_type("Année", int)
            genre = input("Genre : ")
            chemin_image = input("Chemin de l'image : ")
            if not chemin_image:
                chemin_image = None # au cas où
            cursor.execute("INSERT INTO Albums(id_artiste, nom, annee, genre, image) VALUES(?, ?, ?, ?, ?)", [id_artiste, nom, annee, genre, chemin_image])
            database.commit()
            print("Album ajouté. Son id est " + str(cursor.lastrowid))
        
        elif reponse == 3:
            id_album = choix_type("Id de l'album lié", int)
            chemin_musiques = input("Chemin vers le dossier contenant les musiques : ")
            try:
                liste_musiques = os.listdir(chemin_musiques)
            except:
                print("chemin invalide")
                continue
            debut_remove = choix_type("Nombre de caractères à enlever au début", int)
            qualite = choix_multiple("Qualité des musiques", ["min", "moy", "max"])

            # on récupère max_position_album
            cursor.execute("SELECT MAX(position_album) AS max_pos FROM Musiques WHERE id_album=?", [id_album])
            resultat = cursor.fetchall()
                
            max_position_album = resultat[0][0]

            if not max_position_album:
                max_position_album = 0

            do_commit = False
            for musique in sorted(liste_musiques):
                musique = os.path.join(chemin_musiques, musique)
                print("musique : ", musique)
                nom_musique = os.path.splitext(os.path.basename(musique))[0][debut_remove:]

                # on regarde si la musique existe déjà
                cursor.execute("SELECT * FROM Musiques WHERE nom=? AND id_album=?", [nom_musique, id_album])
                if len(cursor.fetchall()) > 0:
                    # la musique existe déjà, on remplace
                    cursor.execute("UPDATE Musiques SET " + str(qualite) + "=? WHERE id_album=? AND nom=?", [musique, id_album, nom_musique])
                    # pas besoin de faire commit à chaque fois, normalement comme on est sur la même connexion le select du haut peut le voir
                    do_commit = True
                else:
                    cursor.execute("INSERT INTO Musiques(nom, id_album, position_album, " + str(qualite) + ") VALUES(?, ?, ?, ?)", [nom_musique, id_album, max_position_album + 1, musique])
                    max_position_album += 1
                    do_commit = True

            if do_commit:
                database.commit()
            print("Musiques ajoutées.")
        
        elif reponse == 4:
            id_artiste = choix_type("Id de l'artiste", int)
            # on supprime tous les trucs avant
            cursor.execute("DELETE FROM UMusiques WHERE id_musique IN (SELECT id FROM Musiques WHERE id_album IN (SELECT id FROM Albums WHERE id_artiste = ?))", [id_artiste])
            cursor.execute("DELETE FROM Musiques WHERE id_album IN (SELECT id FROM Albums WHERE id_artiste = ?)", [id_artiste])
            cursor.execute("DELETE FROM Albums WHERE id_artiste = ?", [id_artiste])
            cursor.execute("DELETE FROM Artistes WHERE id=?",  [id_artiste])
            database.commit()
            print("Artiste supprimé")

        elif reponse == 5:
            id_album = choix_type("Id de l'album", int)
            # on supprime tous les trucs avant
            cursor.execute("DELETE FROM UMusiques WHERE id_musique IN (SELECT id FROM Musiques WHERE id_album = ?)", [id_album])
            cursor.execute("DELETE FROM Musiques WHERE id_album = ?", [id_album])
            cursor.execute("DELETE FROM Albums WHERE id=?",  [id_album])
            database.commit()
            print("Album supprimé")
        
        elif reponse == 6:
            # on supprime la musique
            id_musique = choix_type("Id de la musique", int)
            cursor.execute("DELETE FROM UMusiques WHERE id_musique=?", [id_musique])
            cursor.execute("DELETE FROM Musiques WHERE id=?", [id_musique])
            database.commit()
            print("Musique supprimée")

        elif reponse == 7:
            # on récupère les options
            try:
                fichier_options = open("server_settings.txt", "r")
            except:
                print("Échec de l'ouverture des options serveur. Vérifiez que le fichier 'server_settings.txt' (généré par le manager graphique) se trouve dans le même dossier")
                return
            
            server_options = json.load(fichier_options)
            fichier_options.close()

            if server_options["chemins relatifs"] == 0:
                print("le mode chemins relatifs est déjà désactivé")
                continue
            server_options["chemins relatifs"] = 0
            try:
                fichier_options = open("server_settings.txt", "w")
            except:
                print("Échec de la modification des options serveur")
                return
            
            json.dump(server_options, fichier_options)
            fichier_options.close()
            print("Options modifiées.")
        
        elif reponse == 8:
            cursor.close()
            database.close()
            return

if __name__ == "__main__":
    main()