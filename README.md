# Terminal
[![Translation status](https://l10n.elementary.io/widgets/terminal/-/svg-badge.svg)](https://l10n.elementary.io/projects/terminal/?utm_source=widget)

## The terminal of the 21st century.

A super lightweight, beautiful, and simple terminal. Comes with sane defaults, browser-class tabs, sudo paste protection, smart copy/paste, and little to no configuration.

![Terminal Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* intltool
* libgranite-dev
* libvte-2.91-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/

Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make

To install, use `make install`, then execute with `pantheon-terminal`

    sudo make install
    pantheon-terminal

## Notifications

Terminal implements process completion notifications. They are enabled for BASH automatically. To enable them for ZSH, add the following line to .zshrc:

    builtin . /usr/share/pantheon-terminal/enable-zsh-completion-notifications || builtin true

DISTRIBUTORS: depending on the policy of your distribution, either inform the user about this via the default mechanism for your distribution (for DIY distros like Arch), or add that line to `/etc/zshrc` automatically on installation (for preconfigured distros like Ubuntu).
