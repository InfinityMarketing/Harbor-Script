#! /bin/bash

########################################
#                Harbor                #
#   Theme Development Setup Script     #
#             Mark Bixler              #
#      Uses Harbor starter theme       #
#        by Infinity Marketing         #
########################################

error=false
interactive=true

function usage() {
  echo "usage: harbor <action> [options]"
  echo "  Actions:"
  echo "   install:"
  echo "      download the Harbor starter theme, and get it set up for development."
  echo "      -s, --script                    install harbor script on system (installs to '/usr/local/bin/')"
  echo "   update:"
  echo "        check the the installed packages with Bower and list out the ones with updates."
  echo "      -i, --interactive (default)     ask user before updating a package."
  echo "      -a, --auto                      automatically update every package with updates available"
  echo "  -h, --help:"
  echo "        Display this help and exit"
  exit 1
}

if [ "$2" != "-s" ] && [ "$2" != "--script" ]; then
  command -v harbor >/dev/null 2>&1 || {
    echo "Would you like to install this script to your bin direcetory to make it runnable from any directory(Y/n)?"
    read inst
    if [ "$inst" == "" ] || [ "${inst:0:1}" == "y" ]; then
      echo "Installing script..."
      sudo cp ./harbor.sh /usr/local/bin/harbor
    fi
  }
fi

if [ "$#" -lt 1 ]; then
  usage
fi

if [ "$1" == "-h" ] || [ "$1" == '--help' ] || [ "$2" == "-h" ] || [ "$2" == '--help' ]; then
  usage
fi

if [ "$1" == "install" ]; then

  if [ "$2" == "-s" ]  || [ "$2" == "--script" ]; then
    echo "Installing script..."
    sudo cp ./harbor.sh /usr/local/bin/harbor
    exit 0
  fi

  # Verify dependent programs are installed
  command -v unzip >/dev/null 2>&1 || {
    echo >&2 "Error: unzip required. Please install before proceding.";
    error=true;
  }

  command -v awk >/dev/null 2>&1 || {
    echo >&2 "Error: awk required. Please install before proceding.";
    echo ">   Aborting.";
    error=true;
  }

  command -v sed >/dev/null 2>&1 || {
    echo >&2 "Error: sed required. Please install before proceding.";
    echo ">   Aborting.";
    error=true;
  }

  if [ $error = true ]; then
    echo ">   Errors reported. Aborting";
    exit 1;
  fi

  # Download _s starter theme from github
  rm sass-restructure.zip
  echo "Downloading theme files..."
  wget -a setup.log "https://github.com/Infinity-Marketing/Harbor/archive/sass-restructure.zip"

  # Get a name for the theme and generate a slug
  echo 'Enter theme name '
  read name
  slug=`echo $name | awk '{print tolower($0)}' | sed -e 's/ /-/g'`
  functionSlug=`echo $name | awk '{print tolower($0)}' | sed -e 's/ /_/g'`
  docBlocks=`echo $name | sed -e 's/ /_/g'`
  # Extract theme files and rename root theme folder
  echo "Extracting theme files..."
  unzip sass-restructure.zip >> setup.log
  mv ./Harbor-sass-restructure "./$slug"

  #replace all _s with user supplied name slug
  echo "Enter a short description for your theme."
  read desc
  echo "Customizing Theme..."
  sed -i -e "s/'harbor'/'$slug'/g" ./$slug/*.php
  sed -i -e "s/'harbor'/'$slug'/g" ./$slug/*/*.php

  sed -i -e "s/harbor_/$functionSlug\_/g" ./$slug/*.php
  sed -i -e "s/harbor_/$functionSlug\_/g" ./$slug/*/*.php

  sed -i -e "s/Text Domain: harbor/Text Domain: $slug/g" ./$slug/style.css

  sed -i -e "s/ <code>&nbsp;Harbor<\/code>/ <code>&nbsp;$docBlocks<\/code>/g" ./$slug/*.php
  sed -i -e "s/ <code>&nbsp;Harbor<\/code>/ <code>&nbsp;$docBlocks<\/code>/g" ./$slug/*/*.php

  sed -i -e "s/harbor-/$slug-/g" ./$slug/*.php
  sed -i -e "s/harbor-/$slug-/g" ./$slug/*/*.php

  sed -i -e "s/Theme Name: Harbor/Theme Name: $name/g" "./$slug/style.css"

  sed -i -e "s/Description: Harbor is a starter theme and development environment setup by Infinity Marketing that is heavily based on Automattic's Underscores theme./Description: $desc/g" "./$slug/style.css"

  echo "Done!"

  #set up NodeJs Grunt and Bower for task and package management
  echo "Setting up environment..."
  echo "Enter local development URL"
  read devUrl
  echo "Please wait. This could take a few minutes."
  cd $slug

  sed -i -e "s/target: \"localhost/harbor\"/target: \"$devUrl\"/g" ./$slug/gulpfile.js

  command -v npm >/dev/null 2>&1 || {
    echo >&2 "Error: NodeJs not installed. Exiting environment setup.";
    exit 1
  }
  command -v bower >/dev/null 2>&1 || {
    echo >&2 "Notice: Bower not installed. installing now";
    sudo npm install -g bower >> ../setup.log
  }

  bower install >> ../setup.log --allow-root
  sudo npm install >> ../setup.log

  echo "Removing leftover files..."
  rm ./*.php-e
  rm ./*/*.php-e
  rm -r *\ 2.*
  rm -r *\ 2/
  cd ..
  rm sass-restructure.zip

  echo "Finished!"
elif [ "$1" == "update" ]; then

  if [ "$2" == "-a" ] || [ "$2" == "--auto" ]; then
    interactive=false
  elif [ "$2" == "-i" ] || [ "$2" == "--interactive" ]; then
    interactive=true
  elif [ "$2" != "" ]; then
    echo "unknown option '$2'"
    usage
  fi

  echo "Checking for updates..."
  bower list > updates.tmp
  if [ "$(cat updates.tmp | grep -E "\(latest is ([0-9]\.)*[0-9]\)")" == "" ]; then
    echo "All packages up to date."
    exit 0
  fi
  cat updates.tmp | grep -E "\(latest is ([0-9]\.)*[0-9]\)" | while read -r line ; do
    name=$(echo $line | grep -o -E "[a-z | -]*#" | grep -o -E "[^#]*")
    current=$(echo $line | grep -o -E "#([0-9]*\.)*[0-9]" | grep -o -E "[^#]*")
    new=$(echo $line | grep -o -E "\(.*\)" | grep -o -E "([0-9]*\.)*[0-9]")
    if [ $interactive == true ]; then
      echo "Updates available for$name"
      echo "Current: ($current) New: ($new)"
      echo "Would you like to update now(Y/n)?"
      read ans </dev/tty
      ans=$(echo "$ans" | awk '{print tolower($0)}')
      if [ "$ans" == "" ] || [ "${ans:0:1}" == "y" ]; then
        echo "Updating$name to version $new..."
        bower update $name
      fi
    else
      echo "updating $name from version $current to version $new..."
      bower update $name
    fi
  done
else
  usage
fi
