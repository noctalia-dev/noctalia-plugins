# Bash Pocket

A Noctalia Shell plugin that allows you to create, edit, and execute custom bash scripts directly from the bar.

## Features

- **Dynamic Pockets**: Create as many script pockets as you need.
- **Quick Access**: Execute scripts with a single click.
- **Built-in Editing**: Edit scripts using your preferred terminal and editor (defaults to `nano`).
- **Management**: Easily delete pockets you no longer need.

## Usage

1.  Click the **+** button to create a new pocket.
2.  The new pocket will automatically open in your terminal for editing.
3.  Write your bash script and save it.
4.  Click the pocket number to execute the script.
5.  Use the **pencil** icon to edit the script again.
6.  Use the **trash** icon to delete the pocket.

## Configuration

Scripts are stored in `~/.config/noctalia/plugins/bash-pocket/pockets/`.
The plugin uses the editor exported as EDITOR environment variable and uses kitty nano as a fallback.
