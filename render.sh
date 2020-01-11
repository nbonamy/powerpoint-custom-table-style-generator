#!/bin/bash

# defaults
inside=true
insize=0.25
outside=true
outsize=2.25
border=\'\'
tinting=both
altdef=tx1
altalpha=10
tx2=

usage() {
	echo "Usage: $0 filename"
	echo "Options:"
	echo "  -h show help"
	echo "  -i inside borders size (in points, default is ${insize})"
	echo "  -j disable inside borders styles (default is ${inside})"
	echo "  -o outside borders size (in points, default is ${outsize})"
	echo "  -p disable outside borders styles (default is ${outside})"
	echo "  -b border color (default is current rendering color, has to be tx1/dk1/...)"
	echo "  -t alternate row tinting with current color: only/both/off (default is ${tinting})"
	echo "  -a alternate row tinting colors transparency (percentage, default is ${altalpha}%, 0 to disable banding)"
	echo "  -c alternate row tinting color for tx1 rows (default is ${altdef})"
	echo "  -2 enable tx2 based style rendering (default is off)"
	echo "  -x output result instead of sending to clipboard"
	exit 1
}

# check if pbcopy exists
if hash pbcopy 2>/dev/null; then
	output=pbcopy
else
	output=cat
fi

# parse arguments
while getopts "hb:i:jo:pa:c:t:2x" o; do
  case "${o}" in
		h)
			usage
			;;
    b)
      border=${OPTARG}
      ;;
		i)
			insize=${OPTARG}
			;;
		j)
			inside=false
			;;
		o)
			outsize=${OPTARG}
			;;
		p)
			outside=false
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

# data source, start with border color
ds=$(mktemp)
echo "borderColor: ${border}" > ${ds}

# inner
echo "innerBorder:" >> ${ds}
echo "  enable: ${inside}" >> ${ds}
echo "  size: ${insize}" >> ${ds}
echo "outerBorder:" >> ${ds}
echo "  enable: ${outside}" >> ${ds}
echo "  size: ${outsize}" >> ${ds}

# alternate will force tinting
if [ "$altalpha" == "0" ]; then
	tinting=off
fi

# tinting
echo "tinting: ${tinting}" >> ${ds}

# color names
names=$(echo "tx1 ${tx2} accent1 accent2 accent3 accent4 accent5 accent6" | sed 's/  / /g')

# colors
echo "colors: ${names}" >> ${ds}
echo "names: ${names}" >> ${ds}
echo "altDefault: ${altdef}" >> ${ds}
echo "altAlpha: ${altalpha}" >> ${ds}

# do it
#cat ${ds}
gomplate -d data=file://${ds}?type=application/yaml -f ${template} | sed '/^[[:space:]]*$/d' | ${output}
rm ${ds}

# done
if [ "$output" != "cat" ]; then
	echo "Done!"
fi
