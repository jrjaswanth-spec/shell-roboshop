#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d. -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo  &>>$LOG_FILE
VALIDATE $? "adding rabbitmq repo"

dnf install rabbitmq-server -y  &>>$LOG_FILE
VALIDATE $? "installinf rabbitmq"
systemctl enable rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "enabling rabbitmq"
systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "starting rabbitmq"

rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "adding user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"  &>>$LOG_FILE
VALIDATE $? "setting up permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME-$START_TIME ))
echo -e "script executed in: $Y $TOTAL_TIME seconds $N"