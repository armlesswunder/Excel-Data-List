# Excel Data List

Windows and Android app that lets you quickly create checklists/guides for games. 

https://github.com/user-attachments/assets/f30faf0e-7d67-40af-a6c0-89730825f54e

### IMPRORTANT!!!
Make a backup of your sheets before you use them with this app! This app automatically deletes and updates data using its own underlying logic! You may lose valuable data if you use this app with any sheet! 

This app is not designed to create spreadsheets! You need to use a different app to do that.

## How to use
This app uses .xlxs files to display data. Filter data by text with the Searchbar. Tap and hold a cell to edit. The first row of a table is the header.

## Header
A row with special rules that affect all child elements (all elements in the respective column). Headers are always visible even when scrolling the list. Anything in the header name after an underscore _ is not displayed in app. Underscores are used to specifiy special rules for the children. Here are some of the special rules:

# Checkbox (_cb)
All children are checkboxes. Checked items can be filtered in the table settings dropdown (View checked/unchecked/any items)

# Image (_img)
All children are images. Images may be displayed if they exist in your local assets directory or if they are reachable via a url (make sure the url is an image that doesn't require authentication!).

# Move down (_md)
All children are move down buttons. The item is moved to the bottom of the list.

# Save button
Its in the top right corner. It turns red if there are unsaved changes. Always save before you close to avoid data loss.

## More options (right of searchbar)

# Open file
Opens a file using os file select browser

# Select file
Shows a list of files in your device sheets directory to open.

# Shuffle
Shuffles elements 

# Settings
Global and sheet settings. There is info about all settings on the page, so I won't go over the settings here.

# Find in tables
Search all tables in a sheet for text in searchbar

# Progress
Shows how many items are checked off in a list

# Checked Filter
Shows items based on checked status

## Bugs
I am aware that there is an issue with very large files (files with hundreds of thousands of data cells with complicated data) taking a very long time to load. I think the issue is from the underlying package I am using. I recommend that you don't open large files from the internet using this app and instead make your sheets by hand to avoid any unnecessary data 
