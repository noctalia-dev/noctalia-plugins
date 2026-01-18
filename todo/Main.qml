import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  property var pluginApi: null

  Component.onCompleted: {
    if (pluginApi) {
      if (!pluginApi.pluginSettings.pages) {
        pluginApi.pluginSettings.pages = [
          {
            id: 0,
            name: "General"
          }
        ];
        pluginApi.pluginSettings.current_page_id = 0;
      }

      if (!pluginApi.pluginSettings.todos) {
        pluginApi.pluginSettings.todos = [];
        pluginApi.pluginSettings.count = 0;
        pluginApi.pluginSettings.completedCount = 0;
      }

      if (pluginApi.pluginSettings.isExpanded === undefined) {
        pluginApi.pluginSettings.isExpanded = false;
      }

      // Ensure all existing todos have a pageId
      var todos = pluginApi.pluginSettings.todos;
      for (var i = 0; i < todos.length; i++) {
        if (todos[i].pageId === undefined) {
          todos[i].pageId = 0;
        }
      }

      pluginApi.saveSettings();
    }
  }

  IpcHandler {
    target: "plugin:todo"

    function togglePanel() {
      pluginApi.withCurrentScreen(screen => {
        pluginApi.togglePanel(screen);
      });
    }

    function addTodo(text: string) {
      if (pluginApi && text) {
        var todos = pluginApi.pluginSettings.todos || [];

        var newTodo = {
          id: Date.now(),
          text: text,
          completed: false,
          createdAt: new Date().toISOString(),
          pageId: 0
        };

        todos.push(newTodo);

        pluginApi.pluginSettings.todos = todos;
        pluginApi.pluginSettings.count = todos.length;
        pluginApi.saveSettings();

        ToastService.showNotice(pluginApi?.tr("main.added_new_todo") + text);
      }
    }

    function toggleTodo(id: int) {
      if (pluginApi && id >= 0) {
        var todos = pluginApi.pluginSettings.todos || [];
        var todoFound = false;

        for (var i = 0; i < todos.length; i++) {
          if (todos[i].id === id) {
            todos[i].completed = !todos[i].completed;
            todoFound = true;
            break;
          }
        }

        if (todoFound) {
          pluginApi.pluginSettings.todos = todos;

          var completedCount = 0;
          for (var j = 0; j < todos.length; j++) {
            if (todos[j].completed) {
              completedCount++;
            }
          }
          pluginApi.pluginSettings.completedCount = completedCount;
          pluginApi.saveSettings();

          var action = todos.find(t => t.id === id).completed ? pluginApi?.tr("main.todo_completed") : pluginApi?.tr("main.todo_marked_incomplete");
          var message = pluginApi?.tr("main.todo_status_changed");
          ToastService.showNotice(message + action);
        } else {
          var message = pluginApi?.tr("main.todo_not_found");
          var endMessage = pluginApi?.tr("main.not_found_suffix");
          ToastService.showError(message + id + endMessage);
        }
      }
    }

    function clearCompleted() {
      if (pluginApi) {
        var todos = pluginApi.pluginSettings.todos || [];
        var activeTodos = todos.filter(todo => !todo.completed);

        pluginApi.pluginSettings.todos = activeTodos;
        pluginApi.pluginSettings.count = activeTodos.length;
        pluginApi.pluginSettings.completedCount = 0;
        pluginApi.saveSettings();

        var clearedCount = todos.length - activeTodos.length;
        var message = pluginApi?.tr("main.cleared_completed_todos");
        var suffix = pluginApi?.tr("main.completed_todos_suffix");
        ToastService.showNotice(message + clearedCount + suffix);
      }
    }

    function removeTodo(id: int) {
      if (pluginApi && id >= 0) {
        var todos = pluginApi.pluginSettings.todos || [];
        var indexToRemove = -1;

        for (var i = 0; i < todos.length; i++) {
          if (todos[i].id === id) {
            indexToRemove = i;
            Logger.i("Todo", "Found todo at index: " + i);
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
          ToastService.showNotice(pluginApi?.tr("main.removed_todo"));
        } else {
          Logger.e("Todo", "Todo with ID " + id + " not found");
          ToastService.showError(pluginApi?.tr("main.todo_not_found") + id + pluginApi?.tr("main.not_found_suffix"));
        }
      } else {
        Logger.e("Todo", "Invalid pluginApi or ID for removeTodo");
      }
    }
  }
}
