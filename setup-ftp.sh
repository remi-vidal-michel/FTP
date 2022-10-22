#!/bin/bash

user=$(id -u)
if [ $user != 0 ]
then
   echo "Ce script doit être exécuté en tant qu'utilisateur root" 
   exit 1
fi

echo " "
echo "Setup FTP"
echo "------------------------------------------------------------------------"
echo "Ecrire '1' pour installer et configurer FTP (JOB7)"
echo "Ecrire '2' pour configurer les utilisateurs depuis un fichier csv (JOB9)"
echo "Ecrire '3' pour désinstaller FTP (JOB8)"
echo "Ecrire '4' pour ne pas effectuer de modifications et revenir au terminal"
echo "------------------------------------------------------------------------"
echo "Votre choix : " | tr -d '\n';
read option;

if [ $option = 1 ]
then
    apt -y update ; apt -y upgrade ; apt -y install proftpd ; apt -y install git
    cp /etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf.back
    git clone https://github.com/remi-vidal-michel/referencecfg.git
    cat referencecfg/cfg.txt > /etc/proftpd/proftpd.conf
    mkdir -p /etc/proftpd/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 -out /etc/proftpd/ssl/proftpd-rsa.pem \
    -keyout /etc/proftpd/ssl/proftpd-key.pem -subj "/C=''/ST=''/L=''/O=''/OU=''/CN=''" 
    chmod 440 /etc/proftpd/ssl/proftpd-key.pem
    rm -r referencecfg
    service proftpd restart
    echo "FTP est dorénavant configuré et actif."
    ip=$(hostname -I | cut -f1 -d' ')
    echo "Votre IP est $ip"

elif [ $option = 3 ]
then
    apt -y remove --purge proftpd-*
    echo " "
    echo "FTP a bien été désinstallé."

elif [ $option = 4 ]
then
    exit

elif [ $option = 2 ]
then
    echo " "
    echo "Le fichier csv doit avoir le format suivant : ID - Nom d'Utilisateur - Mot de Passe - Rôle"
    echo "Indiquez le chemin du fichier csv :"
    read input
    groupadd ftpUsers
    sed 1d $input | while IFS=, read ID username password role || [ -n "$role" ];
    do
        useradd -mp $(openssl passwd -1 $password) $username
        usermod -aG ftpUsers $username
        if [ $role = Admin ]
        then
            usermod -aG sudo $username
        fi
        done
echo "Les utilisateurs ont été ajouté"

else
    echo "Erreur : Veuillez écrire 1, 2, 3 ou 4"
fi

# cd /mnt/c/Users/remiv/Documents/git-hub/ftp/referencecfg/
# /mnt/c/Users/remiv/Documents/git-hub/ftp/referencecfg/Shell_Userlist.csv
# sh setup-ftp.sh