#!/bin/bash

SETUP_DIR="$(dirname "$(realpath "$0")")"

install_package() {
  PACKAGE=$1
  if dpkg -l | grep -qw "$PACKAGE"; then
    echo "$PACKAGE is already installed."
  else
    echo "Installing $PACKAGE..."
    sudo apt-get install -y "$PACKAGE" || { echo "Error installing $PACKAGE."; exit 1; }
  fi
}

PACKAGES=("zsh" "git" "curl" "postgresql-12" "google-chrome-stable" "openjdk-11-jdk" "ant" "python3-tqdm")

# Add Google Chrome repo
if ! grep -q "^deb .*dl.google.com/linux/chrome/deb/" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "Añadiendo repositorio de Google Chrome..."
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo tee /usr/share/keyrings/google-chrome-archive-keyring.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/google-chrome-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
  sudo apt-get update
fi

# Node y Npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install packages
for PACKAGE in "${PACKAGES[@]}"; do
  install_package "$PACKAGE"
done

# Add oh-my-zsh
OHMYZSH_DIR="$HOME/.oh-my-zsh"
if [ -d "$OHMYZSH_DIR" ]; then
  echo "skip oh-my-zsh install"
else
  git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  if [ $? -eq 0 ]; then 
    echo "Repositorio clonado correctamente en $CLONE_DIR." 
  else 
    echo "Error al clonar el repositorio. Intenta nuevamente." 
    exit 1
  fi
fi
# Apache
cd "$SETUP_DIR" || exit
tar xf apache-tomcat-9.0.*.tar.gz
sudo mv apache-tomcat-9.0.97 /opt/
cd /opt
sudo ln -s apache-tomcat-9.0.* apache-tomcat-9.0
sudo sh -c 'echo "export CATALINA_OPTS=\"-server -Djava.awt.headless=true -Xms512M -Xmx1024M\"" >> /etc/environment'
sudo sh -c 'echo "export CATALINA_HOME=/opt/apache-tomcat-9.0" >> /etc/environment'
sudo sh -c 'echo "export CATALINA_BASE=/opt/apache-tomcat-9.0" >> /etc/environment'
 
# Eclipse
cd "$SETUP_DIR" || exit
tar xf eclipse-jee-*.tar.gz
sudo mv eclipse /opt/
#cd /opt 
#sudo ln -s eclipse-2024-12 eclipse
cd /usr/local/bin
sudo ln -s /opt/eclipse/eclipse eclipse

# Smartgit
cd "$SETUP_DIR" || exit
tar xf smartgit-linux-19_1_8.tar.gz
sudo mv smartgit /opt/

# CONFIGURATION FILES
CONFIG_FILES=(
  "$SETUP_DIR/eclipse.desktop:$HOME/.local/share/applications/"
  "$SETUP_DIR/smartgit.desktop:$HOME/.local/share/applications/"
)

# Copy configuration files
for FILE_PAIR in "${CONFIG_FILES[@]}"; do
  IFS=':' read -r SRC DEST <<< "$FILE_PAIR"
  if [ -f "$SRC" ]; then
    echo "Copying $SRC a $DEST..."
    sudo cp "$SRC" "$DEST" || { echo "Error copying  $SRC a $DEST."; exit 1; }
  else
    echo "The configuration file does not exist: $SRC"
    exit 1
  fi
done

sudo sh -c 'echo "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/environment'
sudo sh -c 'echo "export ANT_OPTS=\"-Xmx1024M\"" >> /etc/environment'
echo "DONE."
