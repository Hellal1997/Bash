#!/bin/bash


create_database(){
        read -p " join database name " db_name
        if [ -d "./$db_name" ] ; then
                echo "Databas already exists"

        else
                mkdir "./$db_name"
                echo "Database Created"
        fi
}

list_databases(){
	echo "*******************"
        echo "*****Databases*****"
	echo "*******************"
        ls -d */
}

connect_database(){
        read -p "join database name " db_name
        if [ -d "./$db_name" ] ; then
                cd "./$db_name" 
	       	while true ; do 
			echo "1-List all tables "
			echo "2-Create new table "
			echo "3-Select From Table "
			echo "4-Insert into table "
			echo "5-Delete from table "
 			echo "6-Update in table "
			echo "7-Drop table "
			echo "8-back to main menue"
			read -p "Enter your number of these functions " tb_choice 

			case $tb_choice in
				1) list_tables ;;
				2) create_table ;;
				3) select_from_table ;;
				4) insert_into_table ;;
				5) delete_from_table ;;
				6) upate_table ;;
				7) drop_table ;;
				8) break  ;;
				*) echo "Invalid Choice " ;;
			esac
		done
		cd ..

	else
                echo  "DataBase Doesn't exist"
        fi
}

drop_database(){
        read -p "Enter Databse name you want to drop..." db_name
        if [ -d "./$db_name" ] ; then
                rm -r "./$db_name"
                echo " **************"
		echo "Database Dropped "
        else
              echo "DataBase Doesn't exist "
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
            *) echo "Invalid your choose. Please try again." ;;
    esac
done


