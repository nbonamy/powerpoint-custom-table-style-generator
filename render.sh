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

# usage
usage() {
	echo ""
	echo "Usage: $0 <ooxml-template>"
	echo ""
	echo "Options:"
	echo "  -h, --help         show help"
	echo "  -l, --light-mode   disable bold for 1st/last/total rows and cols (default is enabled)"
	echo "  -i, --inbdr-size   inside borders size (in points, default is ${insize})"
	echo "      --no-inbdr     disable inside borders styles (default is enabled)"
	echo "  -o, --outbdr-size  outside borders size (in points, default is ${outsize})"
	echo "      --no-outbdr    disable outside borders styles (default is enabled)"
	echo "  -b, --bdr-color    border color (default is current rendering color, has to be tx1/dk1/...)"
	echo "  -t, --tinting      alternate row tinting with current color: only/both/off (default is ${tinting})"
	echo "  -a, --alt-alpha    alternate row tinting colors transparency percentage (default is ${altalpha}%, 0 to disable banding)"
	echo "  -c, --alt-color    alternate row tinting color for tx1 rows (default is ${altdef})"
	echo "  -2, --tx2          enable tx2 based style rendering (default is off)"
	echo "  -x, --output       output mode. possible values are"
	echo "                       * echo (default)"
	echo "                       * copy for clipboard"
	echo "                       * filename of PPTX file to update in-place (make a backup first!)"
	echo ""
	echo "Example:"
	echo "  $0 --output=presentation.pptx -a 20 -l template.xml"
	exit 2
}

# check args
needs_arg() {
	if [ -z "$OPTARG" ]; then
		echo ""
		echo "Argument missing for --$o option";
		echo "Use --$o=... syntax";
		exit 2;
	fi
}

# parse arguments
while getopts "hlb:i:jo:pa:c:t:2x:-:" o; do
	if [ "$o" = "-" ]; then   # long option: reformulate OPT and OPTARG
    o="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$o}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"    # if long option argument, remove assigning `=`
  fi
	case "${o}" in
		h | help)
			usage
			;;
		l | light-mode)
			bold=false
			;;
    b | bdr-color)
			needs_arg
      border=${OPTARG}
      ;;
		i | inbdr-size)
			needs_arg
			insize=${OPTARG}
			;;
		no-inbdr)
			inside=false
			;;
		o | outbdr-size)
			needs_arg
			outsize=${OPTARG}
			;;
		no-outbdr)
			outside=false
			;;
		a | alt-alpha)
			needs_arg
			altalpha=${OPTARG}
			;;
		c | alt-color)
			needs_arg
			altdef=${OPTARG}
			;;
    t | tinting)
			needs_arg
      tinting=${OPTARG}
      ;;
		2 | tx2)
			tx2=tx2
			;;
		x | output)
			needs_arg
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
