import { WebSocketServer } from "ws";
import fs from "node:fs";
import { exit } from "node:process";
import sqlite, { DatabaseSync } from 'node:sqlite';
import { randomInt } from "node:crypto";
import path from 'node:path';


let ip="0.0.0.0";
let port=25565;
let connexions_timeout = new Map;
let connexions_data = new Map;

let timeout_time = 10000; // en ms

let buffer_slice = 2.097e+6 // environ 2mio
// on crée le fichier de stop du serveur
try{
    fs.writeFileSync("stop_server.txt", "0");
}catch{
    console.log("échec de l'initalisation du fichier stop_server.txt");
    exit();
}

// on récupère / crée l'identifiant du serveur
var id_serveur;
try{
    if(!fs.existsSync("server_id.txt")){
        // on crée le fichier
        id_serveur = randomInt(999999999999).toString()
        fs.writeFileSync("server_id.txt", id_serveur);
    }

    let fichier_read = fs.readFileSync("server_id.txt", "utf-8");
    id_serveur = parseInt(fichier_read);

} catch{
    console.log("un erreur est survenue lors de la lecture du fichier server_id.txt");
    exit();
}

// on récupère l'ip et le port dans le fichier "server_ip.json"
try{
    if(!fs.existsSync("server_ip.json")){
        // on crée le fichier
        let data_fichier = {
            "ip":"0.0.0.0",
            "port":25565
        }
        let data_str = JSON.stringify(data_fichier);
        fs.writeFileSync("server_ip.json", data_str);
    }

    let fichier_read = fs.readFileSync("server_ip.json", "utf-8");
    let data_fichier = JSON.parse(fichier_read);

    ip = fichier_read["ip"];
    port = parseInt(fichier_read["port"]);

} catch{
    console.log("un erreur est survenue lors de la lecture du fichier server_ip.json");
    exit();
}

// on récupère les settings présents dans server_settings.txt
try{
    if(!fs.existsSync("server_settings.txt")){
        console.log("fichier server_settings.txt introuvable");
        exit();
    }

    let fichier_read = fs.readFileSync("server_settings.txt", "utf-8");
    var server_settings = JSON.parse(fichier_read);

} catch{
    console.log("un erreur est survenue lors de la lecture du fichier server_settings.txt");
    exit();
}

// on tente d'ouvrir la base de données
try{
    if(!fs.existsSync("chemin_database.txt")){
        // on crée le fichier
        fs.writeFileSync("chemin_database.txt", "server_data.db");
    }

    let fichier_read = fs.readFileSync("chemin_database.txt", "utf-8");
    if(!fs.existsSync(fichier_read)){
        console.log("le fichier " + fichier_read + " n'existe pas");
        exit();
    }
    
    // on essaye d'ouvrir la base de données
    try{
        var database = new DatabaseSync(fichier_read);
    } catch{
        console.log("impossible d'ouvrir la base de données");
        exit();
    }


} catch{
    console.log("un erreur est survenue lors de la lecture du fichier chemin_database.txt");
    exit();
}

const wss = new WebSocketServer({
    port:25565,
    host:ip,
});

function database_select(requete, arguments_requete){
    let requete_prepare = database.prepare(requete);
    return requete_prepare.all(...arguments_requete); // ... tranforme une liste en arguments
}

function database_exec(requete, arguments_requete){
    let requete_prepare = database.prepare(requete);
    return requete_prepare.run(...arguments_requete);
}

function send(message_envoi, websocketpeer){
    websocketpeer.timeout_block = true;
    let est_chaine = false
    if (typeof message_envoi == "string"){
        // c'est une chaine de caractères, on la convertit en bytes
        //websocketpeer.send(message_envoi + "&SPFEND&");
        message_envoi = Buffer.from(message_envoi + "&SPFEND&", "utf-8");
        est_chaine = true;
    }
    // on envoie par morceaux
    let i = 0;
    let sous_message;
    while(i < message_envoi.length){
        sous_message = message_envoi.subarray(i, i + buffer_slice); // slice deprecated

        if(est_chaine) sous_message = Buffer.concat([Buffer.from("&SPFCHAINE&", "utf-8"), sous_message]);
        websocketpeer.send(sous_message);
        if(est_chaine) i = i + sous_message.length - Buffer.from("&SPFCHAINE&").length
        else i = i + sous_message.length;
        
    }
    websocketpeer.timeout_block = false;
    //websocketpeer.send("&SPFEND&");
}

