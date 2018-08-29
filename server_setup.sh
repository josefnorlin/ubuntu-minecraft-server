#!/bin/bash
# 

# Change directory to same as script is running in
cd "$(dirname "$0")"
# Adds error handling by exiting at first error
set -e
# Cleans the screen
printf "\033c"
# Set global values
STEPCOUNTER=false # Sets to true if user choose to install Tux Everywhere
OS_VERSION="";
WORLD="$(<config.txt)"
# Here we check if OS is supported
# More info on other OSes regarding plymouth: http://brej.org/blog/?p=158


function choose_world { 
    printf "\033c"
    header "Choose the MINECRAFT WORLD" "$1"

    echo "CURRENT WORLDS (active one in green):"
    echo ""


    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    cd /opt/minecraft
    for d in */ ; do
        if [ "${d%?}" = "$WORLD" ]; then
            printf " ${GREEN}${d%?}${NC}\n"
        else
                echo " ${d%?}"
        fi

    done
    echo ""

    options=("Create new world" "Choose another world" "Delete world" "Quit")
    select opt in "${options[@]}"
    do
       case $opt in
        "Create new world")
            echo "Set a new name for a World"
            echo "What do you want to call it?"
            echo ""
            read new_world
            echo "Creating world $new_world"
            mkdir /opt/minecraft/$new_world
            sudo chown -R minecraft:minecraft /opt/minecraft/$new_world

            echo "Making the new world the active one..."
            echo $new_world > '/opt/minecraft/config.txt'
            systemctl stop "minecraft@$WORLD"
            WORLD="$(<config.txt)"
            update_server
            echo ""
            echo "1) Create new world        3) Delete world"
            echo "2) Choose another world    4) Quit"
            ;;
        "Choose another world")
            printf "\033c"
            header "Choose the MINECRAFT WORLD" "$1"
            echo "Write the name of the world you want to choose."
            echo "OBS! World 'Vanilla' is not the same as world 'vanilla'"
            echo "Big and small letters matter"

            echo ""
            echo "CURRENT WORLDS (active one in green):"
            echo ""
            i=1

            GREEN='\033[0;32m'
            NC='\033[0m' # No Color
            cd /opt/minecraft
            for d in */ ; do
                if [ "${d%?}" = "$WORLD" ]; then
                    printf " ${GREEN}${d%?}${NC}\n"
                else
                    echo " ${d%?}"
                fi

            done
            echo ""
            echo ""
            echo "Enter world to select:"
            read new_world
            didnt_find_it=true
            cd /opt/minecraft
            for d in */ ; do
                if [ "${d%?}" = "$new_world" ]; then
                    echo "Stops active world..."
                    systemctl stop "minecraft@$WORLD"
                    echo "Making '$new_world' the active one..."
                    sudo chown -R minecraft:minecraft /opt/minecraft/$new_world
                    echo $new_world > '/opt/minecraft/config.txt'
                    WORLD="$(<config.txt)"
                    didnt_find_it=false
                    sleep 1
                    echo ""
                    echo "Done. Don't forget to start your server."
                    echo ""
                    read -n1 -r -p "Press any key to continue..." key
                fi
                    
            done
            if [ "$didnt_find_it" = true ]; then
                echo "That world doesn't exist. Sorry. Check the spelling"
                sleep 1
                echo ""
                read -n1 -r -p "Press any key to continue..." key
            fi
            echo "1) Create new world        3) Delete world"
            echo "2) Choose another world    4) Quit" 
            ;;
        "Delete world")
            printf "\033c"
            header "Choose the MINECRAFT WORLD" "$1"
            RED='\033[0;31m'
            NC='\033[0m' # No Color

            printf "Write the name of the world you want to ${RED}DELETE${NC}.\n"
            echo "OBS! There is no going back, once deleted its gone."
            echo ""
            echo "CURRENT WORLDS (active one in green):"
            echo ""
            i=1

            GREEN='\033[0;32m'
            NC='\033[0m' # No Color
            cd /opt/minecraft
            for d in */ ; do
                if [ "${d%?}" = "$WORLD" ]; then
                    printf " ${GREEN}${d%?}${NC}\n"
                else
                        echo " ${d%?}"
                fi

            done
            echo ""
            echo "Enter world to delete:"
            read new_world
            didnt_find_it=true
            cd /opt/minecraft
            for d in */ ; do
                if [ "${d%?}" = "$new_world" ]; then
                    if [ "$WORLD" = "$new_world" ]; then
                        echo "Can't delete an active world... Change active world and try again."
                        echo ""
                        read -n1 -r -p "Press any key to continue..." key
                        didnt_find_it=false
                    else
                        echo "Deleting '$new_world'..."
                        sudo rm -r /opt/minecraft/$new_world
                        
                        echo ""
                        echo "Done. Don't forget to start your server."
                        echo ""
                        read -n1 -r -p "Press any key to continue..." key
                        didnt_find_it=false
                    fi
                fi
                    
            done
            if [ "$didnt_find_it" = true ]; then
                echo "That world doesn't exist. Sorry. Check the spelling"
                sleep 1
                echo ""
                read -n1 -r -p "Press any key to continue..." key
            fi
            echo "1) Create new world        3) Delete world"
            echo "2) Choose another world    4) Quit"         
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
       esac
    done

}

