#!/bin/bash

#------- default settings -------

#Set the height and width of the terminal
HEIGHT=46
WIDTH=100
#Set to 'ppt' to set the height/width of the terminal in % of screen height/width
#Set to 'px' to set the height/width of the terminal in pixels
HEIGHT_UNIT='ppt'
WIDTH_UNIT='ppt'

#Set a gap between the terminal and a side of the screen
HORIZONTAL_GAP=5
VERTICAL_GAP=2.4
#Set to 'left' or 'right' to set where the horizontal gap should be calculated from
#Set to 'top' or 'bottom' to set where the vertical gap should be calculated from
HORIZONTAL_GAP_FROM='left'
VERTICAL_GAP_FROM='bottom'
#Set to 'ppt' to set the gap in % of screen height/width
#Set to 'px' to set the gap in pixels
HORIZONTAL_GAP_UNIT='px'
VERTICAL_GAP_UNIT='ppt'

#Set to true if you want the terminal to pop up on the screen nearest to the center
#	of the currently focused window
#Set to false if you want the terminal to pop up on the screen where the cursor is
#If there is no focused window, the cursor position will be used as a fallback
USE_WINDOW_FOCUS=false

#Set the float precision in decimal places
PRECISION=3

#!------ default settings ------!



#------- argument parsing -------
GLOB=false
if [[ $(shopt extglob | awk '{print $2}') == 'on' ]]; then
		GLOB=true
fi

case $GLOB in
		(false) shopt -s extglob;;
esac

die() { echo -e "$*" 1>&2 ; exit 1; }

SIZE_REGEX='^[0-9]+(\.[0-9]+)?(ppt|px)$'
validate_size() {
		VALID=false
		[[ "$1" =~ $SIZE_REGEX ]] && VALID=true
}

validate_hgap() {
		VALID=false
		[[ "$1" =~ ^(left|right)${SIZE_REGEX:1} ]] && VALID=true
}

validate_vgap() {
		VALID=false
		[[ "$1" =~ ^(top|bottom)${SIZE_REGEX:1} ]] && VALID=true
}

HELP_STR="To override the default settings provide arguments.
For the size and gap there are 2 units available: ppt and px
Use 'ppt' to set the size/gap in % of the monitor width
Use 'px' to set the size/gap in pixels

----------------- SIZE -----------------
-w | --width    Set the width of the scratchpad
                Example: --width 99.4ppt
                Default value: 100ppt

-h | height     Set the height of the scratchpad
                Example: --height 46.7ppt
                Default value: 46ppt


----------------- GAPS -----------------
Set gaps between the scratchpad and the edges of the monitor
-n | hgap       Set the horizontal gap either from the left or the right edge of the monitor
                Example: --hgap left10.3ppt
                Default value: left0ppt

-v | vgap       Set the vertical gap either from the top or the bottom edge of the monitor
                Example: --vgap bottom3.2ppt
                Default value: bottom2.4ppt

----------------- OTHER -----------------
-f | --use-window-focus     Use this option to show the scratchpad on the monitor where the
                            currently focused window takes up the most space
                            Omit this option to show the scratchpad on the monitor where
                            the cursor is
                            Default: option is activated

------------ SPECIAL OPTIONS ------------
When providing a special option, kno other options are required

--help                      Shows this help text

-c | --print-cache          This options boosts the scripts performance. Use this if you
                            notice  a delay between running the script and the scratchpad
                            showing. This option prints information that the script
                            obtains through expensive commands. Put the output into the
                            environment variable 'SP_CACHE', then the script skips the
                            expensive commands and reads the cache instead.
                            NOTE: Everytime your screen layout changes, you need to set
                            'SP_CACHE' again. This includes changes in resolution, changes
                            in connected monitors and changes in the position of the
                            monitors in the screen space."

