#!/bin/bash
# libparser.sh -- command parser for miyoko's shellbot

# include chat and channel management libraries and hook generator
. include/libchat.sh
. include/libchannel.sh

parse () {
	send_nick=$(echo ${@} | awk '{print $1}' | sed -e 's/://;s/!/ /')
	send_host=$(echo ${@} | awk '{print $1}' | sed -e 's/://;s/@/ /')
	recv_chan=$(echo ${@} | awk '{print $3}')
	send_nick=$(echo "$send_nick" | awk '{print $1}')
	send_host=$(echo "$send_host" | awk '{print $2}')
	command=$(echo ${@} | awk '{print $2}')
	dest=$(echo ${@} | awk '{print $3}')
	if [ $command == "PRIVMSG" ] ; then
		text=${@:4}
		cmd=$(echo "$text" | awk '{print $1}')
		cmd=${cmd#:}
		if [ $(echo "$cmd" | cut -b 1-4) == "^raw" ] ; then
			if [ $send_host == $user_host ] ; then
				echo "${text#* }" >> etc/core_input
			else
				notice $send_nick Unauthorized access.
			fi
		fi
		if [ $(echo "$cmd" | cut -b 1-6) == "^shell" ] ; then
			rm etc/core_shell
			touch etc/core_shell
			if [ $send_host == $user_host ] ; then
				echo "$(eval ${text#* })" > etc/core_shell 2> etc/core_shell
				while read core_shell; do
					msg $dest $core_shell
				done < etc/core_shell
			else
				notice $send_nick Unauthorized access.
			fi
		fi
		if [ $(echo $cmd | cut -b 1-9) == "^shutdown" ] ; then
			if [ "$send_host" == "$user_host" ] ; then
				echo "QUIT" >> etc/core_input
				procname=$(echo "$0" | sed -e 's/\.\///;s/*\///')
				killall -TERM $procname
			else
				notice $send_nick Unauthorized access.
			fi
		fi
		if [ $(echo $cmd | cut -b 1-5) == "^join" ] ; then
			chan=$(echo $text | awk '{print $2}')
			join $chan
			unset chan
		fi
		if [ $(echo $cmd | cut -b 1-5) == "^part" ] ; then
			chan=$(echo $text | awk '{print $2}')
			part $chan
			unset chan
		fi
		if [ $(echo $cmd | cut -b 1-6) == "^cycle" ] ; then
			chan=$(echo $text | awk '{print $2}')
			cycle $chan
			unset chan
		fi
		if [ $(echo $cmd | cut -b 1-5) == "^kick" ] ; then
			knick=$(echo $text | awk '{print $2}')
			kick $recv_chan $knick
			unset knick
		fi
		if [ $(echo $cmd | cut -b 1-7) == "^uptime" ] ; then
			uptime=$(expr $(date +%s) - $boottime)
			msg $dest I have been running for $uptime seconds
			unset uptime
		fi

		insert_hooks
                . include/libctcp.sh
	fi
}