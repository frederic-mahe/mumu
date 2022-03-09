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
[[ "${1}" ]] && MUMU="$(readlink -f "${1}")"

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

## mumu rejects a file with a name starting with a dash (POSIX
## requires to accept them!)
DESCRIPTION="mumu rejects a file with a name starting with a dash"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG="-mylog.log"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log -- "${LOG}" > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" -- "${LOG}"

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

## some user (root, sudo) can bypass all permission settings, making
## these tests pointless
if grep -q -v "sudo" <(groups $(whoami)) ; then

    ## mumu stops with an error if input files can't be read
    DESCRIPTION="mumu stops with an error if input files can\'t be read (1)"
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
        grep -q "^Error:" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    chmod +r "${OTU_TABLE}"
    rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

    ## mumu stops with an error if input files can't be read
    DESCRIPTION="mumu stops with an error if input files can\'t be read (2)"
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
        grep -q "^Error:" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    chmod +r "${MATCH_LIST}"
    rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

    ## mumu stops with an error if output files can't be overwritten
    DESCRIPTION="mumu stops with an error if output files can\'t be overwritten (1)"
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
        grep -q "^Error:" && \
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
        grep -q "^Error:" && \
        success "${DESCRIPTION}" || \
            failure "${DESCRIPTION}"
    chmod +w "${LOG}"
    rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"
fi

## mumu can write to the null device
DESCRIPTION="mumu can write to the null device"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

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
DESCRIPTION="mumu accepts duplicated parameters (last one is used)"
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
    grep -qE "invalid|unrecognized" &&
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

DESCRIPTION="mumu accepts thread values (2)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" \
    --threads 2 > /dev/null 2>&1 && \
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
DESCRIPTION="mumu refuses high thread value (255 threads max)"
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

## mumu stops with an error if the OTU table is not properly formatted
DESCRIPTION="mumu stops with an error if the OTU table has a variable number of columns"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "OTUs\ts1\nA\t5\nB\t\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

DESCRIPTION="mumu stops with an error message if the OTU table has a variable number of columns"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "OTUs\ts1\nA\t5\nB\t\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null 2>&1 > /dev/null | \
    grep -q "^Error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

DESCRIPTION="mumu stops with an error if the OTU table has a non-numerical value (NA)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "OTUs\ts1\nA\t5\nB\tNA\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null 2>&1 > /dev/null | \
    grep -q "^Error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

## mumu stops with an error if the match list is not properly formatted
DESCRIPTION="mumu stops with an error if the match list > 3 columns"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "A\tB\t96.5\nB\tA\t96.5\textra\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

DESCRIPTION="mumu stops with an error message if the match list > 3 columns"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "A\tB\t96.5\nB\tA\t96.5\textra\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null 2>&1 > /dev/null | \
    grep -q "^Error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

DESCRIPTION="mumu stops with an error if the match list similarity is empty"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "A\tB\t\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null 2>&1 > /dev/null | \
    grep -q "^Error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

DESCRIPTION="mumu stops with an error if the match list has a non-numerical value (NA)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
printf "A\tB\tNA\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null 2>&1 > /dev/null | \
    grep -q "^Error" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}"

DESCRIPTION="mumu can read from a substitution process"
MATCH_LIST=$(mktemp)
"${MUMU}" \
    --otu_table <(printf "OTUs\ts1\nA\t2\nB\t1\n") \
    --match_list "${MATCH_LIST}" \
    --new_otu_table /dev/null \
    --log /dev/null 2>&1 > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${MATCH_LIST}"

DESCRIPTION="mumu can write to a substitution process"
"${MUMU}" \
    --otu_table <(printf "OTUs\ts1\nA\t2\nB\t1\n") \
    --match_list /dev/null \
    --log /dev/null \
    --new_otu_table >(grep -q "." && \
                          success "${DESCRIPTION}" || \
                              failure "${DESCRIPTION}") \
    > /dev/null

# read from named pipes: not possible because mumu opens input files twice
# DESCRIPTION="mumu can read from named pipes"
# rm fifo_OTU_TABLE
# mkfifo fifo_OTU_TABLE

# "${MUMU}" \
#     --otu_table fifo_OTU_TABLE \
#     --match_list /dev/null \
#     --log /dev/null \
#     --new_otu_table /dev/stdout &

# printf "OTUs\ts1\nA\t2\nB\t1\n" > fifo_OTU_TABLE
# rm fifo_OTU_TABLE


# match can be a subset of table, but not the other way around.
DESCRIPTION="mumu skips match entries that are not in the OTU table"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t2\nB\t1\n" > "${OTU_TABLE}"
printf "A\tC\t96.5\nC\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

