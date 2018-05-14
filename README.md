# Terminal
[![Packaging status](https://repology.org/badge/tiny-repos/pantheon-terminal.svg)](https://repology.org/metapackage/pantheon-terminal)
[![Translation status](https://l10n.elementary.io/widgets/terminal/-/svg-badge.svg)](https://l10n.elementary.io/projects/terminal/?utm_source=widget)

## The terminal of the 21st century.

A super lightweight, beautiful, and simple terminal. Comes with sane defaults, browser-class tabs, sudo paste protection, smart copy/paste, and little to no configuration.

![Terminal Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libgranite-dev
* libvte-2.91-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja test` to build and run tests

    meson build --prefix=/usr
    ninja test

To install, use `ninja install`, then execute with `io.elementary.terminal`

    sudo ninja install
    io.elementary.terminal

## Notifications

Terminal implements process completion notifications. They are enabled for BASH and FISH automatically. To enable them for ZSH, add the following line to .zshrc:

    builtin . /usr/share/io.elementary.terminal/enable-zsh-completion-notifications || builtin true

DISTRIBUTORS: depending on the policy of your distribution, either inform the user about this via the default mechanism for your distribution (for DIY distros like Arch), or add that line to `/etc/zshrc` automatically on installation (for preconfigured distros like Ubuntu).
