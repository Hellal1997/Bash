#!/bin/bash

create_database(){
        read -p "Enter Databse Name" db_name
        if [ -d "./$db_name" ] ; then
                echo "Databas already exists"

        else
                mkdir "./$db_name"
                echo "Database Created"
        fi
}

list_databases(){
        echo "Databases"
        ls -d */
}

connect_database(){
        read -p "Enter Database name " db_name
        if [ -d "./$db_name"]; then
                cd "./$db_name" 
        else
                echo  "DataBase Does Not Exist"
        fi
}

drop_database(){
        read -p "Enter Databse name you want to drop" db_name
        if [ -d "./$db_name"] ; then
                rm -r "./$db_name"
                echo "Database Dropped"
        else
                "Database Does not exist"
        fi
}


while true ;do 
	echo "Main Menue"
	echo "1 Create Database" 
	echo "2-List Databases"
	echo "3-Connect to Database"
	echo "4-Drop Database"
	echo "5-Exit"
	read -p "Enter your choice"  choice 


	case $choice in
	    1) create_database ;;
    	    2) list_databases ;;
            3) connect_database ;;
            4) drop_database ;;
            5) exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
    esac
done