init_screen() {
	#monitors string should have a line for each monitor that looks like this:
	# "offsetx offsety width height"
	#offsetx and offsety is the position of the monitor in the whole screen space
	MONITORS=$(xrandr --listactivemonitors | tail -n +2 | awk '{print $3}' | awk -F'[/x+]' '{print $5,$6,$1,$3}')
	#get size of the whole screen space
	#(smallest rectangle that fits all monitors in current configuration)
	#(width, height)
	readarray -d " " -t screen < <(xrandr | head -n 1 | grep -oP "(?<=current )\d* x \d*" | awk '{printf $1 " " $3}')

	CACHE="$MONITORS\n${screen[*]}"
}


while :; do
		# Extract from argument in form of <from><num><unit>
		# 	for example: left11.4px becomes
		# 	from=left
		# 	num=11.4
		# 	unit=px
		from=${2//[0-9.]*}
		num=${2//[A-z]}
		unit=${2//*[0-9.]}
		case $1 in
				-s|--selector)
						if [ "$2" ]; then
								SELECTOR=$2
						else
								die "ERROR: \"--selector\" requires an argument, see the i3 docs for possible selectors\nExample: \"instance=<your-instance>\""
						fi;;
				-w|--width)
						validate_size "$2"
						if [ "$VALID" ]; then
							WIDTH=${num}
							WIDTH_UNIT=${unit}
							shift
						else
							die 'ERROR: "--width" requires an argument in the form of <number><unit>\nExample: --width 99.6ppt\nUnits: ppt/px'
						fi;;
				-h|--height)
						validate_size "$2"
						if [ "$VALID" ]; then
							HEIGHT=${num}
							HEIGHT_UNIT=${unit}
							shift
						else
							die 'ERROR: "--height" requires an argument in the form of <number><unit>\nExample: --height 46.3ppt\nUnits: ppt/px'
						fi;;
				-n|--hgap)
						validate_hgap "$2"
						if [ "$VALID" ]; then
							HORIZONTAL_GAP=${num}
							HORIZONTAL_GAP_FROM=${from}
							HORIZONTAL_GAP_UNIT=${unit}
							shift
						else
							die 'ERROR: "--hgap requires an argument in the form of <side><number><unit>\nExample: --hgap 3.4ppt\nUnits: ppt/px'
						fi;;
				-v|--vgap)
						validate_vgap "$2"
						if [ "$VALID" ]; then
							VERTICAL_GAP=${num}
							VERTICAL_GAP_FROM=${from}
							VERTICAL_GAP_UNIT=${unit}
							shift
						else
							die 'ERROR: "--vgap requires an argument in the form of <side><number><unit>\nExample: --vgap 3.4ppt\nUnits: ppt/px'
						fi;;
				-f|--use-window-focus)
						USE_WINDOW_FOCUS=true;;
				-c|--print-cache)
						init_screen
						echo -e "$CACHE"
						exit 0;;
				--help)
						echo "$HELP_STR"
						exit 0;;
				-?*)
						die "ERROR: No such option as \"$1\"\nTo show help use the --help option";;
				*)
						break
		esac
		shift
done

if [ -z ${SELECTOR+x} ]; then
		die "ERROR: No \"--selector\" argument provided\nSee the i3 docs for possible values\nExample: \"--selector 'instance=<your-instance>\""
fi

if [ -n "$SP_CACHE" ]; then
		MONITORS=$(echo -e "$SP_CACHE" | head -n 2)
		readarray -d " " screen <<< "$(echo -e "$SP_CACHE" | tail -n 1)"
else
		init_screen
fi

