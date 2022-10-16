#!/bin/bash
# set -e

function parse_userdir
{
	while [ $# != 0 ] ; do
		case $1 in
			-u | --userdir )
				USERDIR="${2}"
				shift
				;;
			-ah | --aurhelper | \
			-bs | --bootsize | \
			-cp | --cache-path | \
			-bp | --build-path | \
			-as | --apply-snapshot | \
			-hn | --hostname | \
			-i  | --image | \
			-is | --imgsize | \
			-v  | --subvolume | \
			-wp | --work-path | \
			-wa | --wifi-ap | \
			-wpw | --wifi-passwd | \
			-tn | --trusted-net | \
			-cp | --config-dir | \
			-gp | --gcode-dir ) \
				shift
				;;
			-4 | --ext4 | \
			-s | --snapshots | \
			-h | -? | --help )
				;;
			* )
				echo "Unknown option $1."
				show_help
				return 1
				;;
		esac
		shift
	done

	USERDIR="${USERDIR:-$SCRIPT_PATH/user}"
}


function parse_params
{
	while [ $# != 0 ] ; do
		case $1 in
			-4 | --ext4 )
				USE_EXT4=1
				;;
			-ah | --aurhelper )
				IMG="${2}"
				shift
				;;
			-bs | --bootsize )
				BOOTSIZE="${2}"
				shift
				;;
			-cp | --cache-path )
				CACHE="${2}"
				shift
				;;
			-bp | --build-path )
				BUILD_PATH="${2}"
				shift
				;;
			-hn | --hostname )
				TARGET_HOSTNAME="${2}"
				shift
				;;
			-i | --image )
				IMG="$2"
				shift
				;;
			-is | --imgsize )
				IMGSIZE="${2}"
				shift
				;;
			-u | --userdir )
				# already set in parse_userdir
				USERDIR="${2}"
				shift
				;;
			-v | --subvolume )
				SUBVOL="${2}"
				shift
				;;
			-wp | --work-path )
				WP="$2"
				shift
				;;
			-wa | --wifi-ap )
				WIFI_SSID="${2}"
				shift
				;;
			-wpw | --wifi-passwd )
				WIFI_PASSWD="${2}"
				shift
				;;
			-tn | --trusted-net )
				TRUSTED_NET="${2}"
				shift
				;;
			-as | --apply-snapshot )
				SNAPSHOT="${2}"
				CREATE_SNAPSHOTS=1
				shift
				;;
			-s | --snapshots )
				CREATE_SNAPSHOTS=1
				;;
			-cd | --config-dir )
				CONFIG_DIR="${2}"
				shift
				;;
			-gd | --gcode-dir )
				GCODE_DIR="${2}"
				shift
				;;
			-h | -? | --help)
				show_help
				return 1
				;;
			* )
				echo "Unknown option $1."
				show_help
				return 1
				;;
		esac
		shift
	done

	if [ "${SNAPSHOT}" ]; then
		CHECKPOINT=${SNAPSHOTS[${SNAPSHOT}]}
		if [ -z "${CHECKPOINT}" ]; then
			echo "Unkonwn snapshot to start from"
			return 1
		fi
	else
		CHECKPOINT=0
	fi

	export IMG="${IMG:-$SCRIPT_PATH/koa.img}"
	export WP="${WP:-$SCRIPT_PATH/target}"
	export CACHE="${CACHE:-$SCRIPT_PATH/cache}"
	export BUILD_PATH="${BUILD_PATH:-$SCRIPT_PATH/build}"
	export IMGSIZE="${IMGSIZE:-2400MiB}"
	export BOOTSIZE="${BOOTSIZE:-64MiB}"
	export TARGET_HOSTNAME="${TARGET_HOSTNAME:-koa}"
	export SUBVOL="${SUBVOL:-@koa_root}"
	export AURHELPER="${AURHELPER:-yay}"
	export SNAPSHOTDIR="${SNAPSHOTDIR:-$SCRIPT_PATH/snapshots}"
	export TARGET_USER="${TARGET_USER:-klipper}"
	export CONFIG_DIR="${CONFIG_DIR:-config}"
	export GCODE_DIR="${GCODE_DIR:-gcode-spool}"
	export WIFI_SSID="${WIFI_SSID:-}"
	export WIFI_PASSWD="${WIFI_PASSWD:-}"
	export TRUSTED_NET="${TRUSTED_NET:-}"

}


check_var ()
{
	if [ -z ${!1} ]; then
		echo "$1 has no value!"
		return 1
	fi
}


apply_secrets()
{
	if [ ! -f "${USERDIR}/secrets.sh" ]; then
		echo "Create user/secrets.sh to set WIFI_SSID and WIFI_PASSWD"
		return 1
	fi
	. "${USERDIR}/secrets.sh"
}


run_app_script()
{
	cat "${1}" | sudo chroot "${WP}" su -l "${TARGET_USER}" -c \
		"/bin/env \
		TRUSTED_NET=\"${TRUSTED_NET}\" \
		AURHELPER=\"${AURHELPER}\" \
		DEFAULT_UI=mainsail \
		TARGET_USER=\"${TARGET_USER}\" \
		BASE_PATH=\"/home/${TARGET_USER}\" \
		CONFIG_PATH=\"/home/${TARGET_USER}/${CONFIG_DIR}\" \
		GCODE_PATH=\"/home/${TARGET_USER}/${GCODE_DIR}\" \
		LOG_PATH=/tmp/klipper-logs \
		/bin/bash"
}


print_target_env()
{
	cat <<-EOF
		export TRUSTED_NET="${TRUSTED_NET}"
		export TARGET_USER="${TARGET_USER}"
		export BASE_PATH="/home/${TARGET_USER}"
		export CONFIG_PATH="\${BASE_PATH}/config"
		export GCODE_SPOOL="\${BASE_PATH}/gcode-spool"
		export LOG_PATH=/tmp/klipper-logs 
	EOF
}


show_environment()
{
	echo "-------------------------------------------------"
	echo "Image:       ${IMG}"
	echo "Image size:  ${IMGSIZE}"
	echo "Workdir:     ${WP}"
	echo "Cache:       ${CACHE}"
	echo "Builddir:    ${BUILD_PATH}"
	echo "Userdir:     ${USERDIR}"
	echo "Wifi SSID:   ${WIFI_SSID}"
	echo "Wifi passwd: ${WIFI_PASSWD}"
	echo "Hostname:    ${TARGET_HOSTNAME}"
	echo "Trusted net: ${TRUSTED_NET}"
	echo "Start from:  ${SNAPSHOT}"
	echo "-------------------------------------------------"
	echo
}


show_help()
{
	echo -e "Params: \n" \
		"	-u  | --user <arg>\n" \
		"	-ah | --aurhelper <arg>\n" \
		"	-bs | --bootsize <arg>\n" \
		"	-c  | --cachedir <arg>\n" \
		"	-bd | --builddir <arg>\n" \
		"	-as | --apply-snapshot <arg>\n" \
		"	-hn | --hostname <arg>\n" \
		"	-i  | --image <arg>\n" \
		"	-is | --imgsize <arg>\n" \
		"	-v  | --subvolume <arg>\n" \
		"	-wd | --workdir <arg>\n" \
		"	-wa | --wifi-ap <arg>\n" \
		"	-wp | --wifi-passwd <arg>\n" \
		"	-tn | --trusted-net <arg>\n" \
		"	-4  | --ext4\n" \
		"	-s  | --snapshots\n" \
		"	-h  | -? | --help"
}
