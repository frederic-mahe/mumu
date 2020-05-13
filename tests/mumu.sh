#!/bin/bash -

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit -1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## use the first mumu binary in $PATH by default, unless user wants
## to test another binary
MUMU=$(which mumu 2> /dev/null)
[[ "${1}" ]] && MUMU="${1}"

DESCRIPTION="check if mumu is executable"
[[ -x "${MUMU}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#                                  Interface                                  #
#                                                                             #
#*****************************************************************************#

## Print a header
SECTION_NAME="mumu: interface tests"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SECTION_NAME}}" "${SECTION_NAME}"


## ------------------------------------------------------------------ No option

## No option
DESCRIPTION="mumu aborts when no option is specified"
"${MUMU}" > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"


## ----------------------------------------------- options --version and --help

## GNU tools write help and version messages to stdout
for OPTION in "-h" "--help" "-v" "--version" ; do
    DESCRIPTION="${OPTION} writes to standard output"
    "${MUMU}" "${OPTION}" | grep -q "." && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done

## GNU tools write help and version messages to stdout, not to stderr
for OPTION in "-h" "--help" "-v" "--version" ; do
    DESCRIPTION="${OPTION} doesn't write to standard error"
    "${MUMU}" "${OPTION}" 2>&1 > /dev/null | grep -q "." && \
        failure "${DESCRIPTION}" || \
            success "${DESCRIPTION}"
done

## Return status should be 0 after -h and -v (GNU standards)
for OPTION in "-h" "--help" "-v" "--version" ; do
    DESCRIPTION="return status should be 0 after ${OPTION}"
    "${MUMU}" "${OPTION}" > /dev/null && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
done


## -------------------------------------------------------- mandatory arguments

## mumu stops with an error if no argument is given
DESCRIPTION="mumu stops with an error if no argument is given"
"${MUMU}" > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"

## mumu outputs a warning if an unknow option is passed
DESCRIPTION="mumu outputs a warning if an unknow option is passed"
"${MUMU}" \
    -z 2>&1 | \
    grep -q "^Warning: unknown option" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## mumu stops with an error if '--otu_table file' is missing
DESCRIPTION="mumu stops with an error if '--otu_table file' is missing"
"${MUMU}" 2>&1 | \
    grep -q "\-\-otu_table" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"

## mumu stops with an error if '--match_list file' is missing
DESCRIPTION="mumu stops with an error if '--match_list file' is missing"
OTU_TABLE=$(mktemp)
"${MUMU}" --otu_table "${OTU_TABLE}" 2>&1 | \
    grep -q "\-\-match_list" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}"

## mumu stops with an error if '--new_otu_table file' is missing
DESCRIPTION="mumu stops with an error if '--new_otu_table file' is missing"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
"${MUMU}" --otu_table "${OTU_TABLE}" --match_list "${MATCH_LIST}" 2>&1 | \
    grep -q "\-\-new_otu_table" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

## mumu stops with an error if '--log file' is missing
DESCRIPTION="mumu stops with an error if '--log file' is missing"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" 2>&1 | \
    grep -q "\-\-log" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}"

## mumu needs only four mandatory parameters
DESCRIPTION="mumu needs only four mandatory parameters"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts empty input files (no error)
DESCRIPTION="mumu accepts empty input files (no error)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu outputs a warning if input files can't be read
DESCRIPTION="mumu outputs a warning if input files can\'t be read (1)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
chmod -r "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 | \
    grep -q "^Warning:*read*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
chmod +r "${OTU_TABLE}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu outputs a warning if input files can't be read
DESCRIPTION="mumu outputs a warning if input files can\'t be read (2)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
chmod -r "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 | \
    grep -q "^Warning:*read*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
chmod +r "${MATCH_LIST}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu outputs a warning if input files are empty
DESCRIPTION="mumu outputs a warning if input files are empty"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 | \
    grep -q "^Warning:*empty*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu outputs a warning if output files can't be overwritten
DESCRIPTION="mumu outputs a warning if output files can\'t be overwritten (1)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
chmod -w "${NEW_OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 | \
    grep -q "^Warning:*overwritten*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
chmod +w "${NEW_OTU_TABLE}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu outputs a warning if output files can't be overwritten
DESCRIPTION="mumu outputs a warning if output files can\'t be overwritten (2)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
chmod -w "${LOG}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 | \
    grep -q "^Warning:*overwritten*" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
chmod +w "${LOG}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu clobbers output files
DESCRIPTION="mumu clobbers output files"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
echo "older data" > "${LOG}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
grep -q ".*" "${LOG}" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts duplicated parameters (last one is used)
DESCRIPTION="mumu needs only four mandatory parameters"
OTU_TABLE=$(mktemp)
OTU_TABLE2=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --otu_table "${OTU_TABLE2}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${OTU_TABLE2}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts the short options -o, -m, -n and -l
DESCRIPTION="mumu accepts the short options -o, -m, -n and -l"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    -o "${OTU_TABLE}" \
    -m "${MATCH_LIST}" \
    -n "${NEW_OTU_TABLE}" \
    -l "${LOG}" > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"


