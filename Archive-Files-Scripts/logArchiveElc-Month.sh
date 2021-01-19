#!/bin/bash

# 这个脚本是用来归档精英班的训练日志；
# 在计划任务中每半天去检查用户的家目录中有没有新的日志提交，有的话，自动归档；
# 首先将新上传的日志归档到个人每月份的目录，该目录只能脚本添加，不能自行添加或删除，然后再复制到班级的每月份目录方便教练检查；
# 要求日志提交日期格式一定要规范。

LogArchiveScript(){
#  Elite Class students home directory.
ECdir="/files/home/46thEliteClass1"
#  Elite Class Log Archive Directory.
ECLADir="/files/archive/documents/第46届世界技能大赛/训练日志归档/第1梯队"
currMouth=$(date "+%Y.%m")
logArchiveMouth=logArchive_$currMouth

# 拷贝精英班的日志

#  Elite Class Log Archive Directory for  Mouthly.
ECLADirM=$ECLADir/$logArchiveMouth
if [ ! -d "$ECLADirM" ];then
    mkdir  -p "$ECLADirM"
    chown huangdaojin  "$ECLADirM"
fi

find "$ECdir" -mindepth 1 -maxdepth 1  -type d | while read  StuHomeDir
 do
     LogArchiveDir="$StuHomeDir/$logArchiveMouth"
     if [ ! -d  "$LogArchiveDir" ] ; then
             mkdir   "$LogArchiveDir"
             chmod  755  "$LogArchiveDir"
     fi
     lsattr  -ld "$LogArchiveDir" | grep -q "Append_Only"
     if [ $? -eq 0 ] ;then
            chattr  -a  "$LogArchiveDir"
     fi
#     find  "$StuHomeDir" -mindepth 1  -maxdepth 1   -type f \( -regextype posix-extended -iregex  ".*/2019.*(Linux|Windows|Cisco).*[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.pdf$" \) -exec  basename {} \; |while  read  LogName
find  "$StuHomeDir" -mindepth 1  -maxdepth 1   -type f -iname "*.pdf"  -exec  basename {} \; |egrep '^选手-第46届世界技能大赛网络系统管理项目精英班集训日志-.{2,3}-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-(Linux|Windows|Cisco|English|Troubleshooting|Huawei|Python|Other)\.pdf$' |while  read  LogName
         do
                 FileMouth=$(echo  "$LogName" | grep -o '[0-9]\{4\}\.[0-9]\{2\}')
                 if [ -z "$FileMouth" ] ;then
                         continue;
                 elif [ "$FileMouth" = "$currMouth" ] ; then
#拷贝学生日志到教练查看目录
#    			 for DDir in Linux  Windows  Cisco
#    			 do
#    				 echo $LogName |grep -q $DDir
#    				 if [ $? -eq 0  ];then
#    					 if  [ ! -d  "$ECLADirW/$DDir" ] ;then
#    						 mkdir -p "$ECLADirW/$DDir"
#    				         fi
#    					 chmod  644 "$StuHomeDir/$LogName"
#                             	         cp  -a "$StuHomeDir/$LogName"  "$ECLADirW/$DDir/"
#    			         fi
#    			  done
                     cp  "$StuHomeDir/$LogName"  "$ECLADirM"/
			chown  huangdaojin  "$ECLADirM"/"$LogName"
# 移动归档到学生家目录下
                     mv  "$StuHomeDir/$LogName"  "$LogArchiveDir"/
   #                 chattr +i  "$LogArchiveDir/$LogName"
                  fi
            done
            lsattr  -ld "$LogArchiveDir" | grep -q "Append_Only"
            if [ $? -ne 0 ] ;then
                   chattr  +a  "$LogArchiveDir"
            fi
     done
}
# 统计上交情况并输出到HTML
#
#logHtml(){
#    HtmlDir=/var/www/html/mydoc/LogArchive
#    HtmlTemplate="$HtmlDir"/LogArchive_template.html
#    WeekHtml="$HtmlDir"/"$currMouth".html
#    grep  -q "$currMouth"  "$HtmlDir"/index.html
#    if [ $? -ne  0 ] ;then
#    	sed  -i "/<section>/a <p>月: <a href="$currMouth.html">"$currMouth"</a></p>"  "$HtmlDir"/index.html
#    fi
#    if  [  ! -f  "$WeekHtml" ] ;then
#    	cp  "$HtmlTemplate"  "$WeekHtml" 
#    	sed -i  "s/week/$currMouth/"   "$WeekHtml"
#    fi
#    
#    for FDir in $(ls $ECLADirW)
#    do
#        find   "$ECLADirW"/"$FDir"  -type f  -iname  "*.pdf"  -exec basename {} \;| while  read  LogFile
#           do
#    	  StuName=$(echo  "$LogFile" |awk -F "-" '{print $2}')
#    	  grep "$StuName"  "$WeekHtml" |grep  -q  "bkc" 
#    	  if [ $?  -eq  0 ] ;then
#    	      sed -i "/$StuName/s/<span class=\"bkc\">$FDir<\/span>/$FDir/" "$WeekHtml"
#              fi
#           done
#    done
# }

# 支持添加月份参数2021.01收集指定月份的日志

if [ "$#" -eq 0 ] ; then
         currMouth=$(date "+%Y.%m")
         LogArchiveScript
else
         for  Date  in  $@
              do
# 判断日期的格式
                      echo  "$Date" | grep -q '^[0-9]\{4\}\.[0-9]\{1,2\}$'
                      if [ "$?" -ne 0 ] ;then
                           echo " $Date Form Error. use 2019.09"
                           continue
                      fi
                      currMouth="$Date"
                      LogArchiveScript
              done
fi

