#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d. -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.jrdaws.life
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
 
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJs" 


dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20" 

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs" 

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "creating system user" 
else
     echo -e "user already exist....$Y SKIPPING $N"
fi


mkdir /app 
VALIDATE $? "creating app directory" 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application" 
cd /app 
VALIDATE $? "changing to app directory"
rm -rf /app/*
VALIDATE "removing existing code"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip catalogue"
npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy systemctl services"
systemctl daemon-reload
VALIDATE $? "daemon reload"
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enable catalogue"
systemctl start catalogue
VALIDATE $? "start catalogue"


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo repo"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb client"
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products"
systemctl restart catalogue
VALIDATE $? "restarting catalogue"