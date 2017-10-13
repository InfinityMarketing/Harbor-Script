#! /usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Aug  3 14:20:50 2017

@author: Mark Bixler
"""
import zipfile
import os
import requests
import glob
import subprocess
import platform
import sys, getopt
import argparse
import re

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--update',
                        action='store_true',
                        dest='update',
                        default=False,
                        help="Check for updates to the harbor script")
    parser.add_argument('-i', '--install', action='store_true',
                        dest='install',
                        default=False,
                        help="Install harbor theme in current directory")
    parser.add_argument('-d', '--directory', action='store',
                        dest='dir',
                        help="Specify a directory to install Harbor theme to or if -u option is present updates the Harbor based theme in that directory")
    plat = platform.system()
    results = parser.parse_args()
    install = results.install
    update = results.update
    setup_dir = results.dir
    if(install):
        if setup_dir is not None:
            os.chdir(setup_dir)

        if platform.system() != "Windows":
            if os.getuid() != 0:
                print("Please run this script as root")
                print("Example: 'sudo python3 setup.py'")
                return

        #download theme zip
        if fetchArchive() == False:
            return 1

        print("Setting up Theme...")
        slug = setupTheme()

        setupEnvironment(slug)
    elif update:
        if setup_dir is not None:
            updateTheme(setup_dir)
        else:
            print("Checking for updates to Harbor script...")

            print("Up to date!")
    else:
        parser.print_usage()


def updateTheme(directory):
    os.chdir(directory)
    print("Updating theme...")
    os.system("bower list > updates.tmp")
    update_avail = re.compile("\(([0-9]\.)*[0-9] available\)")
    nameRe = re.compile("[a-z]+-*[a-z]*#")
    #print(update_avail.findall("├─┬ breakpoint-sass#2.5.0 "))
    #exit(0)
    with open("updates.tmp", "r") as update_file:
        for line in update_file:
            results = update_avail.findall(line)
            if results != []:
                print(line)
                nameMatch = nameRe.search(line)
                name = nameMatch.group()[:-1]
                ans = input("Update module?(Y/n)")
                while ans != "" and ans.lower()[0] != 'y' and ans.lower()[0] != 'n':
                    ans = input("Update module?(Y/n)")
                if(ans == "" or ans.lower()[0] == 'y'):
                    print("updating", name, sep=" ")
                    os.system("bower update " + name)
                    print("")
    print("Done!")

# Downloads the starter theme _s from github
def fetchArchive():
    try:
        os.remove("sass-restructure.zip")
    except FileNotFoundError:
        pass

    print("Downloading Theme files...", end=' ')
    file = requests.get("https://github.com/Infinity-Marketing/Harbor/archive/sass-restructure.zip")
    if file.status_code != 200:
        print("Error: There was a problem while downloading the files.\n\tAborting. ")
        return False
    with open("sass-restructure.zip", "wb") as content:
        content.write(file.content)

    print("Done!")

    print("Extracting files...", end=' ')
    with zipfile.ZipFile("sass-restructure.zip", "r") as file:
        file.extractall(".")

    print("Done!")
    return True


def setupTheme():
    name = input("Enter a name for the theme: ")
    slug = name.lower().replace(' ', '-')
    funcSlug = name.lower().replace(' ', '_')
    desc = input("Enter a short description for the theme: ")

    print("Setting up Theme...", end=' ')

    os.rename("./Harbor-sass-restructure", "./" + slug)


    files = glob.glob("./" + slug + "/*.php")
    for filename in glob.glob("./" + slug + "/*/*.php"):
        files.append(filename)

    strings = []
    strings.append(("'harbor'", "'" + slug + "'"))
    strings.append(("harbor_", funcSlug + "_"))
    strings.append((" <code>&nbsp;Harbor</code>", " <code>&nbsp;" + name.replace(' ', '_') + "</code>"))
    strings.append(("Harbor-", slug + "-"))
    findInFiles(strings, files)

    headerInfo = []
    headerInfo.append(("Text Domain: harbor", "Text Domain: " + slug))
    headerInfo.append(("Theme Name: Harbor", "Theme Name: " + name))
    headerInfo.append(("Description: Harbor is a starter theme and development environment setup by Infinity Marketing that is heavily based on Automattic's Underscores theme.", "Description: " + desc))
    findInFiles(headerInfo, ["./" + slug + "/style.css", "./" + slug + "/sass/style.scss"])

    print('Done!')
    return slug

def findInFiles(strings, files):
    for filename in files:
        file = open(filename, "r")
        filedata = file.read()
        file.close()

        for change in strings:
            filedata = filedata.replace(change[0], change[1])

        file = open(filename, "w")
        file.write(filedata)
        file.close()


def setupEnvironment(slug):
    cmd = "where" if platform.system() == "Windows" else "which"

    npm = subprocess.run(cmd+ " npm", shell=True)
    if npm.returncode == 1:
       print("NodeJs is not installed. Aborting")
       return
    bower = subprocess.run(cmd+ " bower", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if bower.returncode == 1:
       print("Bower is not installed.")
       print("Installing bower...")
       subprocess.run("npm install -g bower", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
       print("Done!")

    gulp = subprocess.run(cmd+ " gulp", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if gulp.returncode == 1:
        print("Gulp is not installed")
        print("Installing Gulp...", end=' ')
        subprocess.run("npm install -g gulp", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print("Done!")

    print("Installing dependancies...")
    subprocess.run("bower install", shell=True, cwd="./"+slug)
    subprocess.run("npm install", shell=True, cwd="./"+slug)

    print("Done!")

if(__name__ == "__main__"):
    main()
