# Ansible Role: Workstation

This Ansible role installs the packages and applies the configuration that I want to have present on any system that I use as a workstation. Inasmuch as is reasonable, it attempts to equally support all of the platforms that I use regularly: Ubuntu, Windows (WSL), and Mac OS X.

## Role Usage

TODO

## Playbook

For convenience, this repository/project can also act as a standalone playbook:

1. Bootstrap the system with the minimum prerequisites.
    
    ```
    $ ./bootstrap.sh
    ```
    
2. Generate an SSH key for use (if you're not going to use a preexisting one).
    
    ```
    $ ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
    ```
    
3. Add SSH Key to Keychain.
    
    ```
    $ ssh-add -K ~/.ssh/id_ed25519
    ```
    
    * Be sure to authorize key for GitHub account.
    * Reference: See this to make it persistent on MacOS: <https://apple.stackexchange.com/a/250572>
4. Install the required Ansible roles.
    
    ```
    $ pipenv run ansible-galaxy remove karlmdavis.rcm-dotfiles \
        && pipenv run ansible-galaxy install -r install_roles.yml
    ```
    
5. Provide the required play configuration (fill in placeholders yourself).
    
    ```
    $ cat << EOF > localhost_config.json
    {
      "workstation_config": {
        "user": "<USER>"
      }
    }
    EOF
    ```
    
6. Apply the role via the provided `localhost` playbook:
    
    ```
    $ pipenv run ./ansible-playbook-wrapper localhost_plays.yml --extra-vars "@localhost_config.json"
    ```
    
### Resolving CMS SSL Errors

Some of the above commands (e.g. `ansible-galaxy`) with SSL errors.

TODO
