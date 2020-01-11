#!/bin/bash

# defaults
inside=true
insize=0.25
outside=true
outsize=2.25
border=\'\'
tinting=both
altdef=tx1
altalpha=15
bold=true
output=echo
tx2=

usage() {
	echo ""
	echo "Usage: $0 <ooxml-template>"
	echo ""
	echo "Options:"
	echo "  -h show help"
	echo "  -l disable bold for 1st/last/total rows and cols (default is enabled)"
	echo "  -i inside borders size (in points, default is ${insize})"
	echo "  -j disable inside borders styles (default is enabled)"
	echo "  -o outside borders size (in points, default is ${outsize})"
	echo "  -p disable outside borders styles (default is enabled)"
	echo "  -b border color (default is current rendering color, has to be tx1/dk1/...)"
	echo "  -t alternate row tinting with current color: only/both/off (default is ${tinting})"
	echo "  -a alternate row tinting colors transparency percentage (default is ${altalpha}%, 0 to disable banding)"
	echo "  -c alternate row tinting color for tx1 rows (default is ${altdef})"
	echo "  -2 enable tx2 based style rendering (default is off)"
	echo "  -x output mode. possible values are"
	echo "     * echo (default)"
	echo "     * copy for clipboard"
	echo "     * filename of PPTX file to update in-place (make a backup first!)"
	echo ""
	echo "Example:"
	echo "  $0 -x presentation.pptx -a 20 -l template.xml"
	exit 1
}

# parse arguments
while getopts "hlb:i:jo:pa:c:t:2x:" o; do
  case "${o}" in
		h)
			usage
			;;
		l)
			bold=false
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
			output=${OPTARG}
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

# check
if [ "${output}" != "echo" ] && [ "${output}" != "copy" ]; then
	if [ ! -f "${output}" ]; then
		echo "File ${output} does not exist!"
		exit 1
	fi
fi

# data source
ds=$(mktemp)
: > ${ds}
echo "bold: ${bold}" >> ${ds}
echo "borderColor: ${border}" >> ${ds}

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
xml=$(gomplate -d data=file://${ds}?type=application/yaml -f ${template} | sed '/^[[:space:]]*$/d')
rm ${ds}

# check clipboard
if [ "${output}" == "copy" ]; then
	if ! hash pbcopy 2>/dev/null; then
		output=echo
	fi
fi

# output
if [ "${output}" == "echo" ]; then
	echo "${xml}"
elif [ "${output}" == "copy" ]; then
	echo "${xml}" | pbcopy
	echo "Content copied to clipboard!"
else
	tmp=$(mktemp -d)
	output=$(realpath "${output}")
	unzip -q -d ${tmp} "${output}"
	echo "${xml}" > ${tmp}/ppt/tableStyles.xml
	cd ${tmp}
	zip -q -f -r "${output}" *
	cd - > /dev/null
	rm -rf ${tmp}
	echo "Done!"
fi
