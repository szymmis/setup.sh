#!/bin/bash

###########################################
##### OHMYZSH CONFIGURATION CONSTANTS
###########################################

PLUGINS=("https://github.com/lukechilds/zsh-nvm.git" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "https://github.com/zsh-users/zsh-autosuggestions.git")
THEME="https://github.com/romkatv/powerlevel10k.git"
ALIASES=("code='code-insiders'" "zshrc='nano ~/.zshrc'")

###########################################
##### FORMATTING CONSTANTS
###########################################
PLAIN='\033[0m'
BOLD='\033[1m'

WHITE='\033[29m'
GREEN='\033[32m'
BLUE='\033[33m'
RED='\033[31m'

###########################################
##### FUNCTION DEFINITIONS
###########################################
fecho(){
    echo -e "${BOLD}${2:-$WHITE}$1${PLAIN}"
}

clear_line(){
    echo -ne "\033[0K"
}

progress(){
    if [ "$3" ]; then
        echo -en "\033[0K$3 ["
    else
        echo -en "\033[0K["
    fi
    for x in $(seq $1); do
        echo -ne "="
    done
    if [ ! $1 = $2 ]; then
        echo -ne ">"
    fi
    for x in $(seq $(($2-$1-1))); do
        echo -ne "."
    done

    echo -n "] "
    printf "${BOLD}(%4s)${PLAIN}" "$((100*$1/$2))%"

    if [ $1 = $2 ]; then
        echo -ne "\n"
    else
        echo -ne "\r"
    fi
}

install_package(){
    if [ ! `command -v $1` ]; then
        fecho "Installing $1..."
        sudo apt install $1
        if [ $? -eq 0 ]; then
            fecho "$1 has been succesfully installed!" $GREEN
        else
            fecho "$1 couldn't be installed!" $RED
        fi
    else
        echo `fecho $1 $RED` "already installed!"
    fi
}

install_snap_package(){
    if [ ! `command -v ${2:-$1}` ]; then
        fecho "Installing ${2:-$1}..."
        sudo snap install $1
        if [ $? -eq 0 ]; then
            fecho "${2:-$1} has been succesfully installed!" $GREEN
        else
            fecho "${2:-$1} couldn't be installed!" $RED
        fi
    else
        echo "`fecho ${2:-$1} $RED` already installed!"
    fi
}

