#!/bin/sh
. /tmp/loader

if [ -z "$1" -a -n "$REMOTE_ADDR" ]; then
	eval $( _http query_string_sanitize )		# ACTION=... MAC=... IP_USER=... HASH=... // ( TUNNEL_ID=... | IP_ROUTER=$REMOTE_ADDR )
	_http header_mimetype_output "text/plain"
else
	ACTION="$1"
fi

_log do tunnel_helper daemon info "ACTION: $ACTION QUERY: $QUERY_STRING"

case "$ACTION" in
	tunnel_possible)
		if _tunnel check_local_capable ; then

			_watch counter "/tmp/tunnel_id" increment 1 max 65 || {		# fixme! set to 0 during nightly/kick_user_all()
				echo "FALSE=;"
				exit
			}
			read TUNNEL_ID <"/tmp/tunnel_id"

	#		eval $( _tunnel get_speed_for_hash "$HASH" "$MAC" )
			SPEED_UPLOAD="32"
			SPEED_DOWNLOAD="256"

			echo -n "TRUE=;"
			echo -n "SPEED_UPLOAD=$SPEED_UPLOAD;"
			echo -n "SPEED_DOWNLOAD=$SPEED_DOWNLOAD;"
			echo -n "TUNNEL_IP_CLIENT=$( _tunnel id2ip $TUNNEL_ID client );"
			echo -n "TUNNEL_IP_SERVER=$( _tunnel id2ip $TUNNEL_ID server );"
			echo    "TUNNEL_MASK=30;"

			_tunnel config_insert_new_client "$TUNNEL_ID" "$MAC" "$IP_USER" "$SPEED_UPLOAD" "$SPEED_DOWNLOAD"
			_tunnel config_rebuild     >"/tmp/tunnel/vtun_server.conf"
			_tunnel daemon_apply_config "/tmp/tunnel/vtun_server.conf"
		else
			echo "FALSE=;"
		fi
	;;
	*)
		echo "FALSE=;"
	;;
esac
