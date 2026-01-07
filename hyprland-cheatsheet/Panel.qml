import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property var rawCategories: pluginApi?.pluginSettings?.cheatsheetData || []
  property var categories: processCategories(rawCategories)
  property var column0Items: []
  property var column1Items: []
  property var column2Items: []

  onRawCategoriesChanged: {
    categories = processCategories(rawCategories);
    updateColumnItems();
  }

  onCategoriesChanged: {
    updateColumnItems();
  }

  function updateColumnItems() {
    var assignments = distributeCategories();
    column0Items = buildColumnItems(assignments[0]);
    column1Items = buildColumnItems(assignments[1]);
    column2Items = buildColumnItems(assignments[2]);
  }
  property real contentPreferredWidth: 1400
  property real contentPreferredHeight: 850
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: false 
  readonly property bool panelAnchorHorizontalCenter: true
  readonly property bool panelAnchorVerticalCenter: true
  anchors.fill: parent
  property var allLines: []
  property bool isLoading: false
  
  onPluginApiChanged: { if (pluginApi) checkAndGenerate(); }
  Component.onCompleted: { if (pluginApi) checkAndGenerate(); }

  function checkAndGenerate() {
      if (root.rawCategories.length === 0) {
          isLoading = true;
          allLines = [];
          catProcess.running = true;
      }
  }

  Process {
      id: catProcess
      command: ["sh", "-c", "cat ~/.config/hypr/keybind.conf"]
      running: false
      
      stdout: SplitParser {
          onRead: data => {
              root.allLines.push(data);
          }
      }
      
      onExited: (exitCode, exitStatus) => {
          isLoading = false;
          if (exitCode === 0 && root.allLines.length > 0) {
              var fullContent = root.allLines.join("\n");
              parseAndSave(fullContent);
              root.allLines = [];
          } else {
              errorText.text = pluginApi?.tr("panel.error_read_file") || "File read error";
              errorView.visible = true;
          }
      }
  }

  function parseAndSave(text) {
      var lines = text.split('\n');
      var cats = [];
      var currentCat = null;

      for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line.startsWith("#") && line.match(/#\s*\d+\./)) {
              if (currentCat) cats.push(currentCat);
              var title = line.replace(/#\s*\d+\.\s*/, "").trim();
              currentCat = { "title": title, "binds": [] };
          } 
          else if (line.includes("bind") && line.includes('#"')) {
              if (currentCat) {
                  var descMatch = line.match(/#"(.*?)"$/);
                  var desc = descMatch ? descMatch[1] : (pluginApi?.tr("panel.no_description") || "No description");
                  var parts = line.split(',');
                  if (parts.length >= 2) {
                      var bindPart = parts[0].trim();
                      var keyPart = parts[1].trim();
                      var mod = "";
                      if (bindPart.includes("$mod")) mod = "Super";
                      if (bindPart.includes("SHIFT")) mod += (mod ? " + Shift" : "Shift");
                      if (bindPart.includes("CTRL")) mod += (mod ? " + Ctrl" : "Ctrl");
                      if (bindPart.includes("ALT")) mod += (mod ? " + Alt" : "Alt");
                      var key = keyPart.toUpperCase();
                      var fullKey = mod + (mod && key ? " + " : "") + key;
                      currentCat.binds.push({ "keys": fullKey, "desc": desc });
                  }
              }
          }
      }
      if (currentCat) cats.push(currentCat);
      if (cats.length > 0) {
          pluginApi.pluginSettings.cheatsheetData = cats;
          pluginApi.saveSettings();
      } else {
          errorText.text = pluginApi?.tr("panel.no_categories") || "No categories found";
          errorView.visible = true;
      }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.mSurface 
    radius: Style.radiusL
    clip: true

    Rectangle {
      id: header
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 45
      color: Color.mSurfaceVariant
      radius: Style.radiusL
      
      RowLayout {
        anchors.centerIn: parent
        spacing: Style.marginS
        NIcon {
          icon: "keyboard"
          pointSize: Style.fontSizeM
          color: Color.mPrimary
        }
        NText {
          text: pluginApi?.tr("panel.title") || "Cheat Sheet"
          font.pointSize: Style.fontSizeM
          font.weight: Font.Bold
          color: Color.mPrimary
        }
      }
    }

    NText {
        id: loadingText
        anchors.centerIn: parent
        text: pluginApi?.tr("panel.loading") || "Loading..."
        visible: root.isLoading
        font.pointSize: Style.fontSizeL
        color: Color.mOnSurface
    }

    ColumnLayout {
        id: errorView
        anchors.centerIn: parent
        visible: false
        spacing: Style.marginM
        NIcon {
            icon: "alert-circle"
            pointSize: 48
            Layout.alignment: Qt.AlignHCenter
            color: Color.mError
        }
        NText {
            id: errorText
            text: pluginApi?.tr("panel.no_data") || "No data"
            font.pointSize: Style.fontSizeM
            color: Color.mOnSurface
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        NButton {
            text: pluginApi?.tr("panel.refresh_button") || "Refresh"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                pluginApi.pluginSettings.cheatsheetData = [];
                pluginApi.saveSettings();
                checkAndGenerate();
            }
        }
    }

    RowLayout {
      id: mainLayout
      visible: root.categories.length > 0 && !root.isLoading
      anchors.top: header.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: Style.marginM
      spacing: Style.marginS
      
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        spacing: 2
        Repeater {
          model: root.column0Items
          Loader {
            Layout.fillWidth: true
            sourceComponent: modelData.type === "header" ? headerComponent :
                           (modelData.type === "spacer" ? spacerComponent : bindComponent)
            property var itemData: modelData
          }
        }
      }
      
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        spacing: 2
        Repeater {
          model: root.column1Items
          Loader {
            Layout.fillWidth: true
            sourceComponent: modelData.type === "header" ? headerComponent :
                           (modelData.type === "spacer" ? spacerComponent : bindComponent)
            property var itemData: modelData
          }
        }
      }
      
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        spacing: 2
        Repeater {
          model: root.column2Items
          Loader {
            Layout.fillWidth: true
            sourceComponent: modelData.type === "header" ? headerComponent :
                           (modelData.type === "spacer" ? spacerComponent : bindComponent)
            property var itemData: modelData
          }
        }
      }
    }
  }
  
  Component {
    id: headerComponent
    RowLayout {
      spacing: Style.marginXS
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: 4
      NIcon {
        icon: "circle-dot"
        pointSize: 10
        color: Color.mPrimary
      }
      NText {
        text: itemData.title
        font.pointSize: 11
        font.weight: Font.Bold
        color: Color.mPrimary
      }
    }
  }
  
  Component {
    id: spacerComponent
    Item {
      height: 10
      Layout.fillWidth: true
    }
  }
  
  Component {
    id: bindComponent
    RowLayout {
      spacing: Style.marginS
      height: 22
      Layout.bottomMargin: 1
      Flow {
        Layout.preferredWidth: 220
        Layout.alignment: Qt.AlignVCenter
        spacing: 3
        Repeater {
          model: itemData.keys.split(" + ")
          Rectangle {
            width: keyText.implicitWidth + 10
            height: 18
            color: getKeyColor(modelData)
            radius: 3
            NText {
              id: keyText
              anchors.centerIn: parent
              text: modelData
              font.pointSize: modelData.length > 12 ? 7 : 8
              font.weight: Font.Bold
              color: Color.mOnPrimary
            }
          }
        }
      }
      NText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: itemData.desc
        font.pointSize: 9
        color: Color.mOnSurface
        elide: Text.ElideRight
      }
    }
  }
  
  function getKeyColor(keyName) {
    // Different colors for different key types
    if (keyName === "Super") return Color.mPrimary;
    if (keyName === "Ctrl") return Color.mSecondary;
    if (keyName === "Shift") return Color.mTertiary;
    if (keyName === "Alt") return "#FF6B6B"; // Reddish
    if (keyName.startsWith("XF86")) return "#4ECDC4"; // Turquoise for multimedia
    if (keyName === "PRINT") return "#95E1D3"; // Light turquoise for print screen
    if (keyName.match(/^[0-9]$/)) return "#A8DADC"; // Light blue for numbers
    if (keyName.includes("MOUSE")) return "#F38181"; // Pink for mouse
    // Default color for other keys (letters, arrows, etc.)
    return Color.mPrimaryContainer || "#6C757D";
  }

  function buildColumnItems(categoryIndices) {
    var result = [];
    if (!categoryIndices) return result;

    for (var i = 0; i < categoryIndices.length; i++) {
      var catIndex = categoryIndices[i];
      if (catIndex >= categories.length) continue;

      var cat = categories[catIndex];
      // Add header
      result.push({ type: "header", title: cat.title });
      // Add all keybinds
      for (var j = 0; j < cat.binds.length; j++) {
        result.push({
          type: "bind",
          keys: cat.binds[j].keys,
          desc: cat.binds[j].desc
        });
      }
      // Add spacer after category (except for last in column)
      if (i < categoryIndices.length - 1) {
        result.push({ type: "spacer" });
      }
    }
    return result;
  }

  function processCategories(cats) {
    if (!cats || cats.length === 0) return [];

    var result = [];
    for (var i = 0; i < cats.length; i++) {
      var cat = cats[i];

      // Split large categories (>12 items)
      if (cat.binds && cat.binds.length > 12 && cat.title.includes("OBSZARY ROBOCZE")) {
        var switching = [];
        var moving = [];
        var mouse = [];

        for (var j = 0; j < cat.binds.length; j++) {
          var bind = cat.binds[j];
          if (bind.keys.includes("MOUSE")) {
            mouse.push(bind);
          } else if (bind.desc.includes("Send") || bind.desc.includes("send") ||
                     bind.desc.includes("Move") || bind.desc.includes("move") ||
                     bind.desc.includes("Wyślij") || bind.desc.includes("wyślij")) {
            moving.push(bind);
          } else {
            switching.push(bind);
          }
        }

        if (switching.length > 0) {
          result.push({
            title: pluginApi?.tr("panel.workspace_switching") || "WORKSPACES - SWITCHING",
            binds: switching
          });
        }
        if (moving.length > 0) {
          result.push({
            title: pluginApi?.tr("panel.workspace_moving") || "WORKSPACES - MOVING",
            binds: moving
          });
        }
        if (mouse.length > 0) {
          result.push({
            title: pluginApi?.tr("panel.workspace_mouse") || "WORKSPACES - MOUSE",
            binds: mouse
          });
        }
      } else {
        result.push(cat);
      }
    }

    return result;
  }

  function distributeCategories() {
    // Calculate weight of each category (header + binds + spacer)
    var weights = [];
    var totalWeight = 0;
    for (var i = 0; i < categories.length; i++) {
      var weight = 1 + categories[i].binds.length + 1; // header + binds + spacer
      weights.push(weight);
      totalWeight += weight;
    }

    var targetPerColumn = totalWeight / 3;
    var columns = [[], [], []];
    var columnWeights = [0, 0, 0];

    // Greedy algorithm: assign each category to column with smallest weight
    for (var i = 0; i < categories.length; i++) {
      var minCol = 0;
      for (var c = 1; c < 3; c++) {
        if (columnWeights[c] < columnWeights[minCol]) {
          minCol = c;
        }
      }
      columns[minCol].push(i);
      columnWeights[minCol] += weights[i];
    }

    return columns;
  }
}