function start_server { 
    printf "\033c"
    header "Starting the MINECRAFT SERVER" "$1"

    echo "Starting server world '$WORLD'"
    systemctl start "minecraft@$WORLD"
    sleep 3
    echo "Done. Wait some seconds for it to load before connecting."
    echo ""
    read -n1 -r -p "Press any key to continue..." key
}

function stop_server { 
    printf "\033c"
    header "Stopping the MINECRAFT SERVER" "$1"
    echo "Stopping server world '$WORLD'"
    systemctl stop "minecraft@$WORLD"
    sleep 3
    echo "Server stopped."
    echo ""
    read -n1 -r -p "Press any key to continue..." key
}


function update_server { 
    printf "\033c"
    header "Updating the MINECRAFT SERVER" "$1"

    if ! hash java 2>/dev/null; then
        check_sudo
        sudo apt-add-repository ppa:webupd8team/java
        sudo apt-get update
        sudo apt-get install oracle-java8-installer
    fi
    echo "Active server world to update is '$WORLD'"
    echo "Stops server if active..."
    sleep 3
    systemctl stop "minecraft@$WORLD"
    echo "Stopped."

    # Create the minecraft directory to store server files and change into the directory
    mkdir -p /opt/minecraft/$WORLD
    cd /opt/minecraft/$WORLD

    # Ask which minecraft version to download
    echo "Which version of minecraft server do you want to install? e.g. 1.11.2"
    read VER

    echo "Downloading minecraft server version $VER..."

    # wget --progress=bar:force "https://s3.amazonaws.com/Minecraft.Download/versions/$VER/minecraft_server.$VER.jar" 2>&1 | progressfilt
    sudo wget --show-progress "https://s3.amazonaws.com/Minecraft.Download/versions/$VER/minecraft_server.$VER.jar" -O minecraft_server.jar

    # If server creates a eula.txt file, update the value false to true
    echo 'eula=true' | sudo tee -a "/opt/minecraft/$WORLD/eula.txt" > /dev/null
    echo "Done. You have now downloaded server version $VER to Minecraft World '$WORLD'"
    echo ""
    echo "Don't forget to start your the Minecraft server."
    echo ""
    read -n1 -r -p "Press any key to continue..." key
}

function config_server { 
    printf "\033c"
    header "Loads the config file of the MINECRAFT SERVER" "$1"

    echo "Do you want to open the server.properties for your Minecraft server World?"

    select yn in "Yes" "No"; do
        case $yn in
            Yes ) 
                sudo gedit /opt/minecraft/$WORLD/server.properties
                break;;
            No ) 
                echo "Okay :)"
                break;;
        esac
    done
    

    echo ""
    read -n1 -r -p "Press any key to continue..." key
}

function autostart_server { 
    printf "\033c"
    header "Autostarts the MINECRAFT SERVER" "$1"

    echo "Do you want to autostart the Minecraft server?"

    select yn in "Yes" "No"; do
        case $yn in
            Yes ) 
                echo "Ahh, the server will now run everytime you start ut!"
                systemctl enable "minecraft@$WORLD"
               	# We set the plymouth directory here 
                plymouth_dir="/usr/share/plymouth"
                break;;
            No ) 
                echo "Server will not run on boot, must be started manually."
                systemctl disable "minecraft@$WORLD"
                break;;
        esac
    done
    

    echo ""
    read -n1 -r -p "Press any key to continue..." key
}


