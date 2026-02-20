
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


mkdir -p /app 
VALIDATE $? "creating app directory" 
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading cart application" 
cd /app 
VALIDATE $? "changing to app directory"
rm -rf /app/*
VALIDATE $? "removing existing code"
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzip cart"
npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copy systemctl services"
systemctl daemon-reload
VALIDATE $? "daemon reload"
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enable cart"
systemctl start cart
VALIDATE $? "start cart"




    
systemctl restart cart
VALIDATE $? "restarting cart"