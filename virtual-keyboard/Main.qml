import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.Keyboard
import qs.Services.UI
import qs.Services.Noctalia

Loader {
    id: root

    property var pluginApi: null

    readonly property string typeKeyScript: Settings.configDir + "plugins/virtual-keyboard/type-key.py"

    IpcHandler {
        target: "plugin:virtual-keyboard"
        function toggle() {
            if (pluginApi) {
                pluginApi.pluginSettings.enabled = !pluginApi.pluginSettings.enabled;
                if (pluginApi.pluginSettings.enabled == false) {
                    reset()
                }
                pluginApi.saveSettings();
            }
        }
        function reset() {
            if (pluginApi) {
                resetScript.running = true
                capsON = false
                activeModifiers = {"LEFTSHIFT": false, "RIGHTSHIFT": false, "LEFTCTRL": false, "RIGHTCTRL": false, "LEFTALT": false, "RIGHTALT": false, "LEFTMETA": false, "RIGHTMETA": false, "FN": false}
            }
        }
    }

    Process {
        id: resetScript
        command: ["python", typeKeyScript, "reset"]
        stderr: StdioCollector {
            onStreamFinished: {
                Logger.d("Keyboard", "modifier toggles reset")
            }
        }
    }


    active: pluginApi ? root.pluginApi.pluginSettings.enabled || pluginApi.manifest.metadata.defaultSettings.enabled || false : false
    
    Component.onCompleted: {
        if (!!Settings.data.floatingPanel) {
            Settings.data.floatingPanel.giveFocus = false
        }
    }

    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: {
            if (!!Settings.data.floatingPanel) {
                Settings.data.floatingPanel.enabled = pluginApi ? root.pluginApi.pluginSettings.enabled || pluginApi.manifest.metadata.defaultSettings.enabled || false : false
            }
        }
    }

    FolderListModel {
        id: jsonFiles
        folder: "file://" + Settings.configDir + "plugins/virtual-keyboard/layouts/"
        nameFilters: ["*.json"]
    }

    property var layouts: []

    property var currentLayout

    property string currentSize: pluginApi ? root.pluginApi.pluginSettings.size || pluginApi.manifest.metadata.defaultSettings.size || "compact" : "compact"

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            if (pluginApi) {
                for (let i = 0; i < layouts.length; i ++) {
                    for (let layout in layouts[i]) {
                        if (pluginApi.pluginSettings.layout) {
                            if (pluginApi.pluginSettings.layout == layout) {
                                currentLayout = layouts[i][layout]
                            }
                        }
                        else if (pluginApi.manifest.metadata.defaultSettings.layout == layout) {
                            currentLayout = layouts[i][layout]
                        }
                    }
                }
            }
        }
    }

    Repeater {
        model: jsonFiles

        Item {
            width: 0
            height: 0
            
            FileView {
                path: model.filePath

                onLoaded: {
                    try {
                        let data = JSON.parse(text())
                        let name = model.fileName.slice(0, -5)
                        layouts.push({ [name]: data.layout })
                    } catch(e) {
                        Logger.e("Keyboard", "JSON Error in", model.fileName, ":", e)
                    }
                }
            }
        }
    }

    property var activeModifiers: {"LEFTSHIFT": false, "RIGHTSHIFT": false, "LEFTCTRL": false, "RIGHTCTRL": false, "LEFTALT": false, "RIGHTALT": false, "LEFTMETA": false, "RIGHTMETA": false, "FN": false}

    property bool capsON: LockKeysService.capsLockOn
    property bool numON: LockKeysService.numLockOn

    property var keyArray: []

    sourceComponent: Variants {
        id: allKeyboards
        model: Quickshell.screens
        delegate: Item {
            required property ShellScreen modelData
            Loader {
                id: mainLoader
                objectName: "loader"
                asynchronous: false
                active: pluginApi ? root.pluginApi.pluginSettings.enabled || pluginApi.manifest.metadata.defaultSettings.enabled || false : false
                property ShellScreen loaderScreen: modelData
                sourceComponent: PanelWindow {
                    id: virtualKeyboard
                    screen: mainLoader.loaderScreen
                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }
                    margins {
                        left: (screen.width -  background.width)/2 - screen.x
                        right: (screen.width - background.width)/2 + screen.x
                        top: (screen.height - background.height)/2.15 - screen.y
                        bottom: (screen.height - background.height)/2.15 + screen.y
                    }
                    color: Color.transparent
                    property alias backgroundBox: background
                    
                    NBox {
                        id: background

                        function getWidth() {
                            if (root.currentSize === "compact") {
                                return 1200
                            }
                            else if (root.currentSize === "full") {
                                return 1600
                            }
                            else {
                                return 1200
                            }
                        }

                        width: getWidth()
                        height: 500
                        x: 0
                        y: 0
                        color: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, 0.75)

                        // adapt margins
                        onXChanged: {
                            for (let instance of allKeyboards.instances) {
                                for (let child of instance.children) {
                                    if (child.objectName === "loader" && child.item && child.item.margins) {
                                        let m = child.item.margins
                                        m.left += x
                                        m.right -= x
                                    }
                                }
                            }
                            x = 0
                        }
                        onYChanged: {
                            for (let instance of allKeyboards.instances) {
                                for (let child of instance.children) {
                                    if (child.objectName === "loader" && child.item && child.item.margins) {
                                        let m = child.item.margins
                                        m.top += y
                                        m.bottom -= y
                                    }
                                }
                            }
                            y = 0
                        }

                        function getBackgrounds(_screen) {
                                for (let i = 0; i < allKeyboards.instances.length; i++) {
                                    let instance = allKeyboards.instances[i];
                                    for (let child of instance.children) {
                                        if (child.objectName == "loader") {
                                            let loader = child
                                            if (loader.loaderScreen === _screen){
                                                return loader.item.backgroundBox
                                            }
                                        }
                                    }
                                }
                                return null;
                            }

                        MouseArea {
                            anchors.fill: dragButton.pressed ? parent : closeButton
                            drag.target: background
                            drag.axis: Drag.XAndYAxis

                            onPositionChanged: {
                                // sync every instance
                                for (var i=0; i<allKeyboards.model.length; i++ ){
                                    let _screen = allKeyboards.model[i]
                                    if (_screen != screen) {
                                        let bg = background.getBackgrounds(_screen)
                                        let globalX = background.x + screen.x
                                        let globalY = background.y + screen.y
                                        bg.x = background.x
                                        bg.y = background.y
                                        for (let child of bg.children) {
                                            if (child.objectName == "dragButton") {
                                                child.pressed = true
                                            }
                                        }
                                    }
                                }
                            }
                            
                            onReleased: {
                                for (var i=0; i<allKeyboards.model.length; i++ ){
                                    let _screen = allKeyboards.model[i]
                                    let bg = background.getBackgrounds(_screen)
                                    for (let child of bg.children) {
                                        if (child.objectName == "dragButton") {
                                            child.pressed = false
                                        }
                                    }
                                }
                            }
                        }

                        NBox {
                            id: closeButton
                            width: 50
                            height: 50
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 10
                            anchors.rightMargin: 10
                            property bool pressed: false
                            color: pressed ? Color.mOnSurface : Color.mSurfaceVariant
                            radius: 20
                            NText {
                                anchors.centerIn: parent
                                text: ""
                                font.weight: Style.fontWeightBold
                                font.pointSize: Style.fontSizeL * fontScale
                                color: closeButton.pressed ? Color.mSurfaceVariant : Color.mOnSurface
                            }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: function(mouse) {
                                    closeButton.pressed = true
                                    root.pluginApi.pluginSettings.enabled = false
                                    resetScript.running = true
                                    root.capsON = false
                                    root.activeModifiers = {"LEFTSHIFT": false, "RIGHTSHIFT": false, "LEFTCTRL": false, "RIGHTCTRL": false, "LEFTALT": false, "RIGHTALT": false, "LEFTMETA": false, "RIGHTMETA": false, "FN": false}
                                    pluginApi.saveSettings();
                                }
                                onReleased: {
                                    closeButton.pressed = false
                                }
                            }
                        }

                        NBox {
                            id: dragButton
                            objectName: "dragButton"
                            width: 50
                            height: 50
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 10
                            anchors.leftMargin: 10
                            
                            property bool pressed: false
                            property real localX: 0
                            property real localY: 0
                            property real startX: 0
                            property real startY: 0
                            
                            color: pressed ? Color.mOnSurface : Color.mSurfaceVariant
                            radius: 20

                            NText {
                                anchors.centerIn: parent
                                text: ""
                                font.weight: Style.fontWeightBold
                                font.pointSize: Style.fontSizeL * fontScale
                                color: dragButton.pressed ? Color.mSurfaceVariant : Color.mOnSurface
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onPressed: {
                                    dragButton.pressed = true
                                }

                                drag.target: background
                                drag.axis: Drag.XAndYAxis

                                onPositionChanged: {
                                    // sync every instance
                                    for (var i=0; i<allKeyboards.model.length; i++ ){
                                        let _screen = allKeyboards.model[i]
                                        if (_screen != screen) {
                                            let bg = background.getBackgrounds(_screen)
                                            let globalX = background.x + screen.x
                                            let globalY = background.y + screen.y
                                            bg.x = background.x
                                            bg.y = background.y
                                            for (let child of bg.children) {
                                                if (child.objectName == "dragButton") {
                                                    child.pressed = true
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                onReleased: {
                                    for (var i=0; i<allKeyboards.model.length; i++ ){
                                        let _screen = allKeyboards.model[i]
                                        let bg = background.getBackgrounds(_screen)
                                        for (let child of bg.children) {
                                            if (child.objectName == "dragButton") {
                                                child.pressed = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        ColumnLayout {
                            id: mainColumn
                            anchors.fill: parent
                            anchors.margins: Style.marginL
                            anchors.topMargin: 75
                            spacing: Style.marginM
                            function getLayout() {
                                if (root.currentLayout) {
                                    let list = []
                                    for (let i = 0; i < root.currentLayout.length; i++) {
                                        list[i] = []
                                        for (let y = 0; y < root.currentLayout[i].length; y++) {
                                            if (root.currentLayout[i][y].size.toString().split(",").includes(root.currentSize)) {
                                                list[i].push(root.currentLayout[i][y])
                                            }
                                        }   
                                    }
                                    let finalList = []
                                    for (let i = 0; i < list.length; i++) {
                                        if (list[i].length != 0) {
                                            finalList.push(list[i])
                                        }
                                    }
                                    return finalList
                                }
                                else {
                                    return []
                                }
                            }
                            Repeater {
                                model: mainColumn.getLayout()

                                RowLayout {
                                    spacing: Style.marginL

                                    Repeater {
                                        model: modelData

                                        NBox {
                                            id: key
                                            enabled: modelData.key === "separator" ? false : true 
                                            visible: modelData.size.toString().split(",").includes(root.currentSize)
                                            function getRows() {
                                                let count = 0
                                                let keyAmount = 0
                                                for (let i = 0; i < root.currentLayout.length; i++) {
                                                    for (let y = 0; y < root.currentLayout[i].length; y++) {
                                                        if (root.currentLayout[i][y].size.toString().split(",").includes(root.currentSize)) {
                                                            count++
                                                        }
                                                    }
                                                    if (count > keyAmount) {
                                                        keyAmount = count
                                                    }
                                                    count = 0
                                                }
                                                return keyAmount
                                            }
                                            width: Math.max(10, background.width / (getRows() + 5) + modelData.width)
                                            height: Math.max(10, background.height / (mainColumn.getLayout().length + 3))
                                            color: enabled ? (runScript.running || (modelData.key ===  "CAPSLOCK" && root.capsON) || (modelData.key ===  "NUMLOCK" && root.numON) || (modelData.key in root.activeModifiers && root.activeModifiers[modelData.key])) ? Color.mOnSurface : Color.mSurfaceVariant : Color.transparent 
                                            border.color: enabled ? Color.mOutline : Color.transparent
                                            // refresh colors and text every 0.2 seconds
                                            Timer {
                                                interval: 200; running: true; repeat: true
                                                onTriggered: {
                                                    if (modelData.key ===  "CAPSLOCK" || modelData.key ===  "NUMLOCK" || modelData.key in root.activeModifiers) {
                                                        key.color = enabled ? (runScript.running || (modelData.key ===  "CAPSLOCK" && root.capsON) || (modelData.key ===  "NUMLOCK" && root.numON) || (modelData.key in root.activeModifiers && root.activeModifiers[modelData.key])) ? Color.mOnSurface : Color.mSurfaceVariant : Color.transparent 
                                                    }
                                                    keyTextShift.color = (root.activeModifiers.LEFTSHIFT || root.activeModifiers.RIGHTSHIFT) ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                                    keyTextAlt.color = root.activeModifiers.RIGHTALT ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                                    keyTextNum.color = (!root.numON && modelData.key != "DELETE") ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                                    keyTextFn_unlocked.color = root.activeModifiers.FN ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                                    keyTextOther.color = root.activeModifiers.FN ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                                }
                                            }

                                            function get_key_visibility(_key) {
                                                for (let i = 0; i < root.currentLayout.length; i++) {
                                                    for (let y = 0; y < root.currentLayout[i].length; y++) {
                                                        if (root.currentLayout[i][y].key === _key){
                                                            if (root.currentLayout[i][y].size.toString().split(",").includes(root.currentSize)) {
                                                                return true
                                                            }
                                                            return false
                                                        }
                                                    }
                                                }
                                                return false
                                            }

                                            NText {
                                                id: keyTextMain
                                                anchors.centerIn: parent
                                                text: modelData.txt
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeL * fontScale
                                                color: key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            }

                                            NText {
                                                id: keyTextShift
                                                visible: get_key_visibility("LEFTSHIFT") || get_key_visibility("RIGHTSHIFT")
                                                anchors.left: key.left
                                                anchors.bottom: key.bottom
                                                anchors.leftMargin: 10
                                                anchors.bottomMargin: 10
                                                text: modelData.shift
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeXS * fontScale
                                                color: (root.activeModifiers.LEFTSHIFT || root.activeModifiers.RIGHTSHIFT) ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            }

                                            NText {
                                                id: keyTextAlt
                                                visible: get_key_visibility("RIGHTALT")
                                                anchors.right: key.right
                                                anchors.bottom: key.bottom
                                                anchors.rightMargin: 10
                                                anchors.bottomMargin: 10
                                                text: modelData.alt
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeXS * fontScale
                                                color: root.activeModifiers.RIGHTALT ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            }

                                            NText {
                                                id: keyTextFn_locked
                                                visible: get_key_visibility("FN")
                                                anchors.left: key.left
                                                anchors.top: key.top
                                                anchors.bottom: key.bottom
                                                anchors.leftMargin: 10
                                                text: modelData.fn_locked
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeXS * fontScale
                                                color: key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            }

                                            NText {
                                                id: keyTextFn_unlocked
                                                visible: get_key_visibility("FN")
                                                anchors.right: key.right
                                                anchors.verticalCenter: key.verticalCenter
                                                anchors.rightMargin: 10
                                                text: modelData.fn_unlocked
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeXS * fontScale
                                                color: root.activeModifiers.FN ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            }

                                            NText {
                                                id: keyTextNum
                                                visible: get_key_visibility("NUMLOCK")
                                                anchors.horizontalCenter: key.horizontalCenter
                                                anchors.bottom: key.bottom
                                                anchors.bottomMargin: 5
                                                text: modelData.num
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeXXS * fontScale
                                                color: !root.numON ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            } 
                                            NText {
                                                id: keyTextOther
                                                visible: get_key_visibility("FN")
                                                anchors.horizontalCenter: key.horizontalCenter
                                                anchors.bottom: key.bottom
                                                anchors.bottomMargin: 5
                                                text: modelData.other
                                                font.weight: Style.fontWeightBold
                                                font.pointSize:Style.fontSizeXXS * fontScale
                                                color: root.activeModifiers.FN ? Color.mHover : key.color === Color.mOnSurface ? Color.mSurfaceVariant : Color.mOnSurface
                                            } 

                                            Process {
                                                id: runScript
                                                command: ["python", root.typeKeyScript] // placeholder

                                                function startWithKeys(keys) {
                                                    runScript.command = ["python", root.typeKeyScript].concat(keys);
                                                    runScript.running = true;
                                                }
                                                stdout: StdioCollector {
                                                    onStreamFinished: {
                                                        if (!!Settings.data.floatingPanel) {
                                                            Settings.data.floatingPanel.giveFocus = false
                                                        }
                                                    }
                                                }
                                                stderr: StdioCollector {
                                                    onStreamFinished: {
                                                        if (text) Logger.w(text.trim());
                                                    }
                                                }
                                            }


                                            MouseArea {
                                                anchors.fill: parent
                                                onPressed: {
                                                    if (modelData.key in root.activeModifiers) {
                                                        root.activeModifiers[modelData.key] = !root.activeModifiers[modelData.key]
                                                    }
                                                    else{
                                                        if (!!Settings.data.floatingPanel) {
                                                            Settings.data.floatingPanel.giveFocus = true
                                                        }
                                                        if (modelData.key === "CAPSLOCK") {
                                                            root.capsON = !root.capsON
                                                        }
                                                        if (modelData.key === "NUMLOCK") {
                                                            root.numON = !root.numON
                                                        }
                                                        root.keyArray = [modelData.key.toString()]
                                                        for (var k in root.activeModifiers) {
                                                            var v = root.activeModifiers[k];
                                                            if (v) {
                                                                root.keyArray.push(k);
                                                            }
                                                        }
                                                        if (pluginApi.pluginSettings.layout) {
                                                            root.keyArray.unshift(pluginApi.pluginSettings.layout)
                                                        }
                                                        else {
                                                            root.keyArray.unshift(pluginApi.manifest.metadata.defaultSettings.layout)
                                                        }
                                                        runScript.startWithKeys(root.keyArray)
                                                    }
                                                    Logger.d(modelData.key.toString())
                                                }
                                                onReleased: {
                                                    if (!(modelData.key in root.activeModifiers)) {
                                                        root.keyArray = []
                                                        for (var k in root.activeModifiers) {
                                                            root.activeModifiers[k] = false;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}