function install_games {
    printf "\033c"
    header "Adding Tux GAMES" "$1"
    echo "This will install the following classic Tux games:"
    echo "  - SuperTux                          (A lot like Super Mario)"
    echo "  - SuperTuxKart                      (A lot like Mario Kart)"
    echo "  - Extreme Tux Racer                 (Help Tux slide down slopes)"
    echo "  - FreedroidRPG                      (Sci-fi isometric role playing)"
    echo "  - WarMUX                            (A lot like Worms)"
    echo ""
    check_sudo
    echo "Ready to try some gaming with The Tux!?"
    echo ""
    echo "(Type 1 or 2, then press ENTER)"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) 
                printf "\033c"
                header "Adding Tux GAMES" "$1"
                echo "Initiating Tux Games install..."
                install_if_not_found "supertux supertuxkart extremetuxracer freedroidrpg warmux"
                echo "Successfully installed the Tux Games."
                break;;
            No ) printf "\033c"
                header "Adding Tux GAMES" "$1"
                echo "The sound of Tux flapping with his feets slowly turns silent when he realizes" 
                echo "your response... He shrugs and answer with a lowly voice 'ok'."
                break;;
        esac
    done
    echo ""
    read -n1 -r -p "Press any key to continue..." key
}


function check_sudo {
    if sudo -n true 2>/dev/null; then 
        :
    else
        echo "Oh, and Tux will need sudo rights to copy and install everything, so he'll ask" 
        echo "about that soon."
        echo ""
    fi
}

function install_if_not_found { 
    # As found here: http://askubuntu.com/questions/319307/reliably-check-if-a-package-is-installed-or-not
    for pkg in $1; do
        if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
            echo -e "$pkg is already installed"
        else
            echo "Installing $pkg."
            if sudo apt-get -qq --allow-unauthenticated install $pkg; then
                echo "Successfully installed $pkg"
            else
                echo "Error installing $pkg"
            fi        
        fi
    done
}

function uninstall_if_found { 
    # As found here: http://askubuntu.com/questions/319307/reliably-check-if-a-package-is-installed-or-not
    for pkg in $1; do
        if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
            echo "Uninstalling $pkg."
            if sudo apt-get remove $pkg; then
                echo "Successfully uninstalled $pkg"
            else
                echo "Error uninstalling $pkg"
            fi        
        else
            echo -e "$pkg is not installed"
        fi
    done
}


function header {
    var_size=${#1}
    # 80 is a full width set by us (to work in the smallest standard terminal window)
    if [ $STEPCOUNTER = false ]; then
        # 80 - 2 - 1 = 77 to allow space for side lines and the first space after border.
        len=$(expr 77 - $var_size)
    else   
        # "Step X/X " is 9
        # 80 - 2 - 1 - 9 = 68 to allow space for side lines and the first space after border.
        len=$(expr 68 - $var_size)
    fi
    ch=' '
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    printf "║"
    printf " $1"
    printf '%*s' "$len" | tr ' ' "$ch"
    if [ $STEPCOUNTER = true ]; then
        printf "Step "$2
        printf "/7 "
    fi
    printf "║\n"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
}

while :
do
    clear
    # Menu system as found here: http://stackoverflow.com/questions/20224862/bash-script-always-show-menu-after-loop-execution
    cat<<EOF    
╔══════════════════════════════════════════════════════════════════════════════╗
║ MINECRAFT SERVER SCRIPT ver 1.0                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   What do you want to do today? (Type in one of the following numbers)       ║
║                                                                              ║
║   0) Choose Minecraft World       	         - Set the world to play in    ║
║   ------------------------------------------------------------------------   ║
║   1) Start server                              - Using chosen World          ║
║   2) Stop server                               - Stop active server          ║
║   ------------------------------------------------------------------------   ║
║   3) Install/update server                     - Update chosen world version ║
║   4) Configure server                          - Open server.properties      ║
║   5) Autostart server                          - Toggle autostart on/off     ║
║   ------------------------------------------------------------------------   ║
║   G) Install other games                       - Great free Linux games      ║
║   ------------------------------------------------------------------------   ║
║   Q) I'm done                                  - Quit the installer (Ctrl+C) ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    read -n1 -s
    case "$REPLY" in
    "0")    choose_world ;;
    "1")    start_server ;;
    "2")    stop_server ;;
    "3")    update_server ;;
    "4")    config_server ;;
    "5")    autostart_server ;;
    "G")    install_games ;;
    "g")    install_games ;;
    "Q")    exit ;;
    "q")    exit ;;
     * )    echo "That's an invalid option. Try again." ;;
    esac
    sleep 1
done
