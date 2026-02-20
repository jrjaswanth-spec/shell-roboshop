#!/bin/bash
#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d. -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script started executed at: $( "date" )" &>>$LOG_FILE
if [ $USERID -ne 0 ]
then
     echo "ERROR: please run this script with root privelage"
     exit 1
fi


VALIDATE(){
        if [ $1 -ne 0 ] 
    then
         echo -e "$2...$R FAILURE $N"
         exit 1
    else
         echo -e "$2....$G SUCCESS $N"
    fi     
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing MongoDB"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling mongoDB"

systemctl start mongod  &>>$LOG_FILE
VALIDATE $? "starting mongoDB"

sed -i 's127.0.0.1/0.0.0.0/g'
VALIDATE $? "Allowing remote connections to mongod"

systemctl restart mongod
VALIDATE $? "Restarted mongodb"