function check_keys(message_json, liste_cles){
    // fonction pas vraiment utilise vu que le handle est dans un try
    let cle;
    for (cle of liste_cles){
        let found = false;
        let cle_json
        for(cle_json in message_json){
            if (cle_json == valeur) found = true;
        }
        if (!found); return 0;
    }
    return 1;
}

function clean_umusiques_positions(id_playlist){
    database_select("UPDATE UMusiques AS base SET position_playlist = ordre.position_playlist FROM (SELECT id AS id_temp, ROW_NUMBER() OVER (ORDER BY position_playlist ASC) AS position_playlist FROM UMusiques WHERE id_playlist = ?) AS ordre WHERE id = id_temp", [parseInt(id_playlist)]);
}

function handle(websocketpeer, message_json, message_bytes){
    // message de la forme {'type':'valeur', ...}
    // TODO ajouter vérification des clés
    if(message_json.type == "se connecter"){
        let resultat;
        if (server_settings["mode bannissement"] == 0)
            resultat = database_select("SELECT password, (SELECT MAX(banni) FROM Utilisateurs WHERE ip=?) AS banni FROM Utilisateurs WHERE username = ?", [websocketpeer.ip_client, message_json.pseudo]);
        else resultat = database_select("SELECT password, banni FROM Utilisateurs WHERE username = ?", [message_json.pseudo]);
        
        if(resultat.length > 0){
            // l'utilisateur existe
            if(resultat[0].password == message_json.mdp && resultat[0].banni != 1){
                // l'utilisateur peut se connecter
                websocketpeer.est_connecte = true;
                websocketpeer.pseudo = message_json.pseudo;
                websocketpeer.mdp = message_json.mdp;
                send(JSON.stringify({"type":"se connecter", "resultat":"oui", "taille envoi fichier":server_settings["taille envoi fichier"].toString(), "id serveur":id_serveur.toString()}), websocketpeer);
            }
            else{
                // mauvais mot de passe
                send(JSON.stringify({"type":"se connecter", "resultat":"non"}), websocketpeer);
            }
        }
        else{
            // l'utilisateur n'existe pas (création de compte)
            send(JSON.stringify({"type":"se connecter", "resultat":"new"}), websocketpeer);
        }
    }



    else if(message_json.type == "nouveau compte"){
        // on vérifie que l'ip n'est pas bannie
        let resultat;
        if (server_settings["mode bannissement"] == 0){
            resultat = database_select("SELECT MAX(banni) FROM Utilisateurs WHERE ip=?", [websocketpeer.ip_client]);
            if (resultat.length > 0){
                if(resultat[0].banni == 1){
                    console.log("tentative de connexion d'une ip, fermeture socket");
                    websocketpeer.terminate();
                }
            }
        }

        // on vérifie que le pseudo n'existe pas
        resultat = database_select("SELECT username FROM Utilisateurs WHERE username=?", [message_json.pseudo]);
        if (resultat.length == 0){
        // TODO : faire un hashage
        resultat = database_exec("INSERT INTO Utilisateurs(username, password, ip, banni) VALUES(?, ?, ?, 0)", [message_json.pseudo, message_json.mdp, websocketpeer.ip_client]);
        
        console.log("nouvel utilisateur : " + message_json.pseudo);
        send(JSON.stringify({"type":"nouveau compte", "resultat":"oui"}), websocketpeer);
        } else send(JSON.stringify({"type":"nouveau compte", "resultat":"non"}), websocketpeer);
        
        
    }



    else if(websocketpeer.est_connecte){ // on vérifie que l'utilisateur est connecté

        if(message_json.type == "rechercher"){
            let resultat;
            let max_results = 20;
            let est_fin = false;
            resultat = database_select("SELECT CAST(id AS TEXT) AS id, nom, image, CAST(id_album AS TEXT) AS id_album, nom_album, CAST(id_artiste AS TEXT) as id_artiste, nom_artiste, type_table FROM (SELECT Musiques.id, Musiques.nom, Albums.image, id_album, Albums.nom AS nom_album, Artistes.id AS id_artiste, Artistes.nom AS nom_artiste, 'musique' AS type_table FROM Musiques JOIN Albums ON Albums.id = Musiques.id_album JOIN Artistes ON Artistes.id = Albums.id_artiste WHERE Musiques.nom LIKE ? OR Albums.nom LIKE ? UNION ALL SELECT DISTINCT Artistes.id, Artistes.nom, Artistes.image, NULL AS id_album, NULL AS nom_album, NULL AS id_artiste, NULL AS nom_artiste, 'artiste' AS type_table FROM Artistes LEFT JOIN Albums ON Albums.id_artiste = Artistes.id WHERE Artistes.nom LIKE ? OR Albums.nom LIKE ?) ORDER BY nom ASC LIMIT ? OFFSET ?", ["%" + message_json.recherche + "%", "%" + message_json.recherche + "%", "%" + message_json.recherche + "%", "%" + message_json.recherche + "%", max_results, parseInt(message_json["nb charges"])]);
            //console.log("taille : " + resultat.length);
            //console.log("stringify : " + JSON.stringify({"type":"rechercher", "resultat":resultat, "est fin":est_fin}))
            if (resultat.length < max_results) est_fin = true;
            send(JSON.stringify({"type":"rechercher", "resultat":resultat, "est fin":est_fin}), websocketpeer);
        }



        else if(message_json.type == "get image"){
            // pas besoin de vérif vu qu'on est dans un try
            let fichier_read = fs.readFileSync(message_json.image);
            send(fichier_read, websocketpeer);
            send(JSON.stringify({"type":"get image", "resultat":"ok"}), websocketpeer);
        }


        else if(message_json.type == "get music infos"){
            let resultat;
            resultat = database_select("SELECT Musiques.nom AS nom_musique, Albums.image AS image_musique, Artistes.nom AS nom_artiste FROM Musiques JOIN Albums ON Albums.id = Musiques.id_album JOIN Artistes ON Artistes.id = Albums.id_artiste WHERE Musiques.id = ?", [parseInt(message_json.id)]);
            
            // on regarde si la longueur de résultat est valide
            if (resultat.length != 1){
                console.log("get music infos : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;

            }
            send(JSON.stringify({"type":"get music infos", "resultat":resultat[0]}), websocketpeer);
        }


        else if(message_json.type == "get music"){
            let resultat;
            let qualite;
            if (!["min", "moy", "max"].includes(message_json["qualite"])){
                console.log("qualité invalide, fermeture socket");
                websocketpeer.terminate();
                return;
            }
            resultat = database_select("SELECT min, moy, max FROM Musiques WHERE id=?", [parseInt(message_json["id"])]);

            // on regarde si la longueur de résultat est valide
            if (resultat.length != 1){
                console.log("get music : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;

            }
            
            // on check la qualite a récupérer
            qualite = message_json["qualite"];
            while(qualite != "non"){
                if (resultat[0][qualite]) break;
                switch (qualite){
                    case "min":
                        qualite = "non";
                        break;
                    case "moy":
                        qualite = "min";
                        break;
                    case "max":
                        qualite = "moy";
                        break;
                }
            }
            if (qualite == "non"){
                // pas de qualités dispo
                send(JSON.stringify({"type":"get music", "resultat":"non", "qualite":"non"}), websocketpeer);
            }
            else{
                let extension = path.extname(resultat[0][qualite]);
                
                // on lit le fichier (pas besoin de vérifier, on est dans un try)
                let fichier_data = fs.readFileSync(resultat[0][qualite]);
                send(fichier_data, websocketpeer);
                send(JSON.stringify({"type":"get music", "resultat":extension, "qualite":qualite}), websocketpeer);
            }
        }



        else if(message_json.type == "get musics of album"){
            let resultat;
            resultat = database_select("SELECT DISTINCT CAST(Musiques.id AS TEXT) AS id, Musiques.nom AS nom, Albums.image AS image, CAST(Albums.id AS TEXT) AS id_album, Albums.nom AS nom_album, CAST(Artistes.id AS TEXT) AS id_artiste, Artistes.nom AS nom_artiste, CAST(Albums.annee AS TEXT) AS annee_album, Albums.genre AS genre_album FROM Albums JOIN Artistes ON Artistes.id = Albums.id_artiste LEFT JOIN Musiques ON Musiques.id_album = Albums.id WHERE Albums.id = ? ORDER BY Musiques.position_album ASC", [parseInt(message_json.id_album)])
            //resultat = database_select("SELECT CAST(Musiques.id AS TEXT) AS id, Musiques.nom AS nom, Albums.image AS image, CAST(Albums.id AS TEXT) AS id_album, Albums.nom AS nom_album, CAST(Artistes.id AS TEXT) AS id_artiste, Artistes.nom AS nom_artiste, Albums.annee AS annee_album, Albums.genre AS genre_album FROM Musiques JOIN Albums ON Albums.id = Musiques.id_album JOIN Artistes ON Artistes.id = Albums.id_artiste WHERE Albums.id = ? ORDER BY Musiques.position_album ASC", [parseInt(message_json.id_album)]);
            
            // on regarde si la longueur de résultat est valide
            if (resultat.length < 1){
                console.log("get musics of album : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;

            }
            
            send(JSON.stringify({"type":"get musics of album", "resultat":resultat}), websocketpeer);
        }



        else if(message_json.type == "get artiste infos"){
            let resultat;
            resultat = database_select("SELECT Artistes.nom AS nom_artiste, Artistes.image AS image_artiste, Albums.nom AS nom_album, CAST(Albums.id AS TEXT) AS id_album, CAST(Albums.annee AS TEXT) AS annee, Albums.image AS image_album, Albums.genre AS genre_album FROM Artistes LEFT JOIN Albums ON Albums.id_artiste = Artistes.id WHERE Artistes.id = ?", [parseInt(message_json.id_artiste)]);
            // si pas de résultat, l'artiste n'existe pas (LEFT JOIN)
            if (resultat.length < 1){
                console.log("get artiste infos : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;
            }

            send(JSON.stringify({"type":"get artiste infos", "resultat":resultat}), websocketpeer);
        }


        else if (message_json.type == "creer playlist"){
            let resultat;
            resultat = database_exec("INSERT INTO UPlaylists(id_utilisateur, nom, description) VALUES((SELECT id FROM Utilisateurs WHERE username = ?), 'Playlist', '')", [websocketpeer.pseudo]);
            send(JSON.stringify({"type":"creer playlist", "resultat":resultat.lastInsertRowid.toString()}), websocketpeer);
        }



        else if (message_json.type == "supprimer playlist"){
            let resultat;
            // note : on check le pseudo pour être sûr que l'utilisateur est autorisé à supprimer la playlist
            resultat = database_exec("DELETE FROM UMusiques WHERE id IN (SELECT UMusiques.id FROM UMusiques JOIN UPlaylists ON UPlaylists.id = UMusiques.id_playlist JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur WHERE UPlaylists.id = ? AND username = ?)", [parseInt(message_json.id_playlist), websocketpeer.pseudo]);
            resultat = database_exec("DELETE FROM UPlaylists WHERE id = ? AND id_utilisateur = (SELECT id FROM Utilisateurs WHERE username = ?)", [parseInt(message_json.id_playlist), websocketpeer.pseudo]);
            send(JSON.stringify({"type":"supprimer playlist", "resultat":"ok"}), websocketpeer);
        }



        else if (message_json.type == "get musics of playlist"){
            let resultat;
            resultat = database_select("SELECT CAST(Musiques.id AS TEXT) AS id, Musiques.nom as nom, Albums.image AS image, CAST(Albums.id AS TEXT) AS id_album, Albums.nom AS nom_album, CAST(Artistes.id AS TEXT) AS id_artiste, Artistes.nom AS nom_artiste, CAST(UPlaylists.id AS TEXT) AS id_playlist, Uplaylists.nom AS nom_playlist, Uplaylists.image AS image_playlist, Uplaylists.description AS description_playlist FROM UPlaylists JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur LEFT JOIN UMusiques ON UMusiques.id_playlist = UPlaylists.id LEFT JOIN Musiques ON Musiques.id = UMusiques.id_musique LEFT JOIN Albums ON Albums.id = Musiques.id_album LEFT JOIN Artistes ON Artistes.id = Albums.id_artiste WHERE Uplaylists.id = ? AND Utilisateurs.username = ? ORDER BY UMusiques.position_playlist ASC", [parseInt(message_json.id_playlist), websocketpeer.pseudo]);
            // on ne check pas s'il y a un résultat, car on ne sait pas si la playlist n'existe pas ou si c'est pas le bon pseudo ou s'il n'y a pas de musiques
           if (resultat.length < 1){
                console.log("get musics of playlist : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;
            }
            send(JSON.stringify({"type":"supprimer playlist", "resultat":resultat}), websocketpeer);
        }



        else if (message_json.type == "ajouter musique playlist"){
            let resultat;
            // on vérifie d'abord que l'utilisateur est bien celui qui a la playlist
            resultat = database_select("SELECT UPlaylists.id FROM UPlaylists JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur WHERE UPlaylists.id = ? AND Utilisateurs.username = ?", [parseInt(message_json.id_playlist), websocketpeer.pseudo]);
            if (resultat.length < 1){
                console.log("ajouter musique playlist : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;
            }
            resultat = database_exec("INSERT INTO UMusiques(id_playlist, id_musique, position_playlist) VALUES(?, ?, (SELECT COALESCE(MAX(position_playlist), 0) + 1 FROM UMusiques WHERE id_playlist = ?))", [parseInt(message_json.id_playlist), parseInt(message_json.id_musique), parseInt(message_json.id_playlist)]);
            
            // on renvoie les infos de la musique créée (pour l'ajouter directement)
            resultat = database_select("SELECT CAST(Musiques.id AS TEXT) AS id, Musiques.nom AS nom, Albums.image AS image, CAST(Albums.id AS TEXT) AS id_album, Albums.nom AS nom_album, CAST(Artistes.id AS TEXT) AS id_artiste, Artistes.nom AS nom_artiste FROM Musiques JOIN Albums ON Albums.id = Musiques.id_album JOIN Artistes ON Artistes.id = Albums.id_artiste WHERE Musiques.id = ?", [parseInt(message_json.id_musique)])
            
            // on regarde si la longueur de résultat est valide (normalement inutile grâce à la contraite de clé étrangère des requêtes d'avant (crash si problème) mais en met quand même au cas où)
            if (resultat.length != 1){
                console.log("ajouter musique playlist 2 : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;

            }
            send(JSON.stringify({"type":"ajouter musique playlist", "resultat":resultat}), websocketpeer);
        }



        else if(message_json.type == "get playlists"){
            let resultat;
            resultat = database_select("SELECT CAST(UPlaylists.id AS TEXT) AS id, nom, image FROM Uplaylists JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur WHERE Utilisateurs.username = ?", [websocketpeer.pseudo]);
            send(JSON.stringify({"type":"get playlists", "resultat":resultat}), websocketpeer);
        }



        else if(message_json.type == "remove from playlist"){
            let resultat;
            resultat = database_exec("DELETE FROM UMusiques WHERE id IN (SELECT UMusiques.id FROM UMusiques JOIN UPlaylists ON UPlaylists.id = UMusiques.id_playlist JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur WHERE UPlaylists.id = ? AND UMusiques.position_playlist = ? AND username = ?)", [parseInt(message_json.id_playlist), parseInt(message_json.position_playlist), websocketpeer.pseudo]);
            clean_umusiques_positions(message_json.id_playlist);
            send(JSON.stringify({"type":"remove from playlist", "resultat":"ok"}), websocketpeer);
        }



        else if(message_json.type == "changer position musique"){
            try{
                let resultat;
                // on vérifie d'abord que l'utilisateur est bien celui qui a la playlist
                resultat = database_select("SELECT UPlaylists.id FROM UPlaylists JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur WHERE UPlaylists.id = ? AND Utilisateurs.username = ?", [parseInt(message_json.id_playlist), websocketpeer.pseudo]);
                if (resultat.length < 1){
                    console.log("changer position musique : longueur résultat invalide, fermeture socket");
                    websocketpeer.terminate();
                    return;
                }

                let debut = parseInt(message_json.position_debut);
                let fin = parseInt(message_json.position_fin);

                // on récupère d'abord l'id de la musique a déplacer
                let id_musique = database_select("SELECT id FROM UMusiques WHERE id_playlist = ? AND position_playlist = ?", [parseInt(message_json.id_playlist), debut])[0]["id"];
                if (debut != fin){
                    if (debut > fin){
                        // on monte
                        // on fait +1 pour [fin, debut - 1]
                        resultat = database_exec("UPDATE UMusiques SET position_playlist = position_playlist + 1 WHERE id_playlist = ? AND position_playlist >= ? AND position_playlist <= ?", [parseInt(message_json.id_playlist), fin, debut - 1]);
                    }
                    else if(debut < fin){
                        // on descend
                        // on fait -1 pour [debut + 1, fin]
                        resultat = database_exec("UPDATE UMusiques SET position_playlist = position_playlist - 1 WHERE id_playlist = ? AND position_playlist >= ? AND position_playlist <= ?", [parseInt(message_json.id_playlist), debut + 1, fin]);
                    }
                    // on met la musique déplacée à la bonne position
                    resultat = database_exec("UPDATE UMusiques SET position_playlist = ? WHERE id_playlist = ? AND position_playlist = ? AND id = ?", [fin, parseInt(message_json.id_playlist), debut, id_musique]);
                }
            }
            catch{
                console.log("échec du déplacement, fermeture socket");
                clean_umusiques_positions(message_json.id_playlist);
                websocketpeer.terminate();
                return;
            }
            clean_umusiques_positions(message_json.id_playlist); // on le met au cas où
            send(JSON.stringify({"type":"changer position musique", "resultat":"ok"}), websocketpeer);
        }



        else if(message_json.type == "set playlist infos"){
            let resultat;
            // on vérifie d'abord que l'utilisateur est bien celui qui a la playlist
            resultat = database_select("SELECT UPlaylists.id FROM UPlaylists JOIN Utilisateurs ON Utilisateurs.id = UPlaylists.id_utilisateur WHERE UPlaylists.id = ? AND Utilisateurs.username = ?", [parseInt(message_json.id_playlist), websocketpeer.pseudo]);
            if (resultat.length < 1){
                console.log("set playlist infos : longueur résultat invalide, fermeture socket");
                websocketpeer.terminate();
                return;
            }

            resultat = database_select("SELECT image FROM UPlaylists WHERE id=?", [parseInt(message_json.id_playlist)]);
            let chemin_image = resultat[0]["image"];
            // on regarde si une image a été envoyée
            if(message_json.image_extension != null){
                // on crée le dossier de stockage s'il n'est pas là
                fs.mkdirSync("UPlaylists covers", {recursive:true});
                // on supprime l'ancienne image
                
                if (chemin_image != null) fs.unlinkSync(chemin_image);

                // on stocke l'image sur le disque
                // note : il n'y a pas le point à l'extension
                chemin_image = "Uplaylists covers/" + message_json.id_playlist + "." + message_json.image_extension
                fs.writeFileSync(chemin_image, message_bytes);
                
            }
            // on change le nom, la description et l'image
            resultat = database_exec("UPDATE UPlaylists SET nom=?, description=?, image=? WHERE id=?", [message_json.nom_playlist, message_json.description, chemin_image, parseInt(message_json.id_playlist)])
            send(JSON.stringify({"type":"set playlist infos", "resultat":"ok"}), websocketpeer);
        }

        
        else{
        console.log("type invalide, fermeture socket");
        websocketpeer.terminate();
        }
    }
    else{
        console.log("type invalide, fermeture socket");
        websocketpeer.terminate();
    }
};

function verif_no_number(message_json, test_json=true, test_tableau=true){
    let element;
    for (element in message_json){
        if (typeof(message_json[element]) == "number"){
            console.log("float repéré pour requête de type " + message_json["type"]);
        }
        else if (test_json){
            // on teste si c'est un json (très lent)
            try{
                JSON.stringify(message_json[element]);
                verif_no_number(message_json[element]);
            }
            catch{}
        }
        else if (test_tableau){
            // on teste si c'est un tableau
            try{
                message_json[element][0];
                let i;
                for(i=0; i<message_json[element].length;i++) verif_no_number(message_json[element][i]);
            }
            catch{}
        }
    }
}

wss.on("connection", function connection(websocketpeer, req){ // connection d'un client
    connexions_timeout.set(websocketpeer, Date.now());
    connexions_data.set(websocketpeer, new Map);
    let message_bytes;
    let message_text = "";

    // on initialise les différents attributs du socket
    websocketpeer.est_connecte = false;
    websocketpeer.pseudo = "";
    websocketpeer.mdp = "";
    websocketpeer.timeout_block = false

    // on met l'ip du websocket
    // TODO checker XforwardedFor
    // TODO normaliser ip (ipv4, ipv6 compressé, ipv6 non compressé)
    websocketpeer.ip_client = req.socket.remoteAddress;

    websocketpeer.on("error", console.error);
    websocketpeer.on("message", function message(data, est_binaire){
        //console.log("reçu");
        // on met à jour le temps
        connexions_timeout.set(websocketpeer, Date.now());


        if(est_binaire){
            websocketpeer.send("ok");
            // on ajoute du binaire dans la bonne liste dans connexions_data
            if(data.includes("&SPFCHAINE&")){
                // c'est une partie de chaine, on la met dans text
                data = data.subarray(Buffer.from("&SPFCHAINE&", "utf-8").length);
                if(!connexions_data.get(websocketpeer).has("text")){
                connexions_data.get(websocketpeer).set("text", data);
                }
                else connexions_data.get(websocketpeer).set("text", Buffer.concat([connexions_data.get(websocketpeer).get("text"), data]));
            }
            else if(!connexions_data.get(websocketpeer).has("bytes")){
                connexions_data.get(websocketpeer).set("bytes", data);
            }
            else{
                connexions_data.get(websocketpeer).set("bytes", Buffer.concat([connexions_data.get(websocketpeer).get("bytes"), data]));
            }
        }
        else{
            data = data.toString("utf-8");
             // on check si c'est un ping
            if(data == "quoi"){
                websocketpeer.send("feur");
                return;
            }
        }
        if (!(connexions_data.get(websocketpeer).get("text") != null && connexions_data.get(websocketpeer).get("text").includes(Buffer.from("&SPFEND&")))) return; // le message n'est pas encore complet
        connexions_data.get(websocketpeer).set("text", connexions_data.get(websocketpeer).get("text").toString("utf-8"));
        // le message est complet, on enlève  &SPFEND&
        message_text = connexions_data.get(websocketpeer).get("text").split("&SPFEND&")[0];
        message_bytes = connexions_data.get(websocketpeer).get("bytes");

        // on supprime le contenu de connexions_data
        connexions_data.set(websocketpeer, new Map);

        // message_text est censé être sous forme de str de json
        try{
            message_text = JSON.parse(message_text);
        } catch{
            console.log("un message a été reçu, mais le parse en json a échoué");
            return;
        }
        //console.log("message reçu : " + message_text.type);

        // on lance handle
        // TODO : ajouter try avec catch fermeture socket avec terminate, et aussi avec affichage de l'erreur
        //verif_no_number(message_text); // TODO à enlever à la fin
        handle(websocketpeer, message_text, message_bytes);

        // on remet à jour le temps (potentiel envoi de gros fichiers)
        connexions_timeout.set(websocketpeer, Date.now());
    });
});

function check_stop(){
    try{
        let fichier_read = fs.readFileSync("stop_server.txt");
        if (fichier_read == "1"){
            database.close();
            console.log("arrêt du serveur");
            exit();
        }
    }catch{
        console.log("échec de la lecture du fichier stop_server.txt");
    }
};

function check_timeout(){
    let client;
    //console.log("taille : " + wss.clients.size)
    for(client of connexions_timeout.keys()){
        //console.log("%d > %d", Date.now() - connexions_timeout.get(client), timeout_time);
        if (Date.now() - connexions_timeout.get(client) > timeout_time && !client.timeout_block){
            // on enlève la connexion de connexions_timeout et connexions_data et on la coupe
            console.log("suppression timeout");
            console.log("avant timeout : ", client.readyState);
            connexions_timeout.delete(client);
            connexions_data.delete(client);
            if (client.readyState == WebSocket.CONNECTING || client.readyState == WebSocket.OPEN) client.terminate();
        }
    }
}

setInterval(check_timeout, 10000); // on vérifie si des connexions sont rompues toutes les minutes
setInterval(check_stop, 60000); // on vérifie si le serveur doit s'arrêter toutes les minutes
console.log("serveur lancé");