#cpanel CLI simplification script for doing things in the CLI that you would rather not have to do in cPanel
#Version 0.02
#Declare our variables!
process=$1
group=$2
specify1=$3
specify2=$4
specify3=$5
specify4=$6
#These arrays are for the help process so people can figure out what is available.
arrayprocess=(help mysql email);
arraygroupmysql=(chgpasswd createdb createusr deletedb deleteusr setusrprivs);
arraygroupemail=(createaccount deleteaccount chgmx);
arrayspecifymysqlchgpasswd=(cpuser mysqldbusr passwd);
arrayspecifymysqlcreatedb=(cpuser dbname);
arrayspecifymysqlcreateusr=(cpuser usrname passwd);
arrayspecifymysqldeletedb=(cpuser dbname);
arrayspecifymysqldeleteusr=(cpuser mysqlusr);
arrayspecifymysqlsetusrprivs=(cpuser mysqlusr dbname "ALL PRIVILEGES");
arrayspecifyemailcreateaccount=(cpuser email@domain.com passwd);
arrayspecifyemaildeleteaccount=(cpuser email@domain.com);
arrayspecifyemailchgmx=(domain mxtype);

#This is what controls our help, it's the meat of the program and will list the arrays above as needed.
#this line may be broken but this is what I'm working on
while [[ -z `${arrayprocess[*]} | grep $process` ]]; do echo "Please type one of ${arrayprocess[*]}"; read process; done
if [[ $process == "help" ]]; then
  if [[ $group == "" ]]; then
    echo "A shell script to automate useful WHMAPI commands.";
    echo "Current process options: ${arrayprocess[*]}";
    echo "Ask about specific process options by running ./cpcli.sh help (process)";
    echo "If you have any questions or concerns, please submit a patch request or open a bug!"
    exit 1;
  fi
  if [[ -z $specify1 ]]; then
    arrayname=arraygroup$group[@];
    echo "The options for $group are ${!arrayname}";
    echo "If you have any questions about the things to fill out from here, please run ./cpcli.sh help $group (option).";
    exit 1;
  else arrayname=arrayspecify$group$specify1[@];
    echo "For $group $specify1, you'll need to provide ${!arrayname} in order, like this:";
    echo " ./cpcli.sh $group $specify1 ${!arrayname} ";
  fi
fi
if [[ $group == "" ]]; then
  arrayname=arraygroup$process[@];
  echo "Please type one of ${!arrayname}"; read group;
fi
if [[ $specify1 == "" ]]; then
  arrayname=arrayspecify$process$group[@];
  echo "Now fill out all of ${!arrayname} one at a time in this order:";
  echo ${!arrayname};
  numoptions=`echo ${!arrayname} | wc -w`
  if [ $numoptions -gt 0 ]; then read specify1; fi
  if [ $numoptions -gt 1 ]; then read specify2; fi
  if [ $numoptions -gt 2 ]; then read specify3; fi
  if [ $numoptions -gt 3 ]; then read specify4; fi
fi

#This bit actually runs the processes. If statements, ahoy.
if [[ $process == "mysql" ]]; then
  if [[ $group == "chgpasswd" ]]; then
    uapi --user=$specify1 Mysql set_password user=$specify2 password=$specify3
    echo "In the cPanel user $specify1 we set the MySQL user $specify2 to the password $specify3"
  fi
  if [[ $group == "createdb" ]]; then
    uapi --user=$specify1 Mysql create_database name=$specify2
    echo "We made a mysql database with user $specify1 and dbname $specify2"
  fi
  if [[ $group == "createusr" ]]; then
    uapi --user=$specify1 Mysql create_user name=$specify2 password=specify3
    echo "We made a mysql user with cPanel user $specify1, name $specify2, and password $specify3"
  fi
  if [[ $group == "deletedb" ]]; then
    uapi uapi --user=$specify1 Mysql delete_database name=$specify2
    echo "We deleted the database $specify2 from the user $specify1"
  fi
  if [[ $group == "deleteuser" ]]; then
    uapi --user=$specify1 Mysql delete_user name=$specify2
    echo "We deleted the MySQL user $specify2"
  fi
  if [[ $group == "setusrprivs" ]]; the
    uapi --user=$specify1 Mysql set_privileges_on_database user=$specify2 database=$specify3 privileges=$specify4
    echo "Within the cPanel account $specify1, we gave the privileges $specify4 to the user $specify2 on the db $specify3"
  fi
fi
if [[ $process == "email" ]]; then
  if [[ $group == "createaccount" ]]; then
    uapi --user=$specify1 Email add_pop email=$specify2 password=$specify3 skip_update_db=1
    echo "We created the email account $specify2 on the cpuser $specify1 with the password $specify3"
  fi
  if [[ $group == "deleteaccount" ]]; then
    uapi --user=$specify1 Email delete_pop email=$specify2
    echo "We deleted the email account $specify2 on the cpuser $specify1"
  fi
  if [[ $group == "chgmx" ]]; then
    tempuser=`/scripts/whoowns $specify1`;
    uapi --user=$tempuser Email change_mx domain=$specify1 alwaysaccept=$specify2
    echo "We changed the MX for the domain $specify1 to $specify2"
  fi
fi
