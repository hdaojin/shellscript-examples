#!/bin/bash

# 这个脚本是用来归档精英班的训练日志；
# 在计划任务中每半天去检查用户的家目录中有没有新的日志提交，有的话，自动归档；
# 首先将新上传的日志归档到个人一周的目录，该目录只能脚本添加，不能自行添加或删除，然后再复制到班级的每周目录方便教练检查；
# 要求日志提交日期格式一定要规范。

# 计算出本周的周一和周日的日期

#currDate=$(date +%F)
#currDate=$i
#Weekday=$(date +%w)
LogArchiveScript(){
    week01Mo="2019-08-26"
    week01Mo1971=$(date -d "$week01Mo" "+%s")
    currDate1971=$(date -d "$currDate" "+%s")
    let weekNumber=(currDate1971-week01Mo1971)/3600/24/7+1
    if [ $weekNumber -lt 10 ];then
        weekNumber="0${weekNumber}"
    fi

    Weekday=$(date  -d "$currDate"  +%u)
    MondayDate=$(date -d "$currDate  -$(($Weekday - 1)) days" +%F)
    SundayDate=$(date -d "$MondayDate +6  days" +%F)
    
    MDD=$(echo  "$MondayDate"|sed 's/-/\./g')
    SDD=$(echo  "$SundayDate"|sed 's/-/\./g')
    LogArchiveDate="$MDD"-"$SDD"

    LogArchive=logArchive_Week"${weekNumber}"\("$MDD"-"$SDD"\)
    
    # 拷贝精英班的日志
    #  Elite Class Log Archive Directory.
    ECLADir="/files/archive/documents/第46届世界技能大赛/训练日志归档/第1梯队"
    
    #  Elite Class Log Archive Directory for  Weekly.
    ECLADirW=$ECLADir/$LogArchive
    if [ ! -d "$ECLADirW" ];then
           mkdir  -p "$ECLADirW"
	   chown huangdaojin  "$ECLADirW"
    fi
    
    
    ECdir="/files/home/46thEliteClass1"
    
    find "$ECdir" -mindepth 1 -maxdepth 1  -type d | while read  StuHomeDir
     do
         LogArchiveDir="$StuHomeDir/$LogArchive"
         if [ ! -d  "$LogArchiveDir" ] ; then
                 mkdir   "$LogArchiveDir"
                 chmod  755  "$LogArchiveDir"
         fi
         lsattr  -ld "$LogArchiveDir" | grep -q "Append_Only"
         if [ $? -eq 0 ] ;then
                chattr  -a  "$LogArchiveDir"
         fi
    #     find  "$StuHomeDir" -mindepth 1  -maxdepth 1   -type f \( -regextype posix-extended -iregex  ".*/2019.*(Linux|Windows|Cisco).*[0-9]{4}\.[0-9]{2}\.[0-9]{2}\.pdf$" \) -exec  basename {} \; |while  read  LogName
    find  "$StuHomeDir" -mindepth 1  -maxdepth 1   -type f -iname "*.pdf"  -exec  basename {} \; |egrep '^选手-第46届世界技能大赛网络系统管理项目精英班集训日志-.{2,3}-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-(Linux|Windows|Cisco|English|Troubleshooting|Other)\.pdf$' |while  read  LogName
             do
                     FileDate=$(echo  "$LogName" | grep -o '[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}')
                     if [ -z "$FileDate" ] ;then
                             continue;
                     elif [[ "$FileDate" > "$MDD" && "$FileDate" < "$SDD" ]] || [[ "$FileDate" = "$MDD" ]] || [[ "$FileDate" = "$SDD" ]] ; then
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
                        cp  "$StuHomeDir/$LogName"  "$ECLADirW"/
			chown  huangdaojin  "$ECLADirW"/"$LogName"
# 移动归档到学生家目录下
                              mv  "$StuHomeDir/$LogName"  "$LogArchiveDir"/
   #                           chattr +i  "$LogArchiveDir/$LogName"
                     fi
            done
            lsattr  -ld "$LogArchiveDir" | grep -q "Append_Only"
            if [ $? -ne 0 ] ;then
                   chattr  +a  "$LogArchiveDir"
            fi
     done
}
# 统计上交情况并输出到HTML

logHtml(){
    HtmlDir=/var/www/html/LogArchive
    HtmlTemplate="$HtmlDir"/LogArchive_template.html
    WeekHtml="$HtmlDir"/"$LogArchiveDate".html
    grep  -q "$LogArchiveDate"  "$HtmlDir"/index.html
    if [ $? -ne  0 ] ;then
    	sed  -i "/<section>/a <p>周: <a href="$LogArchiveDate.html">"$LogArchiveDate"</a></p>"  "$HtmlDir"/index.html
    fi
    if  [  ! -f  "$WeekHtml" ] ;then
    	cp  "$HtmlTemplate"  "$WeekHtml" 
    	sed -i  "s/week/$LogArchiveDate/"   "$WeekHtml"
    fi
    
    for FDir in $(ls $ECLADirW)
    do
        find   "$ECLADirW"/"$FDir"  -type f  -iname  "*.pdf"  -exec basename {} \;| while  read  LogFile
           do
    	  StuName=$(echo  "$LogFile" |awk -F "-" '{print $2}')
    	  grep "$StuName"  "$WeekHtml" |grep  -q  "bkc" 
    	  if [ $?  -eq  0 ] ;then
    	      sed -i "/$StuName/s/<span class=\"bkc\">$FDir<\/span>/$FDir/" "$WeekHtml"
              fi
           done
    done
 }



if [ "$#" -eq 0 ] ; then
         currDate=$(date +%F)
         LogArchiveScript
else
         for  Date  in  $@
              do
# 判断日期的格式
                      echo  "$Date" | grep -q '^[0-9]\{4\}\-[0-9]\{1,2\}\-[0-9]\{1,2\}$'
                      if [ "$?" -ne 0 ] ;then
                           echo " $Date Form Error. use 2019-9-23"
                           continue
                      fi
                      currDate="$Date"
                      LogArchiveScript
              done
fi

