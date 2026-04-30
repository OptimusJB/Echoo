import os

dossiers = ["."]
fichiers = []

element_recherche = input("élément à rechercher : ")

# parcours de tous les fichiers
print("découverte des fichiers")
while len(dossiers) > 0:
    for element in os.listdir(dossiers[0]):
        if os.path.isdir(dossiers[0] + "/" + element):
            dossiers.append(dossiers[0] + "/" + element)
        elif os.path.isfile(dossiers[0] + "/" + element) and element[len(element)-3:] == ".gd":
            fichiers.append(dossiers[0] + "/" + element)
    dossiers.pop(0)

# on regarde dans chaque fichier le nombre d'occurences
print("lecture des fichiers")
total_occurences = 0
for element in fichiers:
    fichier = open(element, "r", encoding="utf-8")
    fichier_read = fichier.read()
    fichier.close()

    nombre_occurences = fichier_read.count(element_recherche)
    if nombre_occurences > 0:
        print(f"trouvé {nombre_occurences} occurences dans {element}")
        total_occurences += nombre_occurences

print(f"nombre total d'occurences : {total_occurences}")