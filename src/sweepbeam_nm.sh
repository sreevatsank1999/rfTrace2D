#!/bin/bash

HQZ_PATH="../lib/zenphoton/hqz/build/hqz"
SCENEFILE_PATH=""
OUTDIR_PATH="../build/images/"
OUTFILE_PREFIX="Scenario"

SWEEP_SS_MIN=0
SWEEP_SS_MAX=360
nbSector=12
BeamWidth_AP=30


SWEEP_AP_MIN=0
SWEEP_AP_MAX=360
nbSector=12
BeamWidth_SS=30


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
    echo "usage: ./sweepbeam_nm <config_filepath> [<min_angle1> <min_angle2> <max_angle1> <max_angle2> <beamwidth1> <beamwidth2> <nbSector>] [OPTIONS]"
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
                            SWEEP_AP_MIN=$key
                            SWEEP_SS_MIN=$1
                            shift
                            ;;
                        1)
                            SWEEP_AP_MAX=$key
                            SWEEP_SS_MAX=$1
                            shift
                            ;;
                        2)
                            BeamWidth_AP=$key
                            BeamWidth_SS=$1
                            shift
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
    echo "SWEEP_AP_MIN: ${SWEEP_AP_MIN}"
    echo "SWEEP_AP_MAX: ${SWEEP_AP_MAX}"
    echo "BeamWidth_AP: ${BeamWidth_AP}"
    echo "nbSector: ${nbSector}"
    echo " "
    echo "SWEEP_SS_MIN: ${SWEEP_SS_MIN}"
    echo "SWEEP_SS_MAX: ${SWEEP_SS_MAX}"
    echo "BeamWidth_SS: ${BeamWidth_SS}"
    echo "nbSector: ${nbSector}"
}


parse_args $@ 
print_param

SweepTot_AP=$(math "(${SWEEP_AP_MAX})-(${SWEEP_AP_MIN})")
AngleInc_AP=$(math "(${SweepTot_AP})/${nbSector}")

SweepTot_SS=$(math "(${SWEEP_SS_MAX})-(${SWEEP_SS_MIN})")
AngleInc_SS=$(math "(${SweepTot_SS})/${nbSector}")

echo "SweepTot_AP: ${SweepTot_AP}"
echo "AngleInc_AP: ${AngleInc_AP}"
echo " "
echo "SweepTot_SS: ${SweepTot_SS}"
echo "AngleInc_SS: ${AngleInc_SS}"


for si in $(seq 0 $(math "${nbSector}-1"))
do 
    echo "Tracing Sector ${si} ..."
    SECTOR_HPBW_AP_MIN=$(math "(${SWEEP_AP_MIN})+$si*${AngleInc_AP}-0.5*${BeamWidth_AP}")
    SECTOR_HPBW_AP_MAX=$(math "(${SECTOR_HPBW_AP_MIN})+${BeamWidth_AP}")
    SECTOR_FNBW_AP_MIN=$(math "(${SWEEP_AP_MIN})+$si*${AngleInc_AP}-0.65*${BeamWidth_AP}")
    SECTOR_FNBW_AP_MAX=$(math "(${SECTOR_FNBW_AP_MIN})+1.3*${BeamWidth_AP}")
    
    SECTOR_HPBW_SS_MIN=$(math "(${SWEEP_SS_MIN})+$si*${AngleInc_SS}-0.5*${BeamWidth_SS}")
    SECTOR_HPBW_SS_MAX=$(math "(${SECTOR_HPBW_SS_MIN})+${BeamWidth_SS}")
    SECTOR_FNBW_SS_MIN=$(math "(${SWEEP_SS_MIN})+$si*${AngleInc_SS}-0.65*${BeamWidth_SS}")
    SECTOR_FNBW_SS_MAX=$(math "(${SECTOR_FNBW_SS_MIN})+1.3*${BeamWidth_SS}")

    echo "SECTOR_HPBW_AP_MIN: ${SECTOR_HPBW_AP_MIN}"
    echo "SECTOR_HPBW_AP_MAX: ${SECTOR_HPBW_AP_MAX}"
    echo "SECTOR_FNBW_AP_MIN: ${SECTOR_FNBW_AP_MIN}"
    echo "SECTOR_FNBW_AP_MAX: ${SECTOR_FNBW_AP_MAX}"
    echo " "
    echo "SECTOR_HPBW_SS_MIN: ${SECTOR_HPBW_SS_MIN}"
    echo "SECTOR_HPBW_SS_MAX: ${SECTOR_HPBW_SS_MAX}"
    echo "SECTOR_FNBW_SS_MIN: ${SECTOR_FNBW_SS_MIN}"
    echo "SECTOR_FNBW_SS_MAX: ${SECTOR_FNBW_SS_MAX}"


    OUTFILE_NAME="${OUTFILE_PREFIX}_AP${SWEEP_AP_MIN}-${SWEEP_AP_MAX}_SS${SWEEP_SS_MIN}-${SWEEP_SS_MAX}_${nbSector}_${si}.png"
    cat "${SCENEFILE_PATH}"  | jq -c ".lights[0][5]=[${SECTOR_HPBW_AP_MIN}, ${SECTOR_HPBW_AP_MAX}]" | jq -c ".lights[1][5]=[${SECTOR_FNBW_AP_MIN}, ${SECTOR_FNBW_AP_MAX}]" | jq -c ".lights[2][5]=[${SECTOR_HPBW_SS_MIN}, ${SECTOR_HPBW_SS_MAX}]" | jq -c ".lights[3][5]=[${SECTOR_FNBW_SS_MIN}, ${SECTOR_FNBW_SS_MAX}]" |./"${HQZ_PATH}" - "${OUTDIR_PATH}/${OUTFILE_NAME}"
    echo "Sector ${si} trace complete"
    echo " "
done