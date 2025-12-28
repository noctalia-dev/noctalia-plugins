import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  onPluginApiChanged: {
    if (pluginApi) {
      console.log("Main: pluginApi załadowane, uruchamiam generator");
      runGenerator();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      console.log("Main: Component.onCompleted, uruchamiam generator");
      runGenerator();
    }
  }

  function runGenerator() {
    console.log("Main: === START GENERATORA ===");
    
    // Pobierz HOME z environment
    var homeDir = process.environment["HOME"];
    if (!homeDir) {
      console.log("Main: BŁĄD - nie można pobrać $HOME");
      saveToDb([{
        "title": pluginApi?.tr("main.error") || "ERROR",
        "binds": [{ "keys": "ERROR", "desc": pluginApi?.tr("main.cannot_get_home") || "Cannot get $HOME" }]
      }]);
      return;
    }
    
    var filePath = homeDir + "/.config/hypr/keybind.conf";
    var cmd = "cat " + filePath;
    
    console.log("Main: HOME = " + homeDir);
    console.log("Main: Pełna ścieżka = " + filePath);
    console.log("Main: Komenda = " + cmd);
    
    var proc = process.create("bash", ["-c", cmd]);
    
    proc.finished.connect(function() {
      console.log("Main: Proces zakończony. ExitCode: " + proc.exitCode);
      console.log("Main: Stdout długość: " + proc.stdout.length);
      console.log("Main: Stderr: " + proc.stderr);
      
      if (proc.exitCode !== 0) {
          console.log("Main: BŁĄD! Kod: " + proc.exitCode);
          console.log("Main: Stderr pełny: " + proc.stderr);
          
          saveToDb([{
              "title": pluginApi?.tr("main.read_error") || "READ ERROR",
              "binds": [
                { "keys": pluginApi?.tr("main.exit_code") || "EXIT CODE", "desc": proc.exitCode.toString() },
                { "keys": pluginApi?.tr("main.stderr") || "STDERR", "desc": proc.stderr }
              ]
          }]);
          return;
      }

      var content = proc.stdout;
      console.log("Main: Pobrano treść. Długość: " + content.length);
      
      // Pokaż pierwsze 200 znaków
      if (content.length > 0) {
          console.log("Main: Pierwsze 200 znaków: " + content.substring(0, 200));
          parseAndSave(content);
      } else {
          console.log("Main: Plik jest pusty!");
          saveToDb([{
              "title": pluginApi?.tr("main.file_empty") || "FILE EMPTY",
              "binds": [{ "keys": "INFO", "desc": pluginApi?.tr("main.file_no_data") || "File contains no data" }]
          }]);
      }
    });
  }

  Process {
    id: process
    function create(cmd, args) {
      console.log("Main: Tworzę proces: " + cmd + " " + args.join(" "));
      command = [cmd].concat(args);
      running = true;
      return this;
    }
  }

  function parseAndSave(text) {
    console.log("Main: Parsowanie rozpoczęte");
    var lines = text.split('\n');
    console.log("Main: Liczba linii: " + lines.length);
    
    var categories = [];
    var currentCategory = null;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      if (line.startsWith("#") && line.match(/#\s*\d+\./)) {
        if (currentCategory) {
          console.log("Main: Zapisuję kategorię: " + currentCategory.title + " z " + currentCategory.binds.length + " bindami");
          categories.push(currentCategory);
        }
        var title = line.replace(/#\s*\d+\.\s*/, "").trim();
        console.log("Main: Nowa kategoria: " + title);
        currentCategory = { "title": title, "binds": [] };
      } 
      else if (line.includes("bind") && line.includes('#"')) {
        if (currentCategory) {
            var descMatch = line.match(/#"(.*?)"$/);
            var description = descMatch ? descMatch[1] : "Opis";
            
            var parts = line.split(',');
            if (parts.length >= 2) {
                var mod = parts[0].split('=')[1].trim().replace("$mod", "SUPER");
                var key = parts[1].trim().toUpperCase();
                if (parts[0].includes("SHIFT")) mod += "+SHIFT";
                if (parts[0].includes("CTRL")) mod += "+CTRL";
                
                currentCategory.binds.push({
                    "keys": mod + " + " + key,
                    "desc": description
                });
                console.log("Main: Dodano bind: " + mod + " + " + key);
            }
        }
      }
    }
    
    if (currentCategory) {
      console.log("Main: Zapisuję ostatnią kategorię: " + currentCategory.title);
      categories.push(currentCategory);
    }

    console.log("Main: Znaleziono " + categories.length + " kategorii.");
    saveToDb(categories);
  }

  function saveToDb(data) {
      if (pluginApi) {
          pluginApi.pluginSettings.cheatsheetData = data;
          pluginApi.saveSettings();
          console.log("Main: ZAPISANO DO BAZY " + data.length + " kategorii");
      } else {
          console.log("Main: BŁĄD - pluginApi jest null!");
      }
  }

  IpcHandler {
    target: "plugin:cheatsheet"
    function toggle() {
      console.log("Main: IPC toggle wywołany");
      if (pluginApi) {
        runGenerator(); 
        pluginApi.withCurrentScreen(screen => pluginApi.openPanel(screen));
      }
    }
  }
}