## --------------------------------------------------------- optional arguments

## mumu accepts optional parameters
DESCRIPTION="mumu accepts optional parameters"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_match 84.0 \
    --minimum_ratio_type min \
    --minimum_ratio 1.0 \
    --minimum_relative_cooccurence 0.95 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts optional parameters (short names)
DESCRIPTION="mumu accepts optional parameters (short names)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    -a 84.0 \
    -b min \
    -c 1.0 \
    -d 0.95 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu outputs a warning for unknown parameters (short)
DESCRIPTION="mumu outputs a warning for unknown parameters (short)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    -z 2>&1 | \
    grep -q "invalid" &&
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts minimum_match 50 <= x <= 100
DESCRIPTION="mumu accepts minimum_match 50 <= x <= 100"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_match 75.0 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu stops with an error if minimum_match < 50.0
DESCRIPTION="mumu stops with an error if minimum_match < 50.0"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_match 49.9 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu stops with an error if minimum_match > 100
DESCRIPTION="mumu stops with an error if minimum_match > 100"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_match 100.1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts minimum_ratio values greater than zero
DESCRIPTION="mumu accepts minimum_ratio values greater than zero"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_ratio 10 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu stops with an error if minimum_ratio = 0
DESCRIPTION="mumu stops with an error if minimum_ratio = zero"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_ratio 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts minimum_ratio_type min
DESCRIPTION="mumu accepts minimum_ratio_type min"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_ratio_type min > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts minimum_ratio_type avg
DESCRIPTION="mumu accepts minimum_ratio_type avg"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_ratio_type avg > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu stops with an error if minimum_ratio_type is not min or avg
DESCRIPTION="mumu stops with an error if minimum_ratio_type is not min or avg"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_ratio_type mvg > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts minimum_relative_cooccurence values
DESCRIPTION="mumu accepts minimum_relative_cooccurence values"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_relative_cooccurence 0.5 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu stops with an error if minimum_relative_cooccurence is null
DESCRIPTION="mumu stops with an error if minimum_relative_cooccurence = zero"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_relative_cooccurence 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu stops with an error if minimum_relative_cooccurence is greater than 1
DESCRIPTION="mumu stops with an error if minimum_relative_cooccurence > 1"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --minimum_relative_cooccurence 1.1 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts thread values
DESCRIPTION="mumu accepts thread values"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --threads 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts thread values (short)
DESCRIPTION="mumu accepts thread values (short)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    -t 1 > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu refuses null thread value
DESCRIPTION="mumu refuses null thread value"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --threads 0 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu refuses high thread value
DESCRIPTION="mumu refuses high thread value"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --threads 256 > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"


#*****************************************************************************#
#                                                                             #
#                               Functionality                                 #
#                                                                             #
#*****************************************************************************#

## Print a header
SECTION_NAME="mumu: functionality tests"
LINE=$(printf "%076s\n" | tr " " "-")
printf "# %s %s\n" "${LINE:${#SECTION_NAME}}" "${SECTION_NAME}"

## toy-example:

# OTUs	s1	s2	s3
# A	1	5	10
# B	0	2	4

# A	B	96.5
# B	A	96.5

## mumu merges OTUs A and B as expected with default parameters
DESCRIPTION="mumu merges OTUs A and B as expected with default parameters (output 1 OTU)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk 'END {exit NR == 2 ? 0 : 1}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu merges OTUs A and B as expected with default parameters (log is 1 line)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk 'END {exit NR == 1 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"


## ------------------------------------------------------------------- log file

## log file has 18 columns
DESCRIPTION="mumu log file has 18 columns"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk 'END {exit NF == 18 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## log column 1 is the name of the query OTU
DESCRIPTION="mumu log column 1 is the name of the query"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $1 == "B" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 2 is the name of the potental parent"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $2 == "A" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 3 is the percentage of similarity"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $3 == 96.5 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 4 is total abundance of the query"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $4 == 6 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 5 is total abundance of the potential parent"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $5 == 16 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 6 is overlap abundance of the query"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $6 == 6 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 7 is overlap abundance of the potential parent"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $7 == 15 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 8 is the incidence of the query"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $8 == 2 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 9 is the incidence of the potential parent"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $9 == 3 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 10 is the overlap incidence"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\nB\t0\t2\t4\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $10 == 2 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"



# what happens if we have only one OTU (empty match list)? output OTU
# to new_OTU, mumu should be transparent for empty files or datasets
# without any parent OTU.


exit 0
