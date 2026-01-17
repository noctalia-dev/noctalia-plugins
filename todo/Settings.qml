import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property bool valueShowCompleted: pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted

  property bool valueShowBackground: pluginApi?.pluginSettings?.showBackground !== undefined ? pluginApi.pluginSettings.showBackground : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground

  spacing: Style.marginL  // Increased spacing to make the panel slightly larger

  Component.onCompleted: {
    Logger.i("Todo", "Settings UI loaded");
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show_completed.label")
    description: pluginApi?.tr("settings.show_completed.description")
    checked: root.valueShowCompleted
    onToggled: function (checked) {
      root.valueShowCompleted = checked;
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.background_color.label")
    description: pluginApi?.tr("settings.background_color.description")
    checked: root.valueShowBackground
    onToggled: function (checked) {
      root.valueShowBackground = checked;
    }
  }

  // Section for managing pages
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NText {
      text: pluginApi?.tr("settings.pages.label") || "Manage Pages"
      font.pointSize: Style.fontSizeL
      font.weight: Font.Bold
      Layout.topMargin: Style.marginL
    }

    // Input for adding new pages
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NTextInput {
        id: newPageInput
        placeholderText: pluginApi?.tr("settings.pages.placeholder") || "Enter new page name"
        Layout.fillWidth: true
        Keys.onReturnPressed: addPage()
      }

      NButton {
        text: pluginApi?.tr("settings.pages.add_button") || "Add Page"
        onClicked: addPage()
      }
    }

    // List of existing pages with manual scroll support
    Item {
      Layout.fillWidth: true
      height: Math.min(pagesListView.contentHeight, 200)  // Limit height with scrollbar if needed

      Flickable {
        id: pagesListView
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        ColumnLayout {
          id: contentColumn
          width: parent.width
          spacing: Style.marginS

          Repeater {
            model: pluginApi?.pluginSettings?.pages || []

            delegate: Item {
              width: parent.width
              height: Style.baseWidgetSize

              // Properties to track if this item is being edited
              property bool editing: false
              property string originalName: modelData.name || ""

              // Function to save the renamed page
              function saveRename() {
                var newName = renameInput.text.trim();
                if (newName === "") {
                  // Don't save empty names, just exit editing mode
                  editing = false;
                  return;
                }

                if (newName === originalName) {
                  // Name hasn't changed, just exit editing mode
                  editing = false;
                  return;
                }

                if (!isPageNameUnique(newName, index)) {
                  ToastService.showError(pluginApi?.tr("settings.pages.name_exists") || "Page name already exists");
                  // Don't exit editing mode to allow user to fix the name
                  return;
                }

                // If we get here, the name is valid and different from the original
                var pages = pluginApi.pluginSettings.pages || [];
                pages[index].name = newName;
                pluginApi.pluginSettings.pages = pages;
                pluginApi.saveSettings();

                // Update the originalName to the new value for future edits
                originalName = newName;
                editing = false;
              }

              // Function to cancel renaming
              function cancelRename() {
                // Restore the original text when cancelling
                if (renameInput) {
                  renameInput.text = originalName;
                }
                editing = false;
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                spacing: Style.marginS

                // Container for the normal view (when not editing)
                Item {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  visible: !editing  // Use local property instead of parent

                  RowLayout {
                    anchors.fill: parent
                    spacing: Style.marginS

                    NText {
                      text: modelData.name
                      Layout.fillWidth: true
                      verticalAlignment: Text.AlignVCenter
                    }

                    NIconButton {
                      icon: "pencil"
                      tooltipText: pluginApi?.tr("settings.pages.rename_button_tooltip") || "Rename"
                      onClicked: {
                        // Switch to editing mode and capture the current name
                        originalName = modelData.name; // Capture the current name before editing
                        editing = true;
                      }
                    }

                    NIconButton {
                      icon: "trash"
                      tooltipText: pluginApi?.tr("settings.pages.delete_button_tooltip") || "Delete"
                      colorFg: Color.mError
                      enabled: (pluginApi?.pluginSettings?.pages?.length || 0) > 1  // Don't allow deleting the last page
                      onClicked: {
                        if ((pluginApi?.pluginSettings?.pages?.length || 0) <= 1) {
                          ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last") || "Cannot delete the last page");
                          return; // This will now properly exit the entire onClicked function
                        }

                        // Show confirmation dialog before deleting
                        root.showDeleteConfirmation(index, modelData.name);
                      }
                    }
                  }
                }

                // Editing UI - only visible when in editing mode
                RowLayout {
                  Layout.fillHeight: true
                  Layout.fillWidth: true
                  spacing: Style.marginS
                  visible: editing  // Use local property instead of parent

                  NTextInput {
                    id: renameInput
                    text: originalName  // Use local property instead of parent
                    Layout.fillWidth: true
                    Layout.preferredWidth: 150  // Set a minimum width for better UX
                    focus: editing  // Focus when editing starts

                    Keys.onReturnPressed: saveRename()
                    Keys.onEscapePressed: cancelRename()

                    // Auto-focus when visible and update text when entering edit mode
                    onVisibleChanged: {
                      if (visible && editing) {
                        text = originalName;
                        forceActiveFocus();
                      }
                    }
                  }

                  NButton {
                    text: "✓"
                    fontSize: Style.fontSizeS
                    backgroundColor: Color.mPrimary
                    textColor: Color.mOnPrimary
                    onClicked: saveRename()
                  }

                  NButton {
                    text: "✕"
                    fontSize: Style.fontSizeS
                    backgroundColor: Color.mError
                    textColor: Color.mOnError
                    onClicked: cancelRename()
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // Helper functions for page management
  function getNextPageId() {
    var pages = pluginApi?.pluginSettings?.pages || [];
    if (pages.length === 0) {
      return 0;  // For empty array, return 0
    }

    var maxId = -1;
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].id > maxId) {
        maxId = pages[i].id;
      }
    }
    return maxId + 1;
  }

  function isPageNameUnique(name, excludeIndex) {
    var pages = pluginApi?.pluginSettings?.pages || [];
    var lowerName = name.toLowerCase().trim();
    for (var i = 0; i < pages.length; i++) {
      if (i !== excludeIndex && pages[i].name.toLowerCase().trim() === lowerName) {
        return false;
      }
    }
    return true;
  }

  function promptForPageName(title, message, defaultValue) {
    // In a real implementation, you would use a proper dialog
    // For now, we'll return a fixed value to avoid runtime errors
    // In a real app, you'd want to create a proper dialog component
    return defaultValue + "_renamed"; // Placeholder implementation
  }

  function addPage() {
    var name = newPageInput.text.trim();

    if (name === "") {
      ToastService.showError(pluginApi?.tr("settings.pages.empty_name") || "Page name cannot be empty");
      return;
    }

    if (!isPageNameUnique(name, -1)) {
      ToastService.showError(pluginApi?.tr("settings.pages.name_exists") || "Page name already exists");
      return;
    }

    var newPage = {
      id: getNextPageId(),
      name: name
    };

    var pages = pluginApi.pluginSettings?.pages || [];
    pages.push(newPage);
    pluginApi.pluginSettings.pages = pages;
    pluginApi.saveSettings();

    newPageInput.text = "";
    newPageInput.forceActiveFocus();
  }

  // Confirmation dialog for page deletion
  Popup {
    id: confirmDialog
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: 300
    height: 150

    background: Rectangle {
      color: Color.mSurface
      border.color: Color.mOutline
      border.width: 1
      radius: Style.radiusL
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        id: confirmText
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Are you sure you want to delete this page?"
        verticalAlignment: Text.AlignVCenter
      }

      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: Style.marginS

        NButton {
          text: "Cancel"
          onClicked: confirmDialog.close()
        }

        NButton {
          text: "Delete"
          textColor: Color.mOnError
          backgroundColor: Color.mError
          onClicked: {
            // Perform actual deletion
            performPageDeletion(confirmDialog.pageIndex);
            confirmDialog.close();
          }
        }
      }
    }

    // Property to store the index of the page to delete
    property int pageIndex: -1
  }

  // Function to show the confirmation dialog
  function showDeleteConfirmation(pageIdx, pageName) {
    confirmDialog.pageIndex = pageIdx;
    var confirmMessage = pluginApi?.tr("settings.pages.confirm_delete_message") || "Are you sure you want to delete page '{pageName}'?\n\nAll todos in this page will be transferred to the first page.";
    confirmText.text = confirmMessage.replace("{pageName}", pageName);
    confirmDialog.open();
  }

  // Function to perform the actual page deletion
  function performPageDeletion(pageIdx) {
    if (pageIdx < 0)
      return; // Invalid index

    var pages = pluginApi.pluginSettings.pages || [];
    if (pages.length <= 1) {
      ToastService.showError(pluginApi?.tr("settings.pages.cannot_delete_last") || "Cannot delete the last page");
      return;
    }

    var pageToDeleteId = pages[pageIdx].id;
    var todos = pluginApi.pluginSettings.todos || [];
    var firstPageId = pages[0].id;

    // Transfer todos from the page being deleted to the first page
    for (var i = 0; i < todos.length; i++) {
      if (todos[i].pageId === pageToDeleteId) {
        // Move todo to the first page
        todos[i].pageId = firstPageId;
      }
    }

    // Remove the page from the pages array
    pages.splice(pageIdx, 1);

    // If deleting the current page, switch to the first page
    if (pageToDeleteId === pluginApi.pluginSettings.current_page_id) {
      if (pages.length > 0) {
        pluginApi.pluginSettings.current_page_id = pages[0].id;
      } else {
        // If this was the last page, create a default page
        var defaultPage = {
          id: 0,
          name: "General"
        };
        pages.push(defaultPage);
        pluginApi.pluginSettings.current_page_id = 0;
      }
    }

    // Update IDs to be sequential after deletion
    for (var i = 0; i < pages.length; i++) {
      pages[i].id = i;
    }

    pluginApi.pluginSettings.pages = pages;
    pluginApi.pluginSettings.todos = todos; // Update todos with transferred items
    pluginApi.saveSettings();
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Todo", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.showCompleted = root.valueShowCompleted;
    pluginApi.pluginSettings.showBackground = root.valueShowBackground;
    pluginApi.saveSettings();

    Logger.i("Todo", "Settings saved successfully");
    return;
  }
}
