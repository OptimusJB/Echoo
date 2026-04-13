import { WebSocketServer } from "ws";
import fs from "node:fs";
import { exit } from "node:process";

let ip="0.0.0.0";
let port=25565;
let connexions_timeout = new Map;
let connexions_data = new Map;

let timeout_time = 10000; // en ms

// on crée le fichier de stop du serveur
try{
    fs.writeFileSync("stop-server.txt", "0");
}catch{
    console.log("échec de l'initalisation du fichier stop-server.txt");
    exit();
}

// on récupère l'ip et le port dans le fichier "server-ip.json"
try{
    if(!fs.existsSync("server-ip.json")){
        // on crée le fichier
        let data_fichier = {
            "ip":"0.0.0.0",
            "port":25565
        }
        let data_str = JSON.stringify(data_fichier);
        fs.writeFileSync("server-ip.json", data_str);
    }

    let fichier_read = fs.readFileSync("server-ip.json", "utf-8");
    let data_fichier = JSON.parse(fichier_read);


} catch{
    console.log("un erreur est survenue lors de la lecture du fichier server-ip.json");
    exit();
}

const wss = new WebSocketServer({
    port:25565,
});


function handle(websocketpeer, message_text, message_bytes){
    // message de la forme {'type':'valeur', ...}
};


wss.on("connection", function connection(websocketpeer){ // connection d'un client
    connexions_timeout.set(websocketpeer, Date.now());
    connexions_data.set(websocketpeer, new Map);
    let message_bytes;
    let message_text = "";

    websocketpeer.on("error", console.error);
    websocketpeer.on("message", function message(data, est_binaire){
        // on met à jour le temps
        connexions_timeout.set(websocketpeer, Date.now());


        if(est_binaire){
            // on ajoute du binaire dans connexions_data
            if(!connexions_data.get(websocketpeer).has("bytes")){
                connexions_data.get(websocketpeer).set("bytes", data);
            }
            else connexions_data.get(websocketpeer).set(websocketpeer, connexions_data.get(websocketpeer) + data);
        }
        else{
            data = data.toString("utf-8");
             // on check si c'est un ping
            if(data == "quoi"){
                //console.log("ping reçu")
                websocketpeer.send("feur");
                return;
            }

            // on ajoute du texte dans connexions_data
            if(!connexions_data.get(websocketpeer).has("text")){
                connexions_data.get(websocketpeer).set("text", data);
            }
            else connexions_data.get(websocketpeer).set("text", connexions_data.get(websocketpeer) + data);
        }
        if (!connexions_data.get(websocketpeer).get("text").includes("&SPFEND&")) return; // le message n'est pas encore complet
        
        // le message est complet, on enlève &SPFBEGIN& et &SPFEND&
        message_text = connexions_data.get(websocketpeer).get("text").split("&SPFBEGIN&")[1].split("&SPFEND&")[0];
        message_bytes = connexions_data.get(websocketpeer).get("bytes");

        // on supprime le contenu de connexions_data
        connexions_data.delete(websocketpeer);

        // message_text est censé être sous forme de str de json
        try{
            message_text = JSON.parse(message_text);
        } catch{
            console.log("un message a été reçu, mais le parse en json a échoué");
            return;
        }
        //console.log("message reçu : " + message_text.type);

        // on lance handle
        handle(websocketpeer, message_text, message_bytes);
    });
});

function check_stop(){
    try{
        let fichier_read = fs.readFileSync("stop-server.txt");
        if (fichier_read == "1"){
            console.log("arrêt du serveur");
            exit();
        }
    }catch{
        console.log("échec de la lecture du fichier stop-server.txt");
    }
};

function check_timeout(){
    let client;
    for(client of connexions_timeout.keys()){
        //console.log("%d > %d", Date.now() - connexions_timeout.get(client), timeout_time);
        if (Date.now() - connexions_timeout.get(client) > timeout_time){
            // on enlève la connexion de connexions_timeout et connexions_data et on la coupe
            console.log("suppression timeout")
            connexions_timeout.delete(client);
            connexions_data.delete(client);
            if (client.readyState == WebSocket.CONNECTING || client.readyState == WebSocket.OPEN) client.terminate();
        }
    }
}

setInterval(check_timeout, 10000); // on vérifie si des connexions sont rompues toutes les minutes
setInterval(check_stop, 60000); // on vérifie si le serveur doit s'arrêter toutes les minutes
console.log("serveur lancé");