#!/bin/bash

HQZ_PATH="../lib/zenphoton/hqz/build/hqz"
SCENEFILE_PATH=""
OUTDIR_PATH="../build/images/"
OUTFILE_PREFIX="Scenario"

SWEEP_MIN=0
SWEEP_MAX=360
nbSector=12


math(){
    echo "$*" | bc -l
}
round() {
    printf "%.${2:-0}f" "$1"
}
##############################################################################
is_num() {
    case ${1#[-+]} in 
        ''|.|*[!0-9.]*|*.*.*)
            return 1
            ;; 
    esac
}

print_help(){
    echo "usage: ./sweepbeam <config_filepath> [<min_angle> <max_angle> <beamwidth> <nbSector>] [OPTIONS]"
    echo " "
    echo "    -p, --out-prefix <prefix>: Output file prefix"
    echo "    -o, --out-dir  <out_path>: Output directory"
    echo "    -b, --hqz-path  <binary_path> : Path to HQZ binary"
    echo "    -h, --help  : Print help"
}
invalid(){
    echo "Invalid argument: $1"
    print_help
    exit 1
}
insufficient_args(){
    echo "Insufficient number of arguments"
    print_help
    exit 1
}

parse_args() {

    if [[ $# < 1 ]]
    then
        insufficient_args
    fi

    SCENEFILE_PATH="$1"
    shift

    optargc=0
    while [[ $# > 0 ]]
    do
        key="$1"
        shift

        case $key in
            -b|--hqz-path)
                HQZ_PATH="$1"
                shift
                ;;
            -o|--outdir)
                OUTDIR_PATH="$1"
                shift
                ;;
            -p|--out-prefix)
                OUTFILE_PREFIX="$1"
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                is_num $key
                if [[ $? == 0 ]]
                then
                    case $optargc in
                        0)
                            SWEEP_MIN=$key
                            ;;
                        1)
                            SWEEP_MAX=$key
                            ;;
                        2)
                            BeamWidth=$key
                            ;;
                        3)
                            nbSector=$key
                            ;;
                        *)
                            invalid $key
                    esac
                    optargc=$(math "${optargc}+1")
                else
                    invalid $key
                fi
        esac
    done
}
################################################################################

print_param(){
    echo "Parameters: "
    echo "HQZ_PATH: ${HQZ_PATH}"
    echo "SCENEFILE_PATH: ${SCENEFILE_PATH}"
    echo "OUTDIR_PATH: ${OUTDIR_PATH}"
    echo "OUTFILE_PREFIX: ${OUTFILE_PREFIX}"
    echo " "
    echo "SWEEP_MIN: ${SWEEP_MIN}"
    echo "SWEEP_MAX: ${SWEEP_MAX}"
    echo "BeamWidth: ${BeamWidth}"
    echo "nbSector: ${nbSector}"
}


parse_args $@ 
print_param

SweepTot=$(math "(${SWEEP_MAX})-(${SWEEP_MIN})")
AngleInc=$(math "(${SweepTot})/${nbSector}")

for si in $(seq 0 $(math "${nbSector}-1"))
do 
    echo "Tracing Sector ${si} ..."
    SECTOR_HPBW_MIN=$(math "${SWEEP_MIN}+$si*${AngleInc}-0.5*${BeamWidth}")
    SECTOR_HPBW_MAX=$(math "${SECTOR_HPBW_MIN}+${BeamWidth}")
    SECTOR_FNBW_MIN=$(math "${SWEEP_MIN}+$si*${AngleInc}-0.65*${BeamWidth}")
    SECTOR_FNBW_MAX=$(math "${SECTOR_FNBW_MIN}+1.3*${BeamWidth}")

    OUTFILE_NAME="${OUTFILE_PREFIX}_${SWEEP_MIN}-${SWEEP_MAX}_${nbSector}_${si}.png"
    cat "${SCENEFILE_PATH}"  | jq -c ".lights[0][5]=[${SECTOR_HPBW_MIN}, ${SECTOR_HPBW_MAX}]" | jq -c ".lights[1][5]=[${SECTOR_FNBW_MIN}, ${SECTOR_FNBW_MAX}]" | jq -c ".lights[2][5]=[${SECTOR_HPBW_MIN}, ${SECTOR_HPBW_MAX}]" | jq -c ".lights[3][5]=[${SECTOR_FNBW_MIN}, ${SECTOR_FNBW_MAX}]" |./"${HQZ_PATH}" - "${OUTDIR_PATH}/${OUTFILE_NAME}"
    echo "Sector ${si} trace complete"
    echo " "
done