fetch_plugins(){
    echo "Fetching" `fecho "Oh my ZSH"` "plugins..."

    #Fetch all plugins defined in $PLUGINS array
    for ((i = 0; i < ${#PLUGINS[@]}; i++)); do
        plugin=${PLUGINS[$i]}
        name=`echo $plugin | sed -E 's/.*\/([a-z0-9\-]+).git/\1/g'`
        progress $i ${#PLUGINS[@]} "Cloning `fecho "$name"`"
        git clone "$plugin" ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/${name} &> /dev/null
    done
    progress ${#PLUGINS[@]} ${#PLUGINS[@]} "Fetching plugins `fecho "DONE!" $GREEN`"

    #Fetch theme defined in $THEME constant
    name=`echo $THEME | sed -E 's/.*\/([a-z0-9\-]+).git/\1/g'`
    echo -ne "Cloning" `fecho "$name"` "theme\r"
    git clone "$THEME" ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/${name} &> /dev/null
    #Append plugins list into the .zshrc config
    plugins_list=`ls ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins | tr '\n' ' '`
    sed -i "s/^plugins=.*$/plugins=(git $plugins_list)/g" ~/.zshrc
    #Append theme name into the .zshrc config
    sed -i "s/robbyrussell/$name\/$name/g" ~/.zshrc

    clear_line
    echo "`fecho "$name" $GREEN` theme cloned!"
}

setup_aliases(){
    for ((i = 0; i < ${#ALIASES[@]}; i++)); do
        custom_alias="${ALIASES[$i]}"
        if [ $(grep "alias $custom_alias" ~/.zshrc -c) -eq 0 ]; then
            echo "alias $custom_alias" >> ~/.zshrc
            if [ $? -eq 0 ]; then
                echo "Defined `fecho "$custom_alias" $GREEN` alias"
            else
                echo "Couldn't define `fecho "$custom_alias" $RED` alias"
            fi
        fi
    done
}

authenticate_github(){
    #Install Github CLI in order to add ssh-key to account
    if [ ! `command -v "gh"` ]; then
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
        sudo apt-add-repository https://cli.github.com/packages
        sudo apt update
        install_package gh
    else
        echo "`fecho gh $RED` already installed!"
    fi

    #Generate ssh-key
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        mkdir ~/.ssh
        ssh-keygen -f ~/.ssh/id_rsa -P ""
        eval "$(ssh-agent -s)"
        echo "Generated ssh key!" `fecho "~/.ssh/id_rsa.pub" $GREEN`
    else
        echo `fecho "~/.ssh/id_rsa.pub" $RED` "already exists!"
    fi

    #Try to add ssh-key to account using Github CLI
    if [ $(echo "$(gh ssh-key list)" | grep -c "$USER@$NAME") -eq 0 ]; then
        gh auth login -s admin:public_key -h github.com -w
        gh ssh-key add ~/.ssh/id_rsa.pub -t "$USER@$NAME"
    else
        echo `fecho "$USER@$NAME" $RED` "ssh-key record already exists!"
    fi
}

###########################################
##### SCRIPT BODY
###########################################

echo "--------------------------"
fecho "sudoers"
echo "-------------"

#Add sudoers entry to make passing password to sudo obsolete
SUDOERS_ENTRY="$USER ALL=(ALL) NOPASSWD:ALL"
if [ $(sudo grep "^$SUDOERS_ENTRY$" -c /etc/sudoers) -eq 0 ]; then
    echo $SUDOERS_ENTRY | sudo EDITOR="tee -a" visudo &> /dev/null
    echo `fecho $USER $GREEN` "entry added to sudoers!"
else
    echo `fecho /etc/sudoers $RED` "entry already exists!"
fi

echo "--------------------------"
fecho 'git'
echo "-------------"

install_package "git"

if [ ! -f ~/.gitconfig ] || [ $(grep email ~/.gitconfig  -c) -eq 0 ] || [ $(grep name ~/.gitconfig  -c) -eq 0 ]; then
    read -n1 -p "Do you want to set git global account's identity? `fecho [y/n]:` " prompt
    echo -ne "\n"

    case $prompt in
        y|Y) read -p "`fecho "user.email: "`" email
            read -p "`fecho "user.name: "`" name
            git config --global user.email "$email"
            git config --global user.name "$name"
            fecho "Git account's identity set!" $GREEN;;
        *) fecho "Git account's identity setting aborted!" $RED;;
    esac
else
	echo `fecho "Git account's identity" $RED` "already set up!"
fi

echo "--------------------------"
fecho 'zsh'
echo "-------------"

install_package "zsh"

#Change default shell to ZSH
if [ $(echo $SHELL | grep "zsh" -c) -eq 0 ]; then
    sudo chsh -s $(which zsh) $(whoami) > /dev/null
    if [ $? -eq 0 ]; then
        echo "Default shell changed to" `fecho "ZSH!" $GREEN`
    else
        echo "Couldn't change default shell to" `fecho "ZSH!" $RED`
    fi
else
    echo `fecho "zsh" $RED` "is already your default shell!"
fi

echo "--------------------------"
fecho "Oh my ZSH!"
echo "-------------"

if [ ! -d ~/.oh-my-zsh ]; then
	read -n1 -p "Do you want to install Oh my ZSH? `fecho [y/n]:` " prompt
	echo -ne "\n"

	case $prompt in
	    y|Y) fecho "Installing Oh my ZSH!..." $GREEN
	    if [ ! -d ~/.oh-my-zsh ]; then
	        sh -c "$(wget -O- -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &> /dev/null
	        echo `fecho "Oh my ZSH" $GREEN` "has been installed!"

	        #Fetch and install all plugins defined in 'PLUGINS' array
	        fetch_plugins
	        #Setup all aliases defined in 'ALIASES' array
	        setup_aliases

	        echo `fecho "Oh my ZSH" $GREEN` "has been configured succesfully!"
	    fi;;
	    *) fecho "Oh my ZSH! installation aborted!" $RED;;
	esac
else
	echo `fecho "Oh my ZSH" $RED` "already installed!"
fi

echo "--------------------------"
fecho "FiraCode font"
echo "-------------"

if [ $(ls /usr/share/fonts | grep FiraCode -c) -eq 0 ]; then
    read -n1 -p "Do you want to install FiraCode font? `fecho [y/n]:` " prompt
    echo -ne "\n"

    case $prompt in
        y|Y) fecho "Installing FiraCode font..." $GREEN
            wget -q "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip" -O "font.zip"
            unzip "font.zip" -d "font" &> /dev/null
            sudo cp font/ttf/* /usr/share/fonts
            if [ $? -eq 0 ]; then
                echo "`fecho FiraCode $GREEN` installed successfully"
            else
                echo "Couldn't install `fecho FiraCode $RED`"
            fi
            rm -rf font*;;
        *) fecho "Font installation aborted!" $RED;;
    esac
else
	echo `fecho "FiraCode" $RED` "already installed!"
fi

echo "--------------------------"
fecho 'snap apps'
echo "-------------"

read -n1 -p "Do you want to install snap apps? `fecho [y/n]:` " prompt
echo -ne "\n"

case $prompt in
    y|Y) fecho "Installing snap apps..." $GREEN
        install_snap_package "code-insiders --classic" "code-insiders"
        install_snap_package "spotify"
        install_snap_package "slack --classic" "slack"
        install_snap_package "postman";;
    *) fecho "Snap installation aborted!" $RED;;
esac

echo "--------------------------"
fecho 'GitHub CLI, ssh-key'
echo "-------------"

if [ ! -f ~/.ssh/known_hosts ]; then
    read -n1 -p "Do you want to authenticate with GitHub? `fecho [y/n]:` " prompt
    echo -ne "\n"

    case $prompt in
        y|Y) fecho "Authenticating with GitHub..." $GREEN
        authenticate_github;;
        *) fecho "GitHub authentication aborted!" $RED;;
    esac
else
	echo "Already authenticated with `fecho "GitHub" $RED`!"
fi