# extra entries should be discarded and not be present in the new OTU table
DESCRIPTION="mumu skips match entries that are not in the OTU table (not in output table)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t2\nB\t1\n" > "${OTU_TABLE}"
printf "A\tC\t96.5\nC\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
grep -oq "C" "${NEW_OTU_TABLE}" && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu warns about match entries that are not in the OTU table (warning)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t2\nB\t1\n" > "${OTU_TABLE}"
printf "A\tC\t96.5\nC\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2> /dev/null | \
    grep -q "^warning: " && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
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

## mumu accepts empty input files
DESCRIPTION="mumu accepts empty input files"
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

DESCRIPTION="mumu accepts empty input files and creates empty output files (OTU table)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
[[ -e "${NEW_OTU_TABLE}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu accepts empty input files and creates empty output files (log file)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
[[ -e "${LOG}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu accepts input with a single OTU (empty match list)
DESCRIPTION="mumu accepts input with a single OTU (empty match list)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1 && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu accepts input with a single OTU (output to new OTU table)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
diff --brief "${OTU_TABLE}" "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu accepts input with a single OTU (log is empty)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\ts3\nA\t1\t5\t10\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
[[ -s "${LOG}" ]] && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu accepts duplicated sample names"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts1\ts1\nA\t1\t5\t10\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu stops with an error if an OTU name appears more than once"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t1\nA\t10\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1 && \
    failure "${DESCRIPTION}" || \
        success "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

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

## mumu match orientation matters (good orientation, merge)
DESCRIPTION="mumu match orientation matters (A > B, good orientation)"
"${MUMU}" \
    --otu_table <(printf "OTUs\ts1\nA\t2\nB\t1\n") \
    --match_list <(printf "B\tA\t99.0\n") \
    --new_otu_table >(awk 'END {exit NR == 2 ? 0 : 1}' && \
                          success "${DESCRIPTION}" || \
                              failure "${DESCRIPTION}") \
    --log /dev/null > /dev/null

## mumu match orientation matters (wrong orientation, no merge)
DESCRIPTION="mumu match orientation matters (A > B, wrong orientation)"
"${MUMU}" \
    --otu_table <(printf "OTUs\ts1\nA\t2\nB\t1\n") \
    --match_list <(printf "A\tB\t99.0\n") \
    --new_otu_table >(awk 'END {exit NR == 3 ? 0 : 1}' && \
                          success "${DESCRIPTION}" || \
                              failure "${DESCRIPTION}") \
    --log /dev/null > /dev/null

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

# mumu can find the root of chained merges (A <- B <- C)
DESCRIPTION="mumu can find the root of chained merges"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t5\nB\t2\nC\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\nB\tC\t96.5\nC\tB\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null
awk '{if (NR > 1) {exit ($1 == "A" && $2 == 8) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## OTUs with the same abundance are not merged
# A son cannot be as abundant as its father (to avoid circular linking
# among OTUs of the same abundance).
# expect OTU table with three lines
DESCRIPTION="mumu OTUs with the same abundance are not merged"
"${MUMU}" \
    --otu_table <(printf "OTUs\ts1\nA\t1\nB\t1\n") \
    --match_list <(printf "A\tB\t99.0\nB\tA\t99.0\n") \
    --new_otu_table >(awk ' END {exit NR == 3 ? 0 : 1}' && \
                          success "${DESCRIPTION}" || \
                              failure "${DESCRIPTION}") \
    --log /dev/null > /dev/null

# merged OTUs are sorted by decreasing abundance (B 5 reads, then A with 4 reads)
## input
# OTUs	s1
# A	4
# B	3
# C	2
#
## expect
# OTUs	s1
# B	5
# A	4
#
DESCRIPTION="mumu sorts merged OTUs by decreasing abundance"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t4\nB\t3\nC\t2\n" > "${OTU_TABLE}"
printf "B\tC\t96.5\nC\tB\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 5) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## abundance is the same, spread (B > A)
## input
# OTUs	s1	s2
# A	2	0
# B	1	1
#
## expect
# OTUs	s1	s2
# B	1	1
# A	2	0
#
DESCRIPTION="mumu sorts merged OTUs by decreasing abundance, then by spread (B > A)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t0\nB\t1\t1\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 1 && $3 == 1) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## abundance is the same, spread (A > B)
## input
# OTUs	s1	s2
# A	1	1
# B	2	0
#
## expect
# OTUs	s1	s2
# A	1	1
# B	2	0
#
DESCRIPTION="mumu sorts merged OTUs by decreasing abundance, then by spread (A > B)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t1\t1\nB\t2\t0\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "A" && $2 == 1 && $3 == 1) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## abundance is the same, spread is the same, ASCIIbetical order
## input
# OTUs	s1
# a	1
# B	1
#
## expect
# OTUs	s1
# B	1
# a	1
#
DESCRIPTION="mumu sorts merged OTUs by decreasing abundance, then by spread, then by ASCIIbetical order ('B' before 'a')"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\na\t1\nB\t1\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null
awk '{if (NR == 6) {exit ($1 == "a" && $2 == 1) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## it is ok to sort a vector containing only one OTU
DESCRIPTION="mumu accepts to sort when there is only one OTU"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t1\n" > "${OTU_TABLE}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" 2>&1 > /dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## reject match if...
# if ((parameters.minimum_ratio_type == use_minimum_value and
#      stats.smallest_non_null_ratio <= parameters.minimum_ratio)
#     or (parameters.minimum_ratio_type == use_average_value and
#         stats.avg_non_null_ratio <= parameters.minimum_ratio)) {
#
## the second part is never computed with the current tests
#
DESCRIPTION="mumu rejects parent when using 'avg' minimum ratio"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
printf "OTUs\ts1\nA\t3\nB\t2\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/stdout | \
    grep -oq "rejected$" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to A or B (same abundance values, but different similarity values):
# A	C	95
# B	C	98
#
# expect C to be merged with B
# OTUs	s1
# B	4
# A	3
#
DESCRIPTION="mumu sorts matches by decreasing similarities when searching for a parent (input A before B)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t3\nB\t3\nC\t1\n" > "${OTU_TABLE}"
printf "A\tC\t95.0\nC\tA\t95.0\nB\tC\t98.0\nC\tB\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 4) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to A or B (same abundance values, but different similarity values):
# B	C	98
# A	C	95
#
# expect C to be merged with B
# OTUs	s1
# B	4
# A	3
#
DESCRIPTION="mumu sorts matches by decreasing similarities when searching for a parent (input B before A)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t3\nB\t3\nC\t1\n" > "${OTU_TABLE}"
printf "B\tC\t98.0\nC\tB\t98.0\nA\tC\t95.0\nC\tA\t95.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 4) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"


## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to A or B (same similarity, different abundance values):
# A	C	98
# B	C	98
#
# expect C to be merged with B
# OTUs	s1
# B	4
# A	3
#
DESCRIPTION="mumu sorts matches by decreasing abundance when searching for a parent (input A before B)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t2\nB\t3\nC\t1\n" > "${OTU_TABLE}"
printf "A\tC\t98.0\nC\tA\t98.0\nB\tC\t98.0\nC\tB\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 4) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to A or B (same similarity, different abundance values):
# B	C	98
# A	C	98
#
# expect C to be merged with B
# OTUs	s1
# B	4
# A	3
#
DESCRIPTION="mumu sorts matches by decreasing abundance when searching for a parent (input B before A)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t2\nB\t3\nC\t1\n" > "${OTU_TABLE}"
printf "B\tC\t98.0\nC\tB\t98.0\nA\tC\t98.0\nC\tA\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 4) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to A or B (same similarity, same abundance value, but different spread):
# A	C	98
# B	C	98
#
# OTUs	s1	s2
# A	3	0
# B	2	1
# C	1	0
#
# expect C to be merged with B
# OTUs	s1	s2
# B	3	1
# A	3	0
#
DESCRIPTION="mumu sorts matches by decreasing spread when searching for a parent (input A before B)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t3\t0\nB\t2\t1\nC\t1\t0\n" > "${OTU_TABLE}"
printf "A\tC\t98.0\nC\tA\t98.0\nB\tC\t98.0\nC\tB\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 3 && $3 == 1) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to A or B (same similarity, same abundance value, but different spread):
# B	C	98
# A	C	98
#
# OTUs	s1	s2
# A	3	0
# B	2	1
# C	1	0
#
# expect C to be merged with B
# OTUs	s1	s2
# B	3	1
# A	3	0
#
DESCRIPTION="mumu sorts matches by decreasing spread when searching for a parent (input B before A)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t3\t0\nB\t2\t1\nC\t1\t0\n" > "${OTU_TABLE}"
printf "B\tC\t98.0\nC\tB\t98.0\nA\tC\t98.0\nC\tA\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "B" && $2 == 3 && $3 == 1) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to a or A (same similarity, same abundance value, same spread):
# a	C	98
# A	C	98
#
# OTUs	s1
# a	3
# A	3
# C	1
#
# expect C to be merged with A
# OTUs	s1
# A	4
# a	3
#
DESCRIPTION="mumu sorts matches by ASCIIbetical order when searching for a parent (input a before A)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\na\t3\nA\t3\nC\t1\n" > "${OTU_TABLE}"
printf "a\tC\t98.0\nC\ta\t98.0\nA\tC\t98.0\nC\tA\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "A" && $2 == 4) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## when there are several matches, sort them by similarity, abundance, spread, names
#
# C can be linked to a or A (same similarity, same abundance value, same spread):
# A	C	98
# a	C	98
#
# OTUs	s1
# a	3
# A	3
# C	1
#
# expect C to be merged with A
# OTUs	s1
# A	4
# a	3
#
DESCRIPTION="mumu sorts matches by ASCIIbetical order when searching for a parent (input A before a)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\na\t3\nA\t3\nC\t1\n" > "${OTU_TABLE}"
printf "A\tC\t98.0\nC\tA\t98.0\na\tC\t98.0\nC\ta\t98.0\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --minimum_ratio_type "avg" \
    --minimum_ratio 1.5 \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log /dev/null 2>&1 > /dev/null
awk '{if (NR == 2) {exit ($1 == "A" && $2 == 4) ? 0 : 1}}' "${NEW_OTU_TABLE}" && \
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

awk '{exit $3 == "96.50" ? 0 : 1}' "${LOG}" && \
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

DESCRIPTION="mumu log column 11 is the minimum ratio value (#1)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t10\nB\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $11 == "10.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 11 is the minimum ratio value (#2)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t10\t0\nB\t0\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $11 == "0.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 12 is the sum of abundance ratios"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t1\t0\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $12 == "1.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 13 is the average value of abundance ratios (integer)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t0\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $13 == 1 ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 13 is the average value of abundance ratios (non-integer)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t3\t0\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $13 == "1.50" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 13 is the average value of abundance ratios (non-integer, < 1)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t1\nB\t0\t2\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $13 == "0.50" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 13 is the average value of abundance ratios (= 0.0)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t0\nB\t0\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $13 == "0.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 14 is the minimal non-null abundance ratio"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t1\t0\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $14 == "1.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 15 is the average value of non-null abundance ratios"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t1\t0\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $15 == "1.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 16 is the largest ratio value"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t1\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $16 == "2.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 17 is the relative co-occurence value"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t1\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $17 == "1.00" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 18 is the status (accepted)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t2\nB\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $18 == "accepted" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu log column 18 is the status (rejected)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\ts2\nA\t2\t1\nB\t1\t1\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit $18 == "rejected" ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

DESCRIPTION="mumu orders input OTUs by abundance (B > A)"
OTU_TABLE=$(mktemp)
MATCH_LIST=$(mktemp)
NEW_OTU_TABLE=$(mktemp)
LOG=$(mktemp)
printf "OTUs\ts1\nA\t1\nB\t2\n" > "${OTU_TABLE}"
printf "A\tB\t96.5\nB\tA\t96.5\n" > "${MATCH_LIST}"
"${MUMU}" \
    --otu_table "${OTU_TABLE}" \
    --match_list "${MATCH_LIST}" \
    --new_otu_table "${NEW_OTU_TABLE}" \
    --log "${LOG}" > /dev/null 2>&1
awk '{exit ($1 == "A" && $2 == "B") ? 0 : 1}' "${LOG}" && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
rm -f "${OTU_TABLE}" "${MATCH_LIST}" "${NEW_OTU_TABLE}" "${LOG}"

## mumu allows parent to be missing in some samples (lulu bug)

# Here 'A' is missing from the first sample. The relative cooccurence
# is then 20/21, which is greater than 0.95, the default value. 'A' is
# then accepted as the parent of 'B'. In lulu, there is no merging (to
# be confirmed with a test on the latest version).

DESCRIPTION="mumu allows parent to be missing in some samples (lulu bug)"
"${MUMU}" \
    --otu_table <(printf "OTUs\ts01\ts02\ts03\ts04\ts05\ts06\ts07\ts08\ts09\ts10\ts11\ts12\ts13\ts14\ts15\ts16\ts17\ts18\ts19\ts20\ts21\nA\t0\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\t9\nB\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\t1\n") \
    --match_list <(printf "B\tA\t99.0\n") \
    --log /dev/null \
    --new_otu_table >(awk 'END {exit NR == 2 ? 0 : 1}' && \
                          success "${DESCRIPTION}" || \
                              failure "${DESCRIPTION}") > /dev/null

wait

exit 0

## TODO:
# - list all the reasons to reject a potential parent! Make a test for each.
# - try two OTUs without overlap, do I get infinite values? make a list of values that are set to null, report that in the manual.
