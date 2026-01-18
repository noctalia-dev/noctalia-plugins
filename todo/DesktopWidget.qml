import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root

  property var pluginApi: null
  property bool expanded: pluginApi?.pluginSettings?.isExpanded !== undefined ? pluginApi.pluginSettings.isExpanded : (pluginApi?.manifest?.metadata?.defaultSettings?.isExpanded || false)
  property bool showCompleted: pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted
  property ListModel filteredTodosModel: ListModel {}

  function moveTodoToCorrectPosition(todoId) {
    if (!pluginApi) return;

    var todos = pluginApi.pluginSettings.todos || [];
    var currentPageId = pluginApi?.pluginSettings?.current_page_id || 0;
    var todoIndex = -1;

    for (var i = 0; i < todos.length; i++) {
      if (todos[i].id === todoId) {
        todoIndex = i;
        break;
      }
    }

    if (todoIndex !== -1) {
      var movedTodo = todos[todoIndex];

      todos.splice(todoIndex, 1);

      // Only reorder within the same page
      if (movedTodo.pageId === currentPageId) {
        if (movedTodo.completed) {
          // Place completed items at the end of the page
          var insertIndex = todos.length;
          for (var j = todos.length - 1; j >= 0; j--) {
            if (todos[j].pageId === currentPageId && todos[j].completed) {
              insertIndex = j + 1;
              break;
            }
          }
          todos.splice(insertIndex, 0, movedTodo);
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
          todos.splice(insertIndex, 0, movedTodo);
        }
      } else {
        // If the todo is not on the current page, just add it back to its original position
        todos.splice(todoIndex, 0, movedTodo);
      }

      pluginApi.pluginSettings.todos = todos;
      pluginApi.saveSettings();
    }
  }

  showBackground: (pluginApi && pluginApi.pluginSettings ? (pluginApi.pluginSettings.showBackground !== undefined ? pluginApi.pluginSettings.showBackground : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground) : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground)

  readonly property color todoBg: showBackground ? Qt.rgba(0, 0, 0, 0.2) : "transparent"
  readonly property color itemBg: showBackground ? Color.mSurface : "transparent"
  readonly property color completedItemBg: showBackground ? Color.mSurfaceVariant : "transparent"

  // Scaled dimensions
  readonly property int scaledMarginM: Math.round(Style.marginM * widgetScale)
  readonly property int scaledMarginS: Math.round(Style.marginS * widgetScale)
  readonly property int scaledMarginL: Math.round(Style.marginL * widgetScale)
  readonly property int scaledBaseWidgetSize: Math.round(Style.baseWidgetSize * widgetScale)
  readonly property int scaledFontSizeL: Math.round(Style.fontSizeL * widgetScale)
  readonly property int scaledFontSizeM: Math.round(Style.fontSizeM * widgetScale)
  readonly property int scaledFontSizeS: Math.round(Style.fontSizeS * widgetScale)
  readonly property int scaledRadiusM: Math.round(Style.radiusM * widgetScale)
  readonly property int scaledRadiusS: Math.round(Style.radiusS * widgetScale)

  implicitWidth: Math.round(300 * widgetScale)
  implicitHeight: {
    var headerHeight = scaledBaseWidgetSize + scaledMarginL * 2;
    if (!expanded)
      return headerHeight;

    // Add the height of the tab bar when expanded
    var tabBarHeight = scaledBaseWidgetSize * 0.8;
    var todosCount = root.filteredTodosModel.count;
    var contentHeight = (todosCount === 0) ? scaledBaseWidgetSize : (scaledBaseWidgetSize * todosCount + scaledMarginS * (todosCount - 1));

    var totalHeight = contentHeight + headerHeight + tabBarHeight + scaledMarginS + scaledMarginM * 4;
    return Math.min(totalHeight, headerHeight + tabBarHeight + Math.round(400 * widgetScale));
  }

  function getCurrentTodos() {
    return pluginApi?.pluginSettings?.todos || [];
  }

  function getCurrentShowCompleted() {
    return pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
  }

  function updateFilteredTodos() {
    if (!pluginApi)
      return;

    filteredTodosModel.clear();

    var pluginTodos = getCurrentTodos();
    var currentShowCompleted = getCurrentShowCompleted();
    var currentPageId = pluginApi?.pluginSettings?.current_page_id || 0;

    // Filter todos for the current page
    var pageTodos = pluginTodos.filter(function(todo) {
      return todo.pageId === currentPageId;
    });

    var filtered = pageTodos;

    if (!currentShowCompleted) {
      filtered = pageTodos.filter(function (todo) {
        return !todo.completed;
      });
    }

    for (var i = 0; i < filtered.length; i++) {
      filteredTodosModel.append({
                                  id: filtered[i].id,
                                  text: filtered[i].text,
                                  completed: filtered[i].completed,
                                  pageId: filtered[i].pageId || 0
                                });
    }
  }

  Timer {
    id: updateTimer
    interval: 200
    running: !!pluginApi
    repeat: true
    onTriggered: {
      updateFilteredTodos();
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      root.showCompleted = getCurrentShowCompleted();
      updateFilteredTodos();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      updateFilteredTodos();
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: scaledMarginM
    spacing: scaledMarginS

    Item {
      Layout.fillWidth: true
      height: scaledBaseWidgetSize

      MouseArea {
        anchors.fill: parent
        onClicked: {
          root.expanded = !root.expanded;
          if (pluginApi) {
            pluginApi.pluginSettings.isExpanded = root.expanded;
            pluginApi.saveSettings();
          }
        }
      }

      RowLayout {
        anchors.fill: parent
        spacing: scaledMarginS

        NIcon {
          icon: "checklist"
          pointSize: scaledFontSizeL
        }

        NText {
          text: pluginApi?.tr("desktop_widget.header_title")
          font.pointSize: scaledFontSizeL
          font.weight: Font.Medium
        }

        Item {
          Layout.fillWidth: true
        }

        NText {
          text: {
            var todos = pluginApi?.pluginSettings?.todos || [];
            var activeTodos = todos.filter(function (todo) {
              return !todo.completed;
            }).length;

            var text = pluginApi?.tr("desktop_widget.items_count");
            return text.replace("{active}", activeTodos).replace("{total}", todos.length);
          }
          color: Color.mOnSurfaceVariant
          font.pointSize: scaledFontSizeS
        }

        NIcon {
          icon: root.expanded ? "chevron-up" : "chevron-down"
          pointSize: scaledFontSizeM
          color: Color.mOnSurfaceVariant
        }
      }
    }

    // Page selector using tab components - only visible when expanded
    NTabBar {
      id: tabBar
      Layout.fillWidth: true
      visible: expanded
      Layout.topMargin: scaledMarginS
      distributeEvenly: true
      currentIndex: currentPageIndex
      color: "transparent"
      border.width: 0

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
          text: modelData.name
          tabIndex: index
          checked: index === tabBar.currentPageIndex

          color: showBackground ?
                 (isHovered ? Color.mHover : (checked ? Color.mPrimary : Color.mOnPrimary)) :
                 (isHovered ? Color.mHover : (checked ? "transparent" : "transparent"))

          border.width: showBackground ? 0 : (checked ? 1 : 0)
          border.color: Color.mPrimary

          Component.onCompleted: {
            topLeftRadius = Style.iRadiusM;
            bottomLeftRadius = Style.iRadiusM;
            topRightRadius = Style.iRadiusM;
            bottomRightRadius = Style.iRadiusM;
          }

          onClicked: {
            pluginApi.pluginSettings.current_page_id = modelData.id;
            pluginApi.saveSettings();
            updateFilteredTodos();
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: expanded

      // Background with border - fills entire available space
      Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: root.todoBg
        radius: scaledRadiusM
        // border.color: showBackground ? Color.mOutline : "transparent"
        // border.width: showBackground ? 1 : 0
      }

      // Inner container that is fully inset from the border area
      Item {
        id: innerContentArea
        anchors.fill: parent
        anchors.margins: showBackground ? (backgroundRect.border.width + 1) : 0

        // Scrollable area for the todo items
        Flickable {
          id: todoFlickable
          anchors.fill: parent

          leftMargin: scaledMarginM
          rightMargin: scaledMarginM
          topMargin: scaledMarginM
          bottomMargin: scaledMarginM

          contentWidth: width
          contentHeight: columnLayout.implicitHeight

          flickableDirection: Flickable.VerticalFlick
          clip: true
          boundsBehavior: Flickable.DragOverBounds
          interactive: true
          pressDelay: 150

          Column {
            id: columnLayout
            width: todoFlickable.width
                   - todoFlickable.leftMargin
                   - todoFlickable.rightMargin
            spacing: scaledMarginS

            Repeater {
              model: root.filteredTodosModel

              delegate: Item {
                width: parent.width
                height: scaledBaseWidgetSize

                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 0
                  color: model.completed ? root.completedItemBg : root.itemBg
                  radius: Style.iRadiusS * widgetScale

                  Item {
                    anchors.fill: parent
                    anchors.margins: scaledMarginM

                    // Custom checkbox implementation with TapHandler
                    Item {
                      id: customCheckboxContainer
                      width: scaledBaseWidgetSize * 0.7  // Slightly larger touch area
                      height: scaledBaseWidgetSize * 0.7
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter

                      Rectangle {
                        id: customCheckbox
                        width: scaledBaseWidgetSize * 0.5
                        height: scaledBaseWidgetSize * 0.5
                        radius: Style.iRadiusXS
                        color: showBackground ? (model.completed ? Color.mPrimary : Color.mSurface) : "transparent"
                        border.color: Color.mOutline
                        border.width: Style.borderS
                        anchors.centerIn: parent

                        NIcon {
                          visible: model.completed
                          anchors.centerIn: parent
                          anchors.horizontalCenterOffset: 0
                          icon: "check"
                          color: showBackground ? Color.mOnPrimary : Color.mPrimary
                          pointSize: Math.max(Style.fontSizeXS, width * 0.5)
                        }

                        // MouseArea for the checkbox
                        MouseArea {
                          anchors.fill: parent
                          hoverEnabled: false

                          onClicked: {
                            if (pluginApi) {
                              var todos = pluginApi.pluginSettings.todos || [];

                              for (var i = 0; i < todos.length; i++) {
                                if (todos[i].id === model.id) {
                                  // Preserve all properties including pageId when updating
                                  todos[i] = {
                                    id: todos[i].id,
                                    text: todos[i].text,
                                    completed: !todos[i].completed,
                                    createdAt: todos[i].createdAt,
                                    pageId: todos[i].pageId || 0
                                  };
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

                              moveTodoToCorrectPosition(model.id);

                              pluginApi.saveSettings();
                              updateFilteredTodos();
                            }
                          }
                        }
                      }
                    }

                    // Text for the todo item
                    NText {
                      text: model.text
                      color: model.completed ? Color.mOnSurfaceVariant : Color.mOnSurface
                      font.strikeout: model.completed
                      elide: Text.ElideRight
                      anchors.left: customCheckboxContainer.right
                      anchors.leftMargin: scaledMarginS
                      anchors.right: parent.right
                      anchors.rightMargin: scaledMarginM
                      anchors.verticalCenter: parent.verticalCenter
                      font.pointSize: scaledFontSizeS
                    }
                  }
                }
              }
            }
          }
        }

        // Empty state overlay
        Item {
          anchors.fill: parent
          anchors.margins: scaledMarginS
          visible: root.filteredTodosModel.count === 0

          NText {
            anchors.centerIn: parent
            text: pluginApi?.tr("desktop_widget.empty_state")
            color: Color.mOnSurfaceVariant
            font.pointSize: scaledFontSizeM
            font.weight: Font.Normal
          }
        }
      }
    }
  }
}
