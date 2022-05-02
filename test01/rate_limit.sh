#!/bin/bash

# Confirm temp files not exist
if [ -f tmp_output_full.txt ] ; then
	rm tmp_output_full.txt
fi
if [ -f tmp_input.txt ] ; then
	rm tmp_input.txt
fi

# Getting bash input 
INPUT=$1

# function for getting ip address from temp input file
get_ipaddress(){
	awk '{ print $1 }' | uniq
}
# function for getting timestamp from temp input file
get_timestamp(){
	awk '{ print $4,$5 }' | sed 's/[][]//g;s/\// /g;s/:/ /' | xargs -I {} date '+%s' -d {} 
}
# function for getting ip list from input file
get_iplist(){
	awk '{ print $1 }' | sort -u
}
# function for generating count-timestamp file for condition 1,2
parse_file(){
	cat $FILE 2> /dev/null | get_timestamp | uniq -c > tmp_stat.txt
}
# function for generating count-timestamp file for condition 3
parse_login_file(){
        cat $FILE 2> /dev/null | grep "login" | get_timestamp | uniq -c > tmp_login_stat.txt
}

# main function to process the temp input file
process_file(){
	# confirm temp file non exist
	if [ -f tmp_output.txt ] ; then
		rm tmp_output.txt
	fi
	if [ -f tmp_stat.txt ] ; then
		rm tmp_stat.txt
	fi
	if [ -f tmp_login_stat.txt ] ; then
		rm tmp_login_stat.txt
	fi
	if [ -f tmp_output_sort.txt ] ; then
		rm tmp_output_sort.txt
	fi

	# generating files for condition 1-3
	parse_file
	parse_login_file

	# getting current input file ip address
	IP=$( cat ${FILE} 2> /dev/null | get_ipaddress )
	
	# default vars for condition 1-2
	SUM1=0
	DUR1=0
	ARRTIME1=()
	ARRCOUNT1=()
	SUM2=0
	DUR2=0
	ARRTIME2=()
	ARRCOUNT2=()

	# Read each line of access log
	while read COUNT TIMESTAMP ; do
		ARRCOUNT1+=(${COUNT})
		ARRTIME1+=(${TIMESTAMP})
		ARRCOUNT2+=(${COUNT})
		ARRTIME2+=(${TIMESTAMP})
	
		# while loop to process the calculation within time condition
		CON1=0
		while : ; do
			# sum of requests
			SUM1=$(IFS=+; echo "$((${ARRCOUNT1[*]}))")
			
			# if it is the first request
			if [ -z ${ARRTIME1[0]} ] ; then
				DUR1=0
			else # calculate duration
				DUR1=$(( ${TIMESTAMP}-${ARRTIME1[0]} ))
			fi
	
			if [ ${DUR1} -le 60 ] ; then
				# if match condition
				if [ ${SUM1} -ge 40 ] ; then
					RELEASETIME=$(( ${TIMESTAMP}+601 ))
					echo "${TIMESTAMP} ${SUM1} BAN1 ${RELEASETIME} ${IP}" >> tmp_output.txt
					unset RELEASETIME
				fi	
				CON1=1
			else # if time duration longer than condition
				ARRCOUNT1=("${ARRCOUNT1[@]:1}")
			        ARRTIME1=("${ARRTIME1[@]:1}")
			fi
			# break the while loop if matched time constraint
			if [ ${CON1} -ne 0 ]; then
				break
			fi
		done
		
		# while loop to process the calculation within time condition
		CON2=0
		while : ; do
			# sum of requests
	                SUM2=$(IFS=+; echo "$((${ARRCOUNT2[*]}))")

			# if it is the first request
			if [ -z ${ARRTIME2[0]} ] ; then
				DUR2=0
			else # calculate duration
				DUR2=$(( ${TIMESTAMP}-${ARRTIME2[0]} ))
			fi
	
	                if [ ${DUR2} -le 600 ] ; then
				# if match condition
	                        if [ ${SUM2} -ge 100 ] ; then
					RELEASETIME=$(( ${TIMESTAMP}+3601 ))
	                                echo "${TIMESTAMP} ${SUM2} BAN2 ${RELEASETIME} ${IP}" >> tmp_output.txt
					unset RELEASETIME
	                        fi
	                        CON2=1
	                else # if time duration longer than condition
	                        ARRCOUNT2=("${ARRCOUNT2[@]:1}")
	                        ARRTIME2=("${ARRTIME2[@]:1}")
	                fi
			# break the while loop if matched time constraint
	                if [ ${CON2} -ne 0 ]; then
	                        break
	                fi
	        done
	done < tmp_stat.txt	
	unset COUNT TIMESTAMP
	
	
	SUM3=0
	DUR3=0
	ARRTIME3=()
	ARRCOUNT3=()
	while read COUNT TIMESTAMP ; do
		# while loop to process the calculation within time condition
		CON3=0
		while : ; do
			# sum of requests
			SUM3=$(IFS=+; echo "$((${ARRCOUNT3[*]}))")

			# if it is the first request
			if [ -z ${ARRTIME3[0]} ] ; then
				DUR3=0
			else # calculate duration
				DUR3=$(( ${TIMESTAMP}-${ARRTIME3[0]} ))
			fi
			if [ ${DUR3} -le 600 ] ; then
				# if match condition
				if [ ${SUM3} -ge 20 ] ; then
					RELEASETIME=$(( ${TIMESTAMP}+7201 ))
					echo "${TIMESTAMP} ${SUM3} BAN3 ${RELEASETIME} ${IP}" >> tmp_output.txt
					
					unset RELEASETIME
				fi	
				CON3=1
				
			else # if time duration longer than condition
				ARRCOUNT3=("${ARRCOUNT3[@]:1}")
			        ARRTIME3=("${ARRTIME3[@]:1}")
			fi
			# break the while loop if matched time constraint
			if [ ${CON3} -ne 0 ]; then
				break
			fi
		done
		ARRCOUNT3+=(${COUNT})
		ARRTIME3+=(${TIMESTAMP})
	done < tmp_login_stat.txt	
	unset COUNT TIMESTAMP
	
	# if there is output , sort and process the BAN action calculation
	if [ -f tmp_output.txt ] ; then
		cat tmp_output.txt | sort -n > tmp_output_sort.txt
		BANNED=0
	        RELEASEUNTIL=0
	        COUNTLINENUM=$( cat tmp_output_sort.txt | wc -l )
	        COUNTLINE=0
	        while read TIMESTAMP SUM BAN RELEASETIME IP; do
			# if non-ban, then ban it
	                if [ ${BANNED} -eq 0 ] ; then
	                        BANNED=1
	                        echo "${TIMESTAMP},BAN,${IP}" >> tmp_output_full.txt
	                        RELEASEUNTIL=${RELEASETIME}
	                else
				# if exceed releasetime 
	                        if [ ${RELEASEUNTIL} -lt ${TIMESTAMP} ] ; then
	                                echo "${RELEASEUNTIL},UNBAN,${IP}" >> tmp_output_full.txt
	                                BANNED=0
	                        else # not reached releasetime, keep ban and extend releasetime
	                                RELEASEUNTIL=${RELEASETIME}
	                        fi
	                fi
	                COUNTLINE=$(( ${COUNTLINE}+1 ))
			# if it is the last line of record
	                if [ ${COUNTLINE} -eq ${COUNTLINENUM} ] && [ ${BANNED} -eq 1 ] ; then
	                        echo "${RELEASEUNTIL},UNBAN,${IP}" >> tmp_output_full.txt
	                fi
	        done < tmp_output_sort.txt
	fi
	
	# clean up the env
	if [ -f tmp_output.txt ] ; then
		rm tmp_output.txt
	fi
	if [ -f tmp_stat.txt ] ; then
		rm tmp_stat.txt
	fi
	if [ -f tmp_login_stat.txt ] ; then
		rm tmp_login_stat.txt
	fi
	if [ -f tmp_output_sort.txt ] ; then
		rm tmp_output_sort.txt
	fi
} 

# main

# Get ip list
IPLIST=$( cat $INPUT | get_iplist )
for I in ${IPLIST} ; do
	grep $I $INPUT > tmp_input.txt
	FILE=tmp_input.txt
	process_file
done

# output the sorted list 
cat tmp_output_full.txt | sort -nk 1

# clean up the env
if [ -f tmp_output_full.txt ] ; then
	rm tmp_output_full.txt
fi
if [ -f tmp_input.txt ] ; then
        rm tmp_input.txt
fi



