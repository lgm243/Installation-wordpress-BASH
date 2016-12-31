#!/bin/bash
#
# Automatize WordPress installation
# bash install.sh
#
# Inspirated from Maxime BJ
# For more information, please visit 
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


# Paths
rootpath="/Applications/MAMP/htdocs/"
pathtoinstall="${rootpath}${foldername}/"
url="http://localhost:8888/$foldername/"
acfkey="lacleACF"

success "Récap"
echo "--------------------------------------"
echo -e "Url : $url"
echo -e "Foldername : $foldername"
echo -e "Titre du projet : $title"
echo "--------------------------------------"

# Admin login

adminemail="contact@lgmcreation.fr"

# DB
dbname=$foldername
dbuser=root
dbpass=root
dbprefix=$prefix"_"


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
# cd $pathtoinstall
cd wp-content/themes/
git clone https://github.com/lgm243/wordpress.git

# Modifie le nom du theme
bot "Je modifie le nom du theme"
mv wordpress $foldername

# Modifie le fichier style.scss
bot "Je modifie le fichier style.sccss du thème $foldername"
echo "/* 
	Theme Name: $foldername
	Author: Lgmcreation
	Author URI: http://www.lgmcreation.fr
	Version: 1.0.0
*/" > $foldername/dev/css/style.scss

# Supprime le dossier cache git 
find ./ -depth -name ".git" -exec rm -Rf {}

# Activate theme
bot "J'active le thème $foldername:"
wp theme activate $foldername

# Plugins install
bot "J'installe les plugin yoast hidelogin"
wp plugin install wordpress-seo --activate
wp plugin install wps-hide-login 

# Si on a bien une clé acf pro
bot "J'installe ACF PRO"
# cd $pathtoinstac
cd ..
cd plugins
curl -L -v 'http://connect.advancedcustomfields.com/index.php?p=pro&a=download&k='$acfkey > advanced-custom-fields-pro.zip
wp plugin install advanced-custom-fields-pro.zip --activate
rm -f advanced-custom-fields-pro.zip

# Misc cleanup
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

# CHANGE ID ADMIN 580
bot "Je modifie l'ID de l'ADMIN"
wp db query "
UPDATE ${prefix}_users SET ID = 580 WHERE ID = 1;
UPDATE ${prefix}_usermeta SET user_id=580 WHERE user_id=1;
UPDATE ${prefix}_posts SET post_author=580 WHERE post_author=0;
ALTER TABLE ${prefix}_users AUTO_INCREMENT = 581
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

# Permalinks to /%postname%/
bot "J'active la structure des permaliens"
wp rewrite structure "/%postname%/" --hard
wp rewrite flush --hard

# cat and tag base update
wp option update category_base theme
wp option update tag_base sujet

# Menu stuff
bot "Je crée le menu principal, assigne les pages, et je lie l'emplacement du thème : "
wp menu create "Menu Principal"
wp menu item add-post menu-principal 1
wp menu item add-post menu-principal 2
wp menu item add-post menu-principal 3
wp menu location assign menu-principal main-menu

#Modifier le fichier htaccess
bot "J'ajoute des règles Apache dans le fichier htaccess"
cd ../..
echo "
#Interdire le listage des repertoires
Options All -Indexes

#Interdire l'accès au fichier wp-config.php
<Files wp-config.php>
 	order allow,deny
	deny from all
</Files>

#Intedire l'accès au fichier htaccess lui même
<Files .htaccess>
	order allow,deny 
	deny from all 
</Files>
" >> .htaccess

rm -f license.txt
rm -f readme.html
rm -f wp-cli.yml


# Finish !
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

# Open in browser
open $url
open "${url}wp-admin"

# Open in Sublime text
cd wp-content/themes
cd $foldername
sublime .






