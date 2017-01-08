#!/bin/bash
#
# WordPress installation
# bash install.sh
#
# https://github.com/posykrat/dfwp_tools/blob/master/install.sh
# http://www.wp-spread.com/tuto-wp-cli-comment-installer-et-configurer-wordpress-en-moins-dune-minute-et-en-seulement-un-clic/

#  ==============================
#  ECHO COLORS, FUNCTIONS AND VARS
#  ==============================
bggreen='\033[42m'
bgred='\033[41m'
bold='\033[1m'
black='\033[30m'
gray='\033[37m'
normal='\033[0m'
# Jump a line
function line {
	echo " "
}

# Basic echo
function bot {
	line
	echo -e "$1 ${normal}"
}

# Error echo
function error {
	line
	echo -e "${bgred}${bold}${gray} $1 ${normal}"
}

# Success echo
function success {
	line
	echo -e "${bggreen}${bold}${gray} $1 ${normal}"
}

#  ==============================
#  VARS
#  ==============================


# On récupère le nom du dossier
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Nom du dossier ? " foldername
if [ -z $foldername ]
	then
		error 'Renseigner un nom de dossier'
		exit
fi

# On récupère le titre du site
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Titre du projet ? " title
if [ -z "$title" ]
	then
		error 'Renseigner un titre pour le site'
	exit
fi

# On récupère le login admin
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Administrateur ? " adminlogin
if [ -z "$adminlogin" ]
	then
		error 'Nom administrateur'
		exit
fi

# On récupère le pass admin
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Mot de passe ? " adminpass
if [ -z "$adminpass" ]
	then
		error 'Pass administrateur'
		exit
fi


# On récupère le titre du site
# Si pas de valeur renseignée, message d'erreur et exit
read -p "Prefix table ? " prefix
if [ -z "$prefix" ]
	then
		error 'Prefix table'
		exit
fi

# On récupère la future URL du site pour changer le htaccess
read -p "URL du futur site ? " urlsite

# Paths
path=`pwd` #Repertoire courant du  script
rootpath="/Applications/MAMP/htdocs/"
pathtoinstall="${rootpath}${foldername}/"
url="http://localhost:8888/$foldername/"

#Variables
acfkey="b3JkZXJfaWQ9Nzc2NjF8dHlwZT1kZXZlbG9wZXJ8ZGF0ZT0yMDE2LTAzLTE4IDE1OjU4OjA0"
#ID admin et editor (idamin générer par RANDOM)
idadmin=$[ ( $RANDOM % 500 )  + 100 ]
ideditor=`expr $idadmin + 1`

# Fichiers à inclure
maj="${path}/maj_htaccess.txt"
htaccess_includes="${path}/htaccess_dossier_includes.txt"
htaccess_content_upload="${path}/htaccess_dossier_content_upload.txt"
robots="${path}/robots.txt"

# Admin Email
adminemail="contact@lgmcreation.fr"

# BASE DE DONNEE
dbname=$foldername
dbuser=root
dbpass=root
dbprefix=$prefix"_"

success "Récap"
echo "--------------------------------------"
echo -e "Url : $url"
echo -e "Foldername : $foldername"
echo -e "Titre du projet : $title"
echo "--------------------------------------"
#  ==============================
#  = The show is about to begin =
#  ==============================

# Welcome !
success "L'installation va pouvoir commencer"
echo "--------------------------------------"

# CHECK :  Directory doesn't exist
# cd $rootpath

# Check if provided folder name already exists
if [ -d $pathtoinstall ]; then
  error "Le dossier $pathtoinstall existe déjà. Par sécurité, je ne vais pas plus loin pour ne rien écraser."
  exit 1
fi


# Create directory
bot "Je crée le dossier : $foldername"
cd $rootpath
mkdir $foldername
cd $foldername

bot "Je crée le fichier de configuration wp-cli.yml"
echo "
# Configuration de wpcli
# Voir http://wp-cli.org/config/
# Les modules apaches à charger
apache_modules:
	- mod_rewrite
" >> wp-cli.yml


# Télécharge WP
bot "Je télécharge la dernière version de WordPress en français..."
wp core download --locale=fr_FR --force

# Check version
bot "J'ai récupéré cette version :"
wp core version

# Create base configuration
bot "Je lance la configuration"
wp core config --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpass --dbprefix=$dbprefix --extra-php <<PHP
// Désactiver l'éditeur de thème et de plugins en administration
define('DISALLOW_FILE_EDIT', true);

// Changer le nombre de révisions de contenus
define('WP_POST_REVISIONS', 3);

// Supprimer automatiquement la corbeille tous les 7 jours
define('EMPTY_TRASH_DAYS', 7);

// sauvegarde auto 5 min
define('AUTOSAVE_INTERVAL', 300 ); // seconds

//Mode debug
define('WP_DEBUG', true);
PHP

# Create database
bot "Je crée la base de données"
wp db create

# Launch install
bot "J'installe WordPress..."
wp core install --url=$url --title="$title" --admin_user=$adminlogin --admin_email=$adminemail --admin_password=$adminpass

