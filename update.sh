#!/bin/bash

# ********** Fedora System Update ONLY **********
# 2019-11-15
#
#
#
date
echo "Time to get these updates mayne! "
check_exit_status() {

        if [ $? -eq 0 ]
        then
           echo
           echo "Success"
           echo
        else

           echo
           echo "[ERROR] Process messed up bruh bruh!"
           echo

           read -p "The last command exited with an error. Exit script? (yes/no)" answer

           if [ "$answer" == "yes" ]
           then
                exit 1
           fi

     fi
 }
greeting() {

        echo
        echo "Hello, $USER. Let's update this system. "
        echo
}
update() {

        sudo dnf update -y;

        sudo dnf upgrade -y;
        check_exit_status

      #  sudo dnf dist-upgrade -y;
      #  check_exit_status
}
cleanuptime() {

        sudo dnf autoremove -y;
}
bounce() {
        echo
        echo "---------------------------------"
        echo "- Ok We Good, Update Complete! -"
        echo "---------------------------------"
        echo
        exit
}
greeting
update
cleanuptime
