#!/bin/bash

usage() {
	echo "Usage: $0 filename"
	echo "Options:"
	echo "  -h show help"
	echo "  -b borderColor (default is current rendering color)"
	echo "  -i inside borders size"
	echo "  -o outside borders size"
	echo "  -a alternate row colors transparency (percentage, default is 10%, 0 to disable banding)"
	echo "  -c alternate row tinting default color (default is tx1)"
	echo "  -t alternate row tinting with current color: only/both/off (default is both)"
	echo "  -2 enable tx2 rendering (default is off)"
	echo "  -x output result instead of sending to clipboard"
	exit 1
}

# defaults
inside=3175
outside=28575
output=pbcopy
border=\'\'
tinting=both
altdef=tx1
altalpha=10
tx2=

# parse arguments
while getopts "hb:i:o:a:c:t:2x" o; do
  case "${o}" in
		h)
			usage
			;;
    b)
      border=${OPTARG}
      ;;
		i)
			inside=${OPTARG}
			;;
		o)
			outside=${OPTARG}
			;;
		a)
			altalpha=${OPTARG}
			;;
		c)
			altdef=${OPTARG}
			;;
    t)
      tinting=${OPTARG}
      ;;
		2)
			tx2=tx2
			;;
		x)
			output=cat
			;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

# parameters
template=$1
if [ -z "${template}" ]; then
	usage
fi

# data source, start with border
ds=$(mktemp)
echo "borderColor: ${border}" > ${ds}
echo "innerBorder: ${inside}" >> ${ds}
echo "outerBorder: ${outside}" >> ${ds}

# alternate will force tinting
if [ "$altalpha" == "0" ]; then
	tinting=off
fi

# tinting
if [ "$tinting" == "both" ]; then
	echo "tinting: 1 0" >> ${ds}
elif [ "$tinting" == "only" ]; then
	echo "tinting: 1" >> ${ds}
elif  [ "$tinting" == "off" ]; then
	echo "tinting: 0" >> ${ds}
fi

# color names
names=$(echo "tx1 ${tx2} accent1 accent2 accent3 accent4 accent5 accent6" | sed 's/  / /g')

# colors
echo "colors: ${names}" >> ${ds}
echo "names: ${names}" >> ${ds}
echo "altdefault: ${altdef}" >> ${ds}
echo "altalpha: ${altalpha}" >> ${ds}

# do it
#cat ${ds}
gomplate -d data=file://${ds}?type=application/yaml -f ${template} | sed '/^[[:space:]]*$/d' | ${output}
rm ${ds}
echo "Done!"