# Télécharge thème Wordpress par default
bot "Je télécharge mon thème de base"
cd wp-content/themes/
git clone https://github.com/lgm243/wordpress.git


# Modifie le nom du theme
bot "Je modifie le nom du theme"
mv wordpress $foldername

cd $foldername
rm -rf .git

cd dev/css/
# Modifie le fichier style.sccss (bak bug macos)
bot "Je modifie le fichier style.sccss du thème $foldername"
sed -i.bak "s/nouveausite/${title}/g" style.scss
rm -f style.scss.bak

# Activate theme
bot "J'active le thème $foldername:"
wp theme activate $foldername

# # Plugins install
# bot "J'installe les plugin yoast hidelogin"
# wp plugin install wordpress-seo --activate
# wp plugin install wps-hide-login 

# # Si on a bien une clé acf pro
# bot "J'installe ACF PRO"
# # cd $pathtoinstac
# cd ..
# cd plugins
# curl -L -v 'http://connect.advancedcustomfields.com/index.php?p=pro&a=download&k='$acfkey > advanced-custom-fields-pro.zip
# wp plugin install advanced-custom-fields-pro.zip --activate
# rm -f advanced-custom-fields-pro.zip

# Supprime post articles terms
bot "Je supprime les posts, comments et terms"
wp site empty --yes

#Crée pages
bot "Je crée les pages standards accueil et mentions légales"
wp post create --post_type=page --post_title='Accueil' --post_status=publish
wp post create --post_type=page --post_title='Blog' --post_status=publish
wp post create --post_type=page --post_title='Contact' --post_status=publish
wp post create --post_type=page --post_title='Mentions Légales' --post_status=publish

#Crée articles
curl http://loripsum.net/api/5 | wp post generate --post_content --count=5

# CHANGE ID ADMIN
bot "Je modifie l'ID de l'ADMIN"
wp db query "
UPDATE ${prefix}_users SET ID = ${idadmin} WHERE ID = 1;
UPDATE ${prefix}_usermeta SET user_id=${idadmin} WHERE user_id=1;
UPDATE ${prefix}_posts SET post_author=${idadmin} WHERE post_author=0;
ALTER TABLE ${prefix}_users AUTO_INCREMENT = ${ideditor};
"

# Définition page accueil et articles et SEO
bot "Je change la page d'accueil et la page des articles"
wp option update show_on_front page
wp option update page_on_front 1
wp option update page_for_posts 2
wp option update blog_public 0

# Supprime les thèmes et plugins et arcticles
bot "Je supprime Hello Dolly, les thèmes de base"
wp plugin uninstall hello --skip-delete
wp theme delete twentyseventeen
wp theme delete twentysixteen
wp theme delete twentyfifteen
wp option update blogdescription ''

# Active Permalien
bot "J'active la structure des permaliens"
wp rewrite structure "/%postname%/" --hard
wp rewrite flush --hard

# Modifie le nom de Catégorie et Tag
wp option update category_base theme
wp option update tag_base sujet

# Crée le Menu 
bot "Je crée le menu principal, assigne les pages, et je lie l'emplacement du thème : "
wp menu create "Menu Principal"
wp menu item add-post menu-principal 1
wp menu item add-post menu-principal 2
wp menu item add-post menu-principal 3
wp menu location assign menu-principal main-menu

# Modifie le fichier htaccess
bot "J'ajoute des règles Apache dans le fichier htaccess"
cd $pathtoinstall
cat $maj >> .htaccess
if [ -n "$urlsite" ]
then
    sed -i.bak "s/monsite\.com/lgmcreation\.fr/g" .htaccess
	rm -f .htaccess.bak
fi

#Ajout htaccess wp-includes
cp  $htaccess_includes $pathtoinstall/wp-includes/.htaccess

#Ajout htaccess wp-content
cp  $htaccess_includes $pathtoinstall/wp-content/.htaccess

#Ajout htaccess wp-uplaod
cp  $htaccess_content_upload $pathtoinstall/wp-content/uploads/.htaccess

# J'ajoute les ficheir robots.txt
cp  $robots $pathtoinstall/robots.txt

rm -f license.txt
rm -f readme.html
rm -f wp-cli.yml


# Fin
success "L'installation est terminée !"
echo "--------------------------------------"
echo -e "Url			: $url"
echo -e "Path			: $pathtoinstall"
echo -e "Admin login	: $adminlogin"
echo -e "Admin pass		: $adminpass"
echo -e "Admin email	: $adminemail"
echo -e "DB name 		: localhost"
echo -e "DB user 		: root"
echo -e "DB pass 		: root"
echo -e "DB prefix 		: $dbprefix"
echo -e "WP_DEBUG 		: TRUE"
echo "--------------------------------------"

# Ouvre le site sur ma page web
open $url
open "${url}wp-admin"

# Ouvre Sublime text
cd wp-content/themes
cd $foldername
sublime .

#ouvre fenetre terminal et lance npm install pour gulp (window 1 pour rester sur la meme fenetre ouverte)
osascript -e 'tell application "Terminal"
    do script "cd '$pathtoinstall'/wp-content/themes/'$foldername'" activate
    do script "npm install" in window 1
end tell'
