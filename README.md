# Plugins for Nim Website Creator (NimWC)

Plugin repository for [Nim Website Creator](https://github.com/ThomasTJdev/nim_websitecreator).





# Plugins

## Plugin repo

To update the available plugins go to `<webpage>/plugins/repo`. NimWC will clone this repo to ensure, that the latest available plugins are shown.

## Enable/disable a plugin

To enable or disable a plugin go to `<webpage>/plugins`. Only plugins installed at `<webpage>/plugins/repo` will be available.

Plugins are loaded at compile time with macros, therefore it can take up to ~60 seconds to enable or disable a plugin. The interface will notify you, when the plugin is installed.

## Contribute

To make a plugin public accessible, you need to add it to the `plugins.json` in this [plugin repo](https://github.com/ThomasTJdev/nimwc_plugins).

Make a pull request where you have added your plugin data to the **bottom** of `plugins.json`.

When you release a new version of your plugin, you need to increase the version in your own plugin repo file `plugin.json` and in this repos file `plugins.json`. Otherwise the users will not notice, that your have released a new version.


# Available plugins

## Plugin: Backup

Create an instant backup file. Schedule continuously backups. Download backups.

You can access the plugin at `/backup`.


## Plugin: Contact

A simple contact form for non-logged in users. The email will be sent to the info address specified in the `config.cfg` file.

You can access the plugin at `/contact`. This link can be added to the navbar manually.


## Plugin: Mailer

Add mail elements containing subject, description and a date for sending the mail. Every 12th hour a cronjob will run to check, if it is time to send the mail.

All registered users will receive the email.

You can access the plugin at `/mailer`. This link can be added to the navbar manually.


## Plugin: Open registration

Anyone can register an account and get a user with user role "User".  You can access the plugin at `/register`. An email with an activation link will be sent to users.


## Plugin: Templates

Load predefined templates (database data, css, js and images) or save your current design to a template, which you can share.

You can access the plugin at `/templates/settings`.

## Plugin: Themes

Switch between themes. Save custom themes from the browser.

You can access the plugin at `/themes/settings`.


# Plugin structure

A plugin needs the following structure:

```
templates/
  - html.tmpl   (optional)
  - templates.nim  (required)
  - routes.nim  (required)
  - plugin.json (required)
  - public/
    - js.js             (required) <- Will be appended to all pages
    - style.css         (required) <- Will be appended to all pages
    - js_private.js     (required) <- Needs to be imported manually
    - style_private.css (required) <- Needs to be imported manually
```

## plugin.json
This file contains information about the plugin.

The file needs this formatting:
```JSON
[
  {
    "name": "Templates",
    "foldername": "templates",
    "version": "0.1",
    "requires": "5.0",
    "url": "https://github.com/ThomasTJdev/nimwc_templates.git",
    "method": "git",
    "tags": [
      "templates"
    ],
    "description": "Full templates. Includes database, css, js and other public files.",
    "license": "MIT",
    "web": "https://github.com/ThomasTJdev/nimwc_templates",
    "sustainability": "",
    "email": "user@example.com"
  }
]
```


# JSON Fields Description

- `"name"` Plugin Name, Human Readable, string type, no empty string, no trailing whitespaces.
- `"foldername"` Folder Name, Human Readable, string type, no empty string, no trailing whitespaces.
- `"version"` Plugin Version as a Float, Human Readable, string type, no empty string, no trailing whitespaces.
- `"requires"` Minimum NimWc Version as a Float, `>= 5.0`, Human Readable, string type, no empty string, no trailing whitespaces.
- `"url"` Git clone URL, HTTPS preferred, must be OnLine, Human Readable, string type, no empty string, no trailing whitespaces.
- `"method"` Must be `"git"`
- `"tags"` Plugin Tags, Human Readable, Array of strings, no empty Array, no empty strings, no trailing whitespaces, will be used to display Rendered Tag cloud on Plugin Store, 10 Tags max.
- `"description"` Plugin Description, Human Readable, string type, can be MarkDown/ResTructuredText/Plain Text, will be used to display Rendered HTML on Plugin Store, no empty string, no trailing whitespaces.
- `"license"` Plugin License, Human Readable, string type, no empty string, no trailing whitespaces.
- `"web"` Plugin Web home page, HTTPS preferred, must be OnLine, Human Readable, string type, no empty string, no trailing whitespaces.
- `"email"` Plugin Authors EMail, Human Readable, string type, will be used to display Libravatar/Gravatar on Plugin Store, you can use it to display your Logo of your Freelancing/Cooperative on Plugin Store, can be empty string, no trailing whitespaces.
- `"sustainability"` Plugin Authors way to Self-Sustainable Development, eg Patreon, Liberapay, Bitcoin Address, etc, will be used to display on Plugin Store, string type, can be empty string, no trailing whitespaces. We would love to make Open Source Self-Sustainable, will you help us?.


## templates.nim
Includes the plugins proc()'s etc.

It is required to include a proc named `proc <pluginname>Start*(db: DbConn) =`

For the templates plugin this would be: `proc templatesStart*(db: DbConn) =` . If this proc is not needed, just `discard` the content.


## routes.nim
Includes the URL routes.

It is required to include a route with `/<pluginname>/settings`. This page should show information about the plugin and any options which can be changed.


## *.js and *.css

At compile time `js.js`, `js_private.js`, `style.css` and `style_private.css` are copied from the plugins public folder to the official public folder, if the files contains text.

### JS files
The files will be renamed to `templates.js` and `templates_private.js`

### CSS files
The files will be renamed to `templates.css` and `templates_private.css`.

### Importing

A `<link>` and/or a `<script>` tag to `templates.css`/`templates.js` will be appended to the all pages, if `js.js` or `style.css` contains text.

The `*_private` files needs to be included manually.


# JSON Checker

- This repo includes a JSON Checker for consistency.
- All JSON keys and values are checked.
- Compile with SSL `-d:ssl` to check On-Line using Internet, optional.

```
$ nim c -r -d:ssl check_json.nim

[Suite] Packages consistency testing
  [OK] Check Basic Structure
  [OK] Check Tags
  [OK] Check Methods
  [OK] Check Licenses
  [OK] Check Names
  [OK] Check Versions
  [OK] Check Requires
  [OK] Check Foldernames
  [OK] Check Webs Off-Line
D, [2019-03-06T16:12:32] -- check_json: https://github.com/thomastjdev/nimwc_backup
D, [2019-03-06T16:12:33] -- check_json: https://github.com/thomastjdev/nimwc_contact
D, [2019-03-06T16:12:34] -- check_json: https://github.com/thomastjdev/nimwc_mailer
D, [2019-03-06T16:12:35] -- check_json: https://github.com/thomastjdev/nimwc_openregistration
D, [2019-03-06T16:12:35] -- check_json: https://github.com/thomastjdev/nimwc_templates
D, [2019-03-06T16:12:36] -- check_json: https://github.com/thomastjdev/nimwc_themes
  [OK] Check Webs On-Line
  [OK] Check Sustainability On-Line
  [OK] Check URLs Off-Line
D, [2019-03-06T16:12:36] -- check_json: https://github.com/thomastjdev/nimwc_backup.git
D, [2019-03-06T16:12:37] -- check_json: https://github.com/thomastjdev/nimwc_backup.git
D, [2019-03-06T16:12:38] -- check_json: https://github.com/thomastjdev/nimwc_contact.git
D, [2019-03-06T16:12:38] -- check_json: https://github.com/thomastjdev/nimwc_contact.git
D, [2019-03-06T16:12:39] -- check_json: https://github.com/thomastjdev/nimwc_mailer.git
D, [2019-03-06T16:12:40] -- check_json: https://github.com/thomastjdev/nimwc_mailer.git
D, [2019-03-06T16:12:40] -- check_json: https://github.com/thomastjdev/nimwc_openregistration.git
D, [2019-03-06T16:12:41] -- check_json: https://github.com/thomastjdev/nimwc_openregistration.git
D, [2019-03-06T16:12:42] -- check_json: https://github.com/thomastjdev/nimwc_templates.git
D, [2019-03-06T16:12:43] -- check_json: https://github.com/thomastjdev/nimwc_templates.git
D, [2019-03-06T16:12:44] -- check_json: https://github.com/thomastjdev/nimwc_themes.git
D, [2019-03-06T16:12:44] -- check_json: https://github.com/thomastjdev/nimwc_themes.git
  [OK] Check URLs On-Line

$
```
