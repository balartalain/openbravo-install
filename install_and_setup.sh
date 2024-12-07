#!/bin/bash

SETUP_DIR="$(dirname "$(realpath "$0")")"

install_package() {
  PACKAGE=$1
  if dpkg -l | grep -qw "$PACKAGE"; then
    echo "--$PACKAGE is already installed."
  else
    echo "################ Installing $PACKAGE...##################"
    sudo apt-get install -y "$PACKAGE" || { echo "Error installing $PACKAGE."; exit 1; }
  fi
}

PACKAGES=("zsh" "git" "curl" "nodejs" "npm" "postgresql-12" "postgresql-client-12"  "openjdk-11-jdk" "ant" "google-chrome-stable" "python3-tqdm")

# Add Google Chrome repo
if ! grep -q "^deb .*dl.google.com/linux/chrome/deb/" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
   wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmour -o /usr/share/keyrings/chrome-keyring.gpg 
   sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list' 
#  echo "Añadiendo repositorio de Google Chrome..."
#  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo tee /usr/share/keyrings/google-chrome-archive-keyring.gpg > /dev/null
#  echo "deb [signed-by=/usr/share/keyrings/google-chrome-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
#  sudo apt-get update
fi

# Node y Npm
PACKAGE="curl"
if ! dpkg -l | grep -qw "$PACKAGE"; then
 curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
fi
# Postgres
PACKAGE="postgresql"
if ! dpkg -l | grep -qw "$PACKAGE"; then
 curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
 #sudo sh -c 'curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null'
 echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
 #sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
fi

# Update package
sudo apt update

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
EXISTE=$(ls /opt | grep -i apache)
if ![ -z "$EXISTE" ]; then
 cd "$SETUP_DIR" || exit
 tar xf apache-tomcat-9.0.*.tar.gz
 sudo mv apache-tomcat-9.0.97 /opt/
 cd /opt
 sudo ln -s apache-tomcat-9.0.* apache-tomcat-9.0
 sudo sh -c 'echo "export CATALINA_OPTS=\"-server -Djava.awt.headless=true -Xms512M -Xmx1024M\"" >> /etc/environment'
 sudo sh -c 'echo "export CATALINA_HOME=/opt/apache-tomcat-9.0" >> /etc/environment'
 sudo sh -c 'echo "export CATALINA_BASE=/opt/apache-tomcat-9.0" >> /etc/environment'
fi

# Eclipse
EXISTE=$(ls /opt | grep -i eclipse)
if ![ -z "$EXISTE" ]; then
  cd "$SETUP_DIR" || exit
  tar xf eclipse-jee-*.tar.gz
  sudo mv eclipse /opt/
  cd /usr/local/bin
  sudo ln -s /opt/eclipse/eclipse eclipse
  sudo sh -c 'echo "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/environment'
  sudo sh -c 'echo "export ANT_OPTS=\"-Xmx1024M\"" >> /etc/environment'
fi

# Smartgit
EXISTE=$(ls /opt | grep -i smartgit)
if ![ -z "$EXISTE" ]; then
  cd "$SETUP_DIR" || exit
  tar xf smartgit-linux-19_1_8.tar.gz
  sudo mv smartgit /opt/
fi

# Postgres config
sudo -u postgres psql -c "alter user postgres with password 'postgres';"

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

echo "DONE."
