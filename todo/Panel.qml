import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 700 * Style.uiScaleRatio
  property real contentPreferredHeight: 500 * Style.uiScaleRatio
  readonly property bool allowAttach: true
  anchors.fill: parent
  property ListModel todosModel: ListModel {}
  property ListModel filteredTodosModel: ListModel {}
  property bool showCompleted: false
  property var rawTodos: []

  Binding {
    target: root
    property: "rawTodos"
    value: pluginApi?.pluginSettings?.todos || []
  }

  function moveTodoToCorrectPosition(todoId) {
    if (!pluginApi) return;

    var todos = pluginApi.pluginSettings.todos || [];
    var currentPageId = pluginApi?.pluginSettings?.current_page_id || 0;

    // Find the todo to move
    var todoToMove = null;
    var todoGlobalIndex = -1;

    for (var i = 0; i < todos.length; i++) {
      if (todos[i].id === todoId) {
        todoToMove = todos[i];
        todoGlobalIndex = i;
        break;
      }
    }

    if (todoToMove && todoGlobalIndex !== -1) {
      // Remove the todo from its current position
      todos.splice(todoGlobalIndex, 1);

      // Only reorder within the same page
      if (todoToMove.pageId === currentPageId) {
        // Find the correct position within the same page
        if (todoToMove.completed) {
          // Place completed items at the end of the page
          var insertIndex = todos.length;
          for (var j = todos.length - 1; j >= 0; j--) {
            if (todos[j].pageId === currentPageId && todos[j].completed) {
              insertIndex = j + 1;
              break;
            }
          }
          todos.splice(insertIndex, 0, todoToMove);
        } else {
          // Place uncompleted items at the beginning of the page
          var insertIndex = 0;
          for (; insertIndex < todos.length; insertIndex++) {
            if (todos[insertIndex].pageId === currentPageId) {
              if (todos[insertIndex].completed) {
                break;
              }
            }
          }
          todos.splice(insertIndex, 0, todoToMove);
        }
      } else {
        // If the todo is not on the current page, just add it back to its original position
        todos.splice(todoGlobalIndex, 0, todoToMove);
      }

      pluginApi.pluginSettings.todos = todos;
      pluginApi.saveSettings();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      Logger.i("Todo", "Panel initialized");
      root.showCompleted = pluginApi?.pluginSettings?.showCompleted !== undefined
                           ? pluginApi.pluginSettings.showCompleted
                           : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
      loadTodos();
    }
  }

  function loadTodos() {
    // Store the current scroll position
    var currentScrollPos = todoListView ? todoListView.contentY : 0;

    todosModel.clear();
    filteredTodosModel.clear();

    var pluginTodos = root.rawTodos;
    var currentPageId = pluginApi?.pluginSettings?.current_page_id || 0;

    // Filter todos for the current page
    var pageTodos = pluginTodos.filter(function(todo) {
      return todo.pageId === currentPageId;
    });

    // Populate both models in a single loop
    for (var i = 0; i < pageTodos.length; i++) {
      var todoItem = {
        id: pageTodos[i].id,
        text: pageTodos[i].text,
        completed: pageTodos[i].completed === true,
        createdAt: pageTodos[i].createdAt,
        pageId: pageTodos[i].pageId
      };

      // Add to full model
      todosModel.append(todoItem);

      // Add to filtered model if it meets criteria
      if (showCompleted || !pageTodos[i].completed) {
        filteredTodosModel.append(todoItem);
      }
    }

    // Restore the scroll position
    if (todoListView) {
      Qt.callLater(function() {
        todoListView.contentY = currentScrollPos;
      });
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      loadTodos();
    }
  }

  // Watch for changes in the todos array length or showCompleted setting
  property int previousTodosCount: -1

  Timer {
    id: settingsWatcher
    interval: 200
    running: !!pluginApi
    repeat: true
    onTriggered: {
    var newShowCompleted = pluginApi?.pluginSettings?.showCompleted !== undefined
                           ? pluginApi.pluginSettings.showCompleted
                           : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
      var currentTodos = pluginApi?.pluginSettings?.todos || [];
      var currentTodosCount = currentTodos.length;

      if (root.showCompleted !== newShowCompleted || root.previousTodosCount !== currentTodosCount) {
        root.showCompleted = newShowCompleted;
        root.previousTodosCount = currentTodosCount;
        loadTodos();
      }
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginM
      }
      spacing: Style.marginL

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusL

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          RowLayout {
            spacing: Style.marginM

            NIcon {
              icon: "checklist"
              pointSize: Style.fontSizeXL
            }

            NText {
              text: pluginApi?.tr("panel.header.title")
              font.pointSize: Style.fontSizeL
              font.weight: Font.Medium
              color: Color.mOnSurface
            }

            Item {
              Layout.fillWidth: true
            }

            NButton {
              enabled: (pluginApi.pluginSettings.completedCount > 0)
              text: pluginApi?.tr("panel.header.clear_completed_button")
              icon: "trash"
              fontSize: Style.fontSizeS
              onClicked: {
                if (pluginApi) {
                  var todos = pluginApi.pluginSettings.todos || [];
                  var currentPageId = pluginApi.pluginSettings.current_page_id || 0;

                  // Only clear completed todos for the current page
                  var activeTodos = todos.filter(function(todo) {
                    return !(todo.completed && todo.pageId === currentPageId);
                  });

                  pluginApi.pluginSettings.todos = activeTodos;

                  // Update counts
                  var newCompletedCount = 0;
                  for (var j = 0; j < activeTodos.length; j++) {
                    if (activeTodos[j].completed) {
                      newCompletedCount++;
                    }
                  }
                  pluginApi.pluginSettings.completedCount = newCompletedCount;
                  pluginApi.pluginSettings.count = activeTodos.length;

                  pluginApi.saveSettings();
                  loadTodos();
                }
              }
            }
          }

          // Page selector using tab components
          NTabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.topMargin: Style.marginS
            distributeEvenly: true
            currentIndex: currentPageIndex

            // Track current page index
            property int currentPageIndex: {
              var pages = pluginApi?.pluginSettings?.pages || [];
              var currentId = pluginApi?.pluginSettings?.current_page_id || 0;
              for (var i = 0; i < pages.length; i++) {
                if (pages[i].id === currentId) {
                  return i;
                }
              }
              return 0;
            }

            // Dynamically create tabs based on pages
            Repeater {
              model: pluginApi?.pluginSettings?.pages || []

              delegate: NTabButton {
                id: tabButton
                text: modelData.name
                tabIndex: index
                checked: index === tabBar.currentIndex

                Component.onCompleted: {
                  topLeftRadius = Style.iRadiusM;
                  bottomLeftRadius = Style.iRadiusM;
                  topRightRadius = Style.iRadiusM;
                  bottomRightRadius = Style.iRadiusM;
                }

                onClicked: {
                  pluginApi.pluginSettings.current_page_id = modelData.id;
                  pluginApi.saveSettings();
                  loadTodos();
                }
              }
            }
          }


          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
              spacing: Style.marginS
              Layout.bottomMargin: Style.marginM

              NTextInput {
                id: newTodoInput
                placeholderText: pluginApi?.tr("panel.add_todo.placeholder")
                Layout.fillWidth: true
                Keys.onReturnPressed: addTodo()
              }

              NIconButton {
                icon: "plus"
                onClicked: addTodo()
              }
            }

            ListView {
              id: todoListView
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              model: root.filteredTodosModel
              spacing: Style.marginS
              boundsBehavior: Flickable.StopAtBounds
              flickableDirection: Flickable.VerticalFlick

              delegate: Item {
                id: delegateItem
                width: ListView.view.width
                height: Style.baseWidgetSize + Style.marginS

                required property int index
                required property var modelData

                // Properties for drag functionality
                property bool dragging: false
                property int dragStartY: 0
                property int dragStartIndex: -1
                property int dragTargetIndex: -1
                property int itemSpacing: Style.marginS

                // Properties for edit functionality
                property bool editing: false
                property string originalText: ""

                // Methods for edit functionality
                function startEdit() {
                  editing = true;
                  originalText = modelData.text;
                }

                function saveEdit() {
                  if (pluginApi && todoTextEdit.text.trim() !== "") {
                    var todos = pluginApi.pluginSettings.todos || [];

                    for (var i = 0; i < todos.length; i++) {
                      if (todos[i].id === modelData.id) {
                        todos[i].text = todoTextEdit.text.trim();
                        break;
                      }
                    }

                    pluginApi.pluginSettings.todos = todos;
                    pluginApi.saveSettings();

                    root.loadTodos();
                  }
                  editing = false;
                }

                function cancelEdit() {
                  editing = false;
                  // Restore the original text when cancelling
                  if (todoTextEdit) {
                    todoTextEdit.text = originalText;
                  }
                }

                // Watch for editing property changes to handle focus
                onEditingChanged: {
                    if (editing) {
                        // Use a timer to delay the focus operation
                        var timer = Qt.createQmlObject("
                            import QtQuick 2.0;
                            Timer {
                                interval: 50;
                                running: true;
                                onTriggered: {
                                    if (todoTextEdit && todoTextEdit.input) {
                                        todoTextEdit.input.forceActiveFocus();
                                    }
                                }
                            }", delegateItem);
                    }
                }

                // Position binding for non-dragging state
                y: {
                  if (delegateItem.dragging) {
                    return delegateItem.y;
                  }

                  var draggedIndex = -1;
                  var targetIndex = -1;
                  for (var i = 0; i < todoListView.count; i++) {
                    var item = todoListView.itemAtIndex(i);
                    if (item && item.dragging) {
                      draggedIndex = item.dragStartIndex;
                      targetIndex = item.dragTargetIndex;
                      break;
                    }
                  }

                  // If an item is being dragged, adjust positions
                  if (draggedIndex !== -1 && targetIndex !== -1 && draggedIndex !== targetIndex) {
                    var currentIndex = delegateItem.index;

                    if (draggedIndex < targetIndex) {
                      if (currentIndex > draggedIndex && currentIndex <= targetIndex) {
                        return (currentIndex - 1) * (delegateItem.height + delegateItem.itemSpacing);
                      }
                    } else {
                      if (currentIndex >= targetIndex && currentIndex < draggedIndex) {
                        return (currentIndex + 1) * (delegateItem.height + delegateItem.itemSpacing);
                      }
                    }
                  }

                  return delegateItem.index * (delegateItem.height + delegateItem.itemSpacing);
                }

                // Behavior for smooth animation when not dragging
                Behavior on y {
                  enabled: !delegateItem.dragging
                  NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutQuad
                  }
                }

                // The actual todo item rectangle
                Rectangle {
                  anchors.fill: parent
                  color: Color.mSurface
                  radius: Style.radiusS

                  RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.marginM
                    anchors.rightMargin: Style.marginM
                    spacing: Style.marginS

                    // Drag handle
                    Item {
                      id: dragHandle

                      Layout.preferredWidth: Style.baseWidgetSize * 0.5
                      Layout.preferredHeight: Style.baseWidgetSize * 0.8

                      NIcon {
                        id: dragHandleIcon
                        anchors.centerIn: parent
                        icon: "grip-vertical"
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                        opacity: 0.5

                        states: [
                          State {
                            name: "hovered"
                            when: dragHandleMouseArea.containsMouse
                            PropertyChanges {
                              target: dragHandleIcon
                              opacity: 1.0
                              color: Color.mOnSurface
                            }
                          }
                        ]

                        transitions: [
                          Transition {
                            from: "*"; to: "hovered"
                            NumberAnimation { properties: "opacity"; duration: 150 }
                          },
                          Transition {
                            from: "hovered"; to: "*"
                            NumberAnimation { properties: "opacity"; duration: 150 }
                          }
                        ]
                      }

                      MouseArea {
                        id: dragHandleMouseArea

                        anchors.fill: parent
                        cursorShape: Qt.SizeVerCursor
                        hoverEnabled: true
                        preventStealing: false
                        z: 1000

                        onPressed: mouse => {
                                      delegateItem.dragStartIndex = delegateItem.index;
                                      delegateItem.dragTargetIndex = delegateItem.index;
                                      delegateItem.dragStartY = delegateItem.y;
                                      delegateItem.dragging = true;
                                      delegateItem.z = 999;

                                      // Signal that interaction started (prevents panel close)
                                      preventStealing = true;
                                    }

                        onPositionChanged: mouse => {
                                              if (delegateItem.dragging) {
                                                var dy = mouse.y - dragHandle.height / 2;
                                                var newY = delegateItem.y + dy;

                                                // Constrain within bounds
                                                newY = Math.max(0, Math.min(newY, todoListView.contentHeight - delegateItem.height));
                                                delegateItem.y = newY;

                                                // Calculate target index (but don't apply yet)
                                                var targetIndex = Math.floor((newY + delegateItem.height / 2) / (delegateItem.height + delegateItem.itemSpacing));
                                                targetIndex = Math.max(0, Math.min(targetIndex, todoListView.count - 1));

                                                delegateItem.dragTargetIndex = targetIndex;
                                              }
                                            }

                        onReleased: {
                          // Apply the model change now that drag is complete
                          if (delegateItem.dragStartIndex !== -1 && delegateItem.dragTargetIndex !== -1 && delegateItem.dragStartIndex !== delegateItem.dragTargetIndex) {
                            moveTodoItem(delegateItem.dragStartIndex, delegateItem.dragTargetIndex);
                          }

                          delegateItem.dragging = false;
                          delegateItem.dragStartIndex = -1;
                          delegateItem.dragTargetIndex = -1;
                          delegateItem.z = 0;

                          // Reset interaction prevention
                          preventStealing = false;
                        }

                        onCanceled: {
                          // Handle cancel (e.g., ESC key pressed during drag)
                          delegateItem.dragging = false;
                          delegateItem.dragStartIndex = -1;
                          delegateItem.dragTargetIndex = -1;
                          delegateItem.z = 0;

                          // Reset interaction prevention
                          preventStealing = false;
                        }
                      }
                    }

                    // Checkbox
                    Item {
                      Layout.preferredWidth: Style.baseWidgetSize * 0.7
                      Layout.preferredHeight: Style.baseWidgetSize * 0.7

                      Rectangle {
                        id: box

                        anchors.fill: parent
                        radius: Style.iRadiusXS
                        color: modelData.completed ? Color.mPrimary : Color.mSurface
                        border.color: Color.mOutline
                        border.width: Style.borderS

                        Behavior on color {
                          ColorAnimation {
                            duration: Style.animationFast
                          }
                        }

                        NIcon {
                          visible: modelData.completed
                          anchors.centerIn: parent
                          anchors.horizontalCenterOffset: -1
                          icon: "check"
                          color: Color.mOnPrimary
                          pointSize: Math.max(Style.fontSizeXS, Style.baseWidgetSize * 0.7 * 0.5)
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            if (pluginApi) {
                              var todos = pluginApi.pluginSettings.todos || [];

                              for (var i = 0; i < todos.length; i++) {
                                if (todos[i].id === modelData.id) {
                                  todos[i].completed = !modelData.completed;
                                  break;
                                }
                              }

                              pluginApi.pluginSettings.todos = todos;

                              var completedCount = 0;
                              for (var j = 0; j < todos.length; j++) {
                                if (todos[j].completed) {
                                  completedCount++;
                                }
                              }
                              pluginApi.pluginSettings.completedCount = completedCount;

                              moveTodoToCorrectPosition(modelData.id);

                              loadTodos();
                            }
                          }
                        }
                      }
                    }

                    // Text container (using Layout to fit in the RowLayout)
                    Item {
                      Layout.fillWidth: true
                      Layout.preferredHeight: parent.height

                      // Normal text display
                      NText {
                        id: todoTextDisplay
                        visible: !delegateItem.editing
                        text: modelData.text
                        color: modelData.completed ? Color.mOnSurfaceVariant : Color.mOnSurface
                        font.strikeout: modelData.completed
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        anchors.fill: parent
                        anchors.leftMargin: Style.marginS
                        anchors.rightMargin: Style.marginS
                      }

                      // Edit text field - Using TextField directly to have more control
                      Item {
                        id: todoTextEditContainer
                        visible: delegateItem.editing
                        anchors.fill: parent
                        anchors.leftMargin: Style.marginS
                        anchors.rightMargin: Style.baseWidgetSize * 0.8 + Style.marginL
                        height: parent.height * 0.8
                        anchors.verticalCenter: parent.verticalCenter

                        TextField {
                          id: todoTextEdit
                          anchors.fill: parent
                          anchors.rightMargin: Style.baseWidgetSize * 0.8
                          text: modelData.text

                          verticalAlignment: TextInput.AlignVCenter

                          echoMode: TextInput.Normal
                          color: Color.mOnSurface
                          placeholderTextColor: Qt.alpha(Color.mOnSurfaceVariant, 0.6)

                          selectByMouse: true

                          topPadding: 0
                          bottomPadding: 0
                          leftPadding: Style.marginS
                          rightPadding: Style.baseWidgetSize * 0.6

                          font.family: Settings.data.ui.fontDefault
                          font.pointSize: Style.fontSizeS * Style.uiScaleRatio
                          font.weight: Style.fontWeightRegular

                          // Remove the frame/background to eliminate border
                          background: null

                          Keys.onReturnPressed: {
                            delegateItem.saveEdit();
                          }

                          Keys.onEscapePressed: {
                            delegateItem.cancelEdit();
                          }

                          // Set focus when visible
                          onVisibleChanged: {
                            if (visible) {
                              Qt.callLater(function() {
                                todoTextEdit.forceActiveFocus();
                              });
                            }
                          }
                        }

                        // Clear button
                        NIconButton {
                          icon: "restore"
                          tooltipText: "Clear text"

                          anchors.right: parent.right
                          anchors.verticalCenter: parent.verticalCenter
                          anchors.rightMargin: Style.marginM

                          scale: 0.7
                          colorBg: "transparent"
                          colorBgHover: "transparent"
                          colorFg: Color.mOnSurface
                          colorFgHover: Color.mError

                          visible: todoTextEdit.text.length > 0

                          onClicked: {
                            todoTextEdit.clear();
                            todoTextEdit.forceActiveFocus();
                          }
                        }
                      }
                    }

                    // Edit button (only show when not editing) and Save/Cancel buttons
                    Item {
                      Layout.preferredWidth: Style.baseWidgetSize * 0.8
                      Layout.preferredHeight: parent.height

                      // Edit button (only show when not editing)
                      Item {
                        id: editButtonContainer
                        visible: !delegateItem.editing
                        anchors.centerIn: parent

                        implicitWidth: Style.baseWidgetSize * 0.8
                        implicitHeight: Style.baseWidgetSize * 0.8

                        NIcon {
                          id: editButtonIcon
                          anchors.centerIn: parent
                          icon: "pencil"
                          pointSize: Style.fontSizeM
                          color: Color.mOnSurfaceVariant
                          opacity: 0.5

                          MouseArea {
                            id: editMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              delegateItem.startEdit();
                            }
                          }

                          ToolTip {
                            id: editToolTip
                            text: pluginApi?.tr("panel.todo_item.edit_button_tooltip") || "Edit"
                            delay: 1000
                            parent: editButtonIcon
                            visible: editMouseArea.containsMouse

                            contentItem: NText {
                              text: editToolTip.text
                              color: Color.mOnPrimary
                              font.pointSize: Style.fontSizeXS
                            }

                            background: Rectangle {
                              color: Color.mPrimary
                              radius: Style.iRadiusS
                              border.color: Qt.rgba(0, 0, 0, 0.2)
                              border.width: 1
                            }
                          }

                          states: [
                            State {
                              name: "hovered"
                              when: editMouseArea.containsMouse
                              PropertyChanges {
                                target: editButtonIcon
                                opacity: 1.0
                                color: Color.mPrimary
                              }
                            }
                          ]

                          transitions: [
                            Transition {
                              from: "*"; to: "hovered"
                              NumberAnimation { properties: "opacity"; duration: 150 }
                            },
                            Transition {
                              from: "hovered"; to: "*"
                              NumberAnimation { properties: "opacity"; duration: 150 }
                            }
                          ]
                        }
                      }

                      // Save/Cancel buttons (only show when editing)
                      RowLayout {
                        id: editButtonsRow
                        visible: delegateItem.editing
                        anchors.centerIn: parent
                        spacing: Style.marginS

                        NIconButton {
                          icon: "check"
                          Layout.preferredWidth: Style.baseWidgetSize * 0.6
                          Layout.preferredHeight: Style.baseWidgetSize * 0.6

                          onClicked: {
                            delegateItem.saveEdit();
                          }
                        }

                        NIconButton {
                          icon: "x"
                          Layout.preferredWidth: Style.baseWidgetSize * 0.6
                          Layout.preferredHeight: Style.baseWidgetSize * 0.6

                          onClicked: {
                            delegateItem.cancelEdit();
                          }
                        }
                      }
                    }

                    // Delete button
                    Item {
                      id: deleteButtonContainer
                      implicitWidth: Style.baseWidgetSize * 0.8
                      implicitHeight: Style.baseWidgetSize * 0.8

                      NIcon {
                        id: deleteButtonIcon
                        anchors.centerIn: parent
                        icon: "x"
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                        opacity: 0.5

                        MouseArea {
                          id: mouseArea
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            // Directly modify the todos list through pluginApi
                            if (pluginApi) {
                              var todos = pluginApi.pluginSettings.todos || [];
                              var indexToRemove = -1;

                              for (var i = 0; i < todos.length; i++) {
                                if (todos[i].id === modelData.id) {
                                  indexToRemove = i;
                                  break;
                                }
                              }

                              if (indexToRemove !== -1) {
                                todos.splice(indexToRemove, 1);

                                pluginApi.pluginSettings.todos = todos;
                                pluginApi.pluginSettings.count = todos.length;

                                // Recalculate completed count after removal
                                var completedCount = 0;
                                for (var j = 0; j < todos.length; j++) {
                                  if (todos[j].completed) {
                                    completedCount++;
                                  }
                                }
                                pluginApi.pluginSettings.completedCount = completedCount;

                                pluginApi.saveSettings();
                                loadTodos();
                              } else {
                                Logger.e("Todo", "Todo with ID " + modelData.id + " not found for deletion");
                              }
                            } else {
                              Logger.e("Todo", "pluginApi is null, cannot delete todo");
                            }
                          }
                        }

                        ToolTip {
                          id: deleteToolTip
                          text: pluginApi?.tr("panel.todo_item.delete_button_tooltip") || "Delete"
                          delay: 1000
                          parent: deleteButtonIcon
                          visible: mouseArea.containsMouse

                          contentItem: NText {
                            text: deleteToolTip.text
                            color: Color.mOnError
                            font.pointSize: Style.fontSizeXS
                          }

                          background: Rectangle {
                            color: Color.mError
                            radius: Style.iRadiusS
                            border.color: Qt.rgba(0, 0, 0, 0.2)
                            border.width: 1
                          }
                        }

                        states: [
                          State {
                            name: "hovered"
                            when: mouseArea.containsMouse
                            PropertyChanges {
                              target: deleteButtonIcon
                              opacity: 1.0
                              color: Color.mError
                            }
                          }
                        ]

                        transitions: [
                          Transition {
                            from: "*"; to: "hovered"
                            NumberAnimation { properties: "opacity"; duration: 150 }
                          },
                          Transition {
                            from: "hovered"; to: "*"
                            NumberAnimation { properties: "opacity"; duration: 150 }
                          }
                        ]
                      }
                    }
                  }
                }
              }

              highlightRangeMode: ListView.NoHighlightRange
              preferredHighlightBegin: 0
              preferredHighlightEnd: 0

              header: null
            }

            // Empty state overlay - using a separate container that doesn't interfere with layout
            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
              Layout.alignment: Qt.AlignCenter
              visible: root.filteredTodosModel.count === 0

              NText {
                anchors.centerIn: parent
                text: pluginApi?.tr("panel.empty_state.message") || "No todo items yet"
                color: Color.mOnSurfaceVariant
                font.pointSize: Style.fontSizeM
                font.weight: Font.Normal
              }
            }
          }
        }
      }
    }
  }


  function addTodo() {
    if (newTodoInput.text.trim() !== "") {
      if (pluginApi) {
        var todos = pluginApi.pluginSettings.todos || [];
        var currentPageId = pluginApi.pluginSettings.current_page_id || 0;

        var newTodo = {
          id: Date.now()
              ,
          text: newTodoInput.text.trim(),
          completed: false,
          createdAt: new Date().toISOString(),
          pageId: currentPageId
        };

        todos.unshift(newTodo);

        pluginApi.pluginSettings.todos = todos;

        pluginApi.pluginSettings.count = todos.length;

        pluginApi.saveSettings();

        newTodoInput.text = "";
        loadTodos();
      }
    }
  }

  function moveTodoItem(fromIndex, toIndex) {
    if (fromIndex === toIndex)
      return;

    var currentPageId = pluginApi?.pluginSettings?.current_page_id || 0;
    var pluginTodos = root.rawTodos;

    // Filter todos for the current page
    var pageTodos = pluginTodos.filter(function(todo) {
      return todo.pageId === currentPageId;
    });

    if (fromIndex < 0 || fromIndex >= pageTodos.length)
      return;
    if (toIndex < 0 || toIndex >= pageTodos.length)
      return;

    // Create a copy of the full todos array
    var newTodos = pluginTodos.slice();

    // Find the item in the full array using the fromIndex from the pageTodos
    var itemToMove = pageTodos[fromIndex];

    // Find the index of this item in the full array
    var fromGlobalIndex = -1;
    for (var i = 0; i < newTodos.length; i++) {
      if (newTodos[i].id === itemToMove.id) {
        fromGlobalIndex = i;
        break;
      }
    }

    if (fromGlobalIndex === -1) return;

    // Remove the item from its current position
    var movedItem = newTodos.splice(fromGlobalIndex, 1)[0];

    // Find the target position in the full array
    var toGlobalIndex = -1;
    var targetItem = pageTodos[toIndex];

    // If moving down, we need to account for the item being removed
    if (fromIndex < toIndex) {
      // Adjust target index since we removed an item before the target
      var adjustedPageIndex = toIndex;
      var count = 0;
      for (var i = 0; i < newTodos.length; i++) {
        if (newTodos[i].pageId === currentPageId) {
          if (count === adjustedPageIndex) {
            toGlobalIndex = i;
            break;
          }
          count++;
        }
      }
    } else {
      // Moving up, target position stays the same relative to global array
      var count = 0;
      for (var i = 0; i < newTodos.length; i++) {
        if (newTodos[i].pageId === currentPageId) {
          if (count === toIndex) {
            toGlobalIndex = i;
            break;
          }
          count++;
        }
      }
    }

    // Insert the item at the new position
    if (toGlobalIndex === -1) {
      // If target index is at the end of the page's items
      var lastPageIndex = -1;
      var count = 0;
      for (var i = 0; i < newTodos.length; i++) {
        if (newTodos[i].pageId === currentPageId) {
          lastPageIndex = i;
          count++;
        }
      }
      if (count === toIndex + 1) {
        toGlobalIndex = lastPageIndex + 1;
      } else {
        return;
      }
    }

    newTodos.splice(toGlobalIndex, 0, movedItem);

    // Update the plugin settings
    if (pluginApi) {
      pluginApi.pluginSettings.todos = newTodos;
      pluginApi.saveSettings();
      loadTodos();
    }
  }
}
