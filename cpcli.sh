#cpanel CLI simplification script for doing things in the CLI that you would rather not have to do in cPanel
#Version 0.04
#Declare our variables!
process=$1
group=$2
specify1=$3
specify2=$4
specify3=$5
specify4=$6
#These arrays are for the help process so people can figure out what is available.
arrayprocess=(mysql email ip);
arraygroupmysql=(chgpasswd createdb createusr deletedb deleteusr setusrprivs showdbs showusrs);
arraygroupemail=(createacct deleteacct chgmx chgpasswd);
arraygroupip=(changeip)
arrayspecifymysqlchgpasswd=(mysqldbusr passwd);
arrayspecifymysqlcreatedb=(dbname);
arrayspecifymysqlcreateusr=(usrname passwd);
arrayspecifymysqldeletedb=(dbname);
arrayspecifymysqldeleteusr=(mysqlusr);
arrayspecifymysqlsetusrprivs=(mysqlusr dbname "ALL PRIVILEGES");
arrayspecifymysqlshowdbs=();
arrayspecifymysqlshowusrs=();
arrayspecifyemailcreateaccount=(email@domain.com passwd);
arrayspecifyemaildeleteaccount=(email@domain.com);
arrayspecifyemailchgmx=(domain mxtype);
arrayspecifyemailchgpasswd=(email@domain.com passwd);
arrayspecifyipchgip=(domain newip);

#This is what controls our help, it's the meat of the program and will list the arrays above as needed.
if [[ -z $process ]]; then process="notaprocess"; fi
while [[ -z `echo ${arrayprocess[*]} "help" | grep $process` ]]; do echo "Please type one of: help ${arrayprocess[*]}"; read process; done
if [[ $process == "help" ]]; then
  if [[ -z $group ]]; then group="notagroup"; fi
  while [[ -z `echo ${arrayprocess[*]} | grep $group` ]]; do
    echo "Hello! This is a bash script that makes some cPanel CLI commands easier to run."
    echo "You can type one of these: ${arrayprocess[*]} and this script will give you the options for that group.";
    read group;
  done
  if [[ -z $specify1 ]]; then
    specify1="notspecify1";
    arrayname=arraygroup$group[@];
    echo "The options for $group are ${!arrayname}";
    echo "Type one of those to learn about what exactly that needs.";
    while [[ -z `echo ${!arrayname} | grep $specify1` ]]; do echo "Please type one of ${!arrayname}"; read specify1; done
  fi
  arrayname=arrayspecify$group$specify1[@];
  echo "For $group $specify1, you'll need to provide ${!arrayname} in order, like this:";
  echo " ./cpcli.sh $group $specify1 ${!arrayname} ";
  exit 1
fi
if [[ -z $group ]]; then group="notagroup"; fi
arrayname=arraygroup$process[@];
while [[ -z `echo ${!arrayname} | grep $group` ]]; do echo "Please type one of ${!arrayname}"; read group; done
if [[ $specify1 == "" ]]; then
  arrayname=arrayspecify$process$group[@];
  echo "If you want to use a random password, you can use this:" `tr -cd '[:alnum:]!@#$%^&*()<>?' < /dev/urandom | fold -w20 | head -n1`
  echo "Now fill out all of ${!arrayname} one at a time (press return after each option selected) in this order:";
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
    tempuser=$(ls /var/cpanel/users | grep `echo $specify1 | cut -d"_" -f1`);
    uapi --user=$tempuser Mysql set_password user=$specify1 password=$specify2
  fi
  if [[ $group == "createdb" ]]; then
    tempuser=$(ls /var/cpanel/users | grep `echo $specify1 | cut -d"_" -f1`);
    uapi --user=$specify1 Mysql create_database name=$specify1
  fi
  if [[ $group == "createusr" ]]; then
    tempuser=$(ls /var/cpanel/users | grep `echo $specify1 | cut -d"_" -f1`);
    uapi --user=$tempuser Mysql create_user name=$specify1 password=specify2
  fi
  if [[ $group == "deletedb" ]]; then
    tempuser=$(ls /var/cpanel/users | grep `echo $specify1 | cut -d"_" -f1`);
    uapi uapi --user=$tempuser Mysql delete_database name=$specify1
  fi
  if [[ $group == "deleteuser" ]]; then
    tempuser=$(ls /var/cpanel/users | grep `echo $specify1 | cut -d"_" -f1`);
    uapi --user=$tempuser Mysql delete_user name=$specify1
  fi
  if [[ $group == "setusrprivs" ]]; then
    tempuser=$(ls /var/cpanel/users | grep `echo $specify1 | cut -d"_" -f1`);
    uapi --user=$tempuser Mysql set_privileges_on_database user=$specify1 database=$specify2 privileges=$specify3
  fi
  if [[ $group == "showusrs" ]]; then
    mysql -e "select distinct user from mysql.user"
  fi
  if [[ $group == "showdbs" ]]; then
    mysql -e "show databases"
  fi
fi
if [[ $process == "email" ]]; then
  if [[ $group == "createacct" ]]; then
    tempdomain=`echo $specify1 | cut -d'@' -f2`;
    tempuser=`/scripts/whoowns $tempdomain`;
    uapi --user=$tempuser Email add_pop email=$specify1 password=$specify2 skip_update_db=1
  fi
  if [[ $group == "deleteacct" ]]; then
    tempdomain=`echo $specify1 | cut -d'@' -f2`;
    tempuser=`/scripts/whoowns $tempdomain`;
    uapi --user=$tempuser Email delete_pop email=$specify1
  fi
  if [[ $group == "chgmx" ]]; then
    tempuser=`/scripts/whoowns $specify1`;
    exchanger=`uapi --user=$tempuser Email list_mxs domain=$specify1 |grep domain | sed 's/ //g' | cut -d: -f2 | head -n1`;
    uapi --user=$tempuser Email change_mx domain=$specify1 alwaysaccept=$specify2 exchanger=$exchanger oldexchanger=$exchanger;
  fi
  if [[ $group == "chgpasswd" ]]; then
    tempdomain=`echo $specify1 | cut -d'@' -f2`;
    tempuser=`/scripts/whoowns $tempdomain`;
    uapi --user=$tempuser Email passwd_pop email=$specify1 password=$specify2 domain=$tempdomain
  fi
fi
if [[ $process == "ip" ]]; then
  if [[ $group == "chgip" ]]; then
    /usr/local/cpanel/bin/setsiteip $specify1 $specify2
  fi
fi
