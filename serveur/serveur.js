import { WebSocketServer } from "ws";
import fs from "node:fs";
import { exit } from "node:process";

var ip="0.0.0.0";
var port=25565;
var connexions = {};

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
        var data_fichier = {
            "ip":"0.0.0.0",
            "port":25565
        }
        var data_str = JSON.stringify(data_fichier);
        fs.writeFileSync("server-ip.json", data_str);
    }

    var fichier_read = fs.readFileSync("server-ip.json", "utf-8");
    var data_fichier = JSON.parse(fichier_read);


} catch{
    console.log("un erreur est survenue lors de la lecture du fichier server-ip.json");
    exit();
}

const wss = new WebSocketServer({
    port:25565,
});


function handle(websocketpeer, message){
    // message de la forme {'type':'valeur', ...}
    if(message.type == "quoi"){
        websocketpeer.send(JSON.stringify({"type":"feur"}));
        return;
    }
};


wss.on("connection", function connection(websocketpeer){ // connection d'un client
    connexions[websocketpeer] = Date.now();
    websocketpeer.on("error", console.error);
    websocketpeer.on("message", function message(data, est_binaire){
        if(!est_binaire) data = data.toString("utf-8");
        // data est censé être sous forme de str de json

        try{
            data = JSON.parse(data);
        } catch{
            console.log("un message a été reçu, mais le parse en json a échoué");
            return;
        }

        // on met à jour le temps
        connexions[websocketpeer] = Date.now();

        // on lance handle
        handle(message);
    });
});

function check_stop(){
    try{
        var fichier_read = fs.readFileSync("stop-server.txt");
        if (fichier_read == "1"){
            console.log("arrêt du serveur");
            exit();
        }
    }catch{
        console.log("échec de la lecture du fichier stop-server.txt");
    }
};

setInterval(check_stop, 60000); // on vérifie si le serveur doit s'arrêter toutes les minutes
console.log("serveur lancé");