transform_float() {
		if [ "$1" = "0" ]; then
				RESULT=$1
				return 0
		fi
		local decimal_places diff_to_precision
		decimal_places="${1#*.}"
		if (( ${#decimal_places} == ${#1} )); then
				decimal_places=""
		fi
		# remove comma
		RESULT="${1/.}"
		# calc the diff to PRECISION setting
		# the resulting int is the number of decimal places to add to the result
		diff_to_precision=$((PRECISION - ${#decimal_places}))
		if (( diff_to_precision < 0 )); then
				RESULT="${RESULT::diff_to_precision}"
		else
				istr=""
				for (( i=0; i<diff_to_precision; i++ )); do
						istr+="$i"
						RESULT+='0'
				done
		fi
}

transform_float "$WIDTH"
WIDTH=$RESULT
transform_float "$HEIGHT"
HEIGHT=$RESULT
transform_float "$HORIZONTAL_GAP"
HORIZONTAL_GAP=$RESULT
transform_float "$VERTICAL_GAP"
VERTICAL_GAP=$RESULT
						
case $GLOB in
		(false) shopt -u extglob;;
esac
#!------ argument parsing ------!


#------- spawning scratchpad -------

#convert monitors to array
readarray -t MONITORS <<< "$MONITORS"

monitor_count=${#MONITORS[@]}

set_origin_mouse() {
		local mouse_position_str mouse_pos
		mouse_position_str="$(xdotool getmouselocation --shell)"
		readarray mouse_pos <<< "$(echo "$mouse_position_str" | awk -F'[=]' '{print $2}')"
		ORIGIN_X=${mouse_pos[0]}
		ORIGIN_Y=${mouse_pos[1]}
}

set_origin_window() {
		#result string should look like this: (value on right side)
		# X=x
		# Y=y
		# WIDTH=width
		# HEIGHT=height
		local active_window_str active_window
		active_window_str="$(xdotool getactivewindow getwindowgeometry --shell | tail -n +2 | head -n 4)"
		
		#result array should look like this:
		# [x, y, width, height]
		readarray active_window <<< "$(echo "$active_window_str" | awk -F'[=]' '{print $2}')"
		
		if (( ${#active_window[@]} != 4 )); then
				set_origin_mouse
				return 0
		fi
	
		active_window_center_x=$((active_window[0] + active_window[2] / 2))
		active_window_center_y=$((active_window[1] + active_window[3] / 2))

	
		ORIGIN_X=$active_window_center_x
		ORIGIN_Y=$active_window_center_y
}

if $USE_WINDOW_FOCUS; then
		set_origin_window
else
		set_origin_mouse
fi

FLOAT_PRECISION_MULT=$((10 ** PRECISION));

MONITORS_FLAT=()

#this function creates a monitor array in this form:
# (offsetx, offsety, width, height, biggestx, biggesty)
# or in other words:
# (leftx, topy, width, height, rightx, bottomy)
# For multiple monitors, these values repeat: use modulo to access a specific monitors values
create_monitor_arr() {
		readarray -d " " -t monitor < <(printf '%s' "${MONITORS[$1]}") #append biggest x and y coordinate of this monitor
	monitor+=($((monitor[0] + monitor[2])) $((monitor[1] + monitor[3])))
	MONITORS_FLAT+=("${monitor[0]}" "${monitor[1]}" "${monitor[2]}" "${monitor[3]}" "${monitor[4]}" "${monitor[5]}")
}

for (( i=0; i<monitor_count; i++ )); do
		create_monitor_arr $i
done

ONE_HALF=$((FLOAT_PRECISION_MULT / 2))

#Finds the monitor closest to the ORIGIN
nearest_monitor() {
		local nearest_c nearest_monitor i
		nearest_c=999999999
		for (( i=0; i<monitor_count; i++ )); do
				local m_left_x m_top_y m_right_x m_bottom_y dx dy
				m_left_x="${MONITORS_FLAT[$i * 6]}"
				m_top_y="${MONITORS_FLAT[$i * 6 + 1]}"
				m_right_x="${MONITORS_FLAT[$i * 6 + 4]}"
				m_bottom_y="${MONITORS_FLAT[$i * 6 + 5]}"

				if (( ORIGIN_X < m_left_x )); then
						dx=$(( m_left_x - ORIGIN_X ))
				elif (( ORIGIN_X >= m_right_x )); then
						dx=$(( ORIGIN_X - m_right_x ))
				else
						dx=0
				fi
				if (( ORIGIN_Y < m_top_y )); then
						dy=$(( m_top_y - ORIGIN_Y ))
				elif (( ORIGIN_Y >= m_bottom_y )); then
						dy=$(( ORIGIN_Y - m_bottom_y ))
				else
						dy=0
				fi
				dx=$((dx * 100))
				dy=$((dy * 100))
				local a2plusb2 dc
				a2plusb2=$(( dx ** 2 + dy ** 2 ))
				dc=$(bc <<< "sqrt($a2plusb2)")
				if (( dc < nearest_c )); then
						nearest_c=$dc
						nearest_monitor=$i
				fi
		done
		RESULT=$nearest_monitor
}


nearest_monitor
NEAREST_MONITOR=$RESULT

for (( i=0; i<monitor_count; i++ ))
do
		M_LEFT_X="${MONITORS_FLAT[$i * 6]}"
		M_TOP_Y="${MONITORS_FLAT[$i * 6 + 1]}"
		M_WIDTH="${MONITORS_FLAT[$i * 6 + 2]}"
		M_HEIGHT="${MONITORS_FLAT[$i * 6 + 3]}"
		M_RIGHT_X="${MONITORS_FLAT[$i * 6 + 4]}"
		M_BOTTOM_Y="${MONITORS_FLAT[$i * 6 + 5]}"

		M_LEFT_X_F="$((M_LEFT_X * FLOAT_PRECISION_MULT))";
		M_TOP_Y_F="$((M_TOP_Y * FLOAT_PRECISION_MULT))";
		M_WIDTH_F="$((M_WIDTH * FLOAT_PRECISION_MULT))";
		M_HEIGHT_F="$((M_HEIGHT * FLOAT_PRECISION_MULT))";
		M_RIGHT_X_F="$((M_RIGHT_X * FLOAT_PRECISION_MULT))";
		M_BOTTOM_Y_F="$((M_BOTTOM_Y * FLOAT_PRECISION_MULT))";

		if (( i == NEAREST_MONITOR )); then
				 if [[ "$HORIZONTAL_GAP_UNIT" == 'ppt' ]]; then
						 X_OFFSET=$((M_WIDTH_F * HORIZONTAL_GAP / 100 / FLOAT_PRECISION_MULT))
				 else
						 X_OFFSET=$HORIZONTAL_GAP
				 fi
				 if [[ "$VERTICAL_GAP_UNIT" == 'ppt' ]]; then
						 Y_OFFSET=$((M_HEIGHT_F * VERTICAL_GAP / 100 / FLOAT_PRECISION_MULT))
				 else
						 Y_OFFSET=$VERTICAL_GAP
				 fi

				 if [[ "$WIDTH_UNIT" == 'ppt' ]]; then
						 WIDTH_PX=$((M_WIDTH_F * WIDTH / 100 / FLOAT_PRECISION_MULT))
				 else
						 WIDTH_PX=$WIDTH
				 fi
				 if [[ "$HEIGHT_UNIT" == 'ppt' ]]; then
						 HEIGHT_PX=$((M_HEIGHT_F * HEIGHT / 100 / FLOAT_PRECISION_MULT))
				 else
						 HEIGHT_PX=$HEIGHT
				 fi

				 if [[ "$HORIZONTAL_GAP_FROM" == 'left' ]]; then
						 X=$((M_LEFT_X_F + X_OFFSET + ONE_HALF))
				 else
						 X=$((M_RIGHT_X_F - WIDTH_PX - X_OFFSET + ONE_HALF))
				 fi
				 if [[ "$VERTICAL_GAP_FROM" == 'top' ]]; then
						 #round to int
						 Y=$((M_TOP_Y_F + Y_OFFSET + ONE_HALF))
				 else
						 #round to int
						 Y=$((M_BOTTOM_Y_F - HEIGHT_PX - Y_OFFSET + ONE_HALF))
				 fi


				 X=$((X / FLOAT_PRECISION_MULT))
				 Y=$((Y / FLOAT_PRECISION_MULT))
				 WIDTH=$((WIDTH / FLOAT_PRECISION_MULT))
				 HEIGHT=$((HEIGHT / FLOAT_PRECISION_MULT))
				 WIDTH_PX=$((WIDTH_PX / FLOAT_PRECISION_MULT))
				 HEIGHT_PX=$((HEIGHT_PX / FLOAT_PRECISION_MULT))

				 printf %s "i3-msg output: "
                 i3-msg ["$SELECTOR"] scratchpad show, resize set $WIDTH_PX px $HEIGHT_PX px, move position $X px $Y px
		fi
done
#!------ spawning scratchpad ------!
