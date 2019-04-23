#!/bin/bash

# Stop immediately if something fails.
set -e
set -o pipefail

is_macosx() {
  if [[ $(uname) == 'Darwin' ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

# Outputs "true" if the MacOS X Command Line Tools are installed, "false" otherwise.
macosx_cmdline_tools_check() {
  local os=$(sw_vers -productVersion | awk -F. '{print $1 "." $2}')
  if softwareupdate --history | grep --silent "Command Line Tools.*${os}"; then
    echo 'true'
  else
    echo 'false'
  fi
}

# Installs the MacOS X Command Line Tools.
macosx_cmdline_tools_install() {
  # Reference: <https://apple.stackexchange.com/a/325089>
  echo 'TRACE: MacOS X Command Line Tools: installing...'
  os=$(sw_vers -productVersion | awk -F. '{print $1 "." $2}')
  in_progress=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  touch ${in_progress}
  product=$(softwareupdate --list | awk "/\* Command Line.*${os}/ { sub(/^   \* /, \"\"); print }")
  sudo softwareupdate --verbose --install "${product}" || { >&2 echo 'ERROR: Installation failed.'; rm ${in_progress}; exit 1; }
  rm ${in_progress}
  echo 'TRACE: MacOS X Command Line Tools: installed.'
}

# Outputs "true" if the specified Homebrew package is installed, "false" otherwise.
#
# $1: The name of the Homebreqw package to check for.
macos_is_brew_package_installed() {
  if $(brew ls --versions "${1}" &> /dev/null); then
    echo 'true'
  else
    echo 'false'
  fi
}

# Checks to see if the specified Homebrew package is already installed and, if not, installs it.
#
# $1: The name of the Homebrew package to check/install.
macos_brew_ensure_package() {
  if [[ "$(macos_is_brew_package_installed python3)" != 'true' ]]; then
    echo "TRACE: Homebrew:'${1}': installing..."
    brew install "${1}"
    echo "TRACE: Homebrew:'${1}': installed."
  else
    echo "TRACE: Homebrew:'${1}': was already installed."
  fi
}

# Install the bare minimum needed to run this role locally.
# (Remote runs just need a version of Python that Ansible supports.)
macos_bootstrap() {
  # Clean MacOS installs come with Python 2.7, but no `pip`, virtualenv`, etc.
  # To get all of that, the safest option is to install Homebrew.

  # Homebrew (and lots of things) require the MacOS Command Line Tools.
  if [[ "$(macosx_cmdline_tools_check)" != 'true' ]]; then
    macosx_cmdline_tools_install
  else
    echo 'TRACE: MacOS X Command Line Tools: was already installed.'
  fi

  # Install Homebrew if not already present.
  if [[ ! -x "$(which brew)" ]]; then
    echo 'TRACE: Homebrew: installing...'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo 'TRACE: Homebrew: installed.'
  else
    echo 'TRACE: Homebrew: was already installed.'
  fi

  # Install Python 3 (Ansible is slowly moving to this).
  macos_brew_ensure_package 'python@3'
  macos_brew_ensure_package 'pipenv'

  # Create virtual environment, if missing.
  #if [[ ! -d .venv ]]; then
  #  echo 'TRACE: Python virtual environment: creating...'
  #  # Note: This will install the packages in this directory's `Pipfile`.
  #  PIPENV_VENV_IN_PROJECT=1 pipenv install --three
  #  echo 'TRACE: Python virtual environment: created.'
  #else
  #  echo 'TRACE: Python virtual environment: was already present.'
  #fi
}

if [[ $(is_macosx) == "true" ]]; then
  echo "Platform: MacOS X"
  macos_bootstrap

  echo ""
  echo 'Python'"'"'s pipenv now installed and available for use, e.g. `pipenv install --three <PACKAGE_SPEC>`.'
  #echo 'Ansible now installed and available for use via `pipenv run ...`,'
  #echo 'e.g. `pipenv run ansible-playbook --help`.'
else
  >&2 echo "Unsupported platform!"
  exit 1
fi
