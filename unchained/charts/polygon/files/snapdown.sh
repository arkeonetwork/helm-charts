#!/bin/bash

function validate_network() {
  if [[ "$1" != "mainnet" && "$1" != "mumbai" ]]; then
    echo "Invalid network input. Please enter 'mainnet' or 'mumbai'."
    exit 1
  fi
}

function validate_client() {
  if [[ "$1" != "heimdall" && "$1" != "bor" && "$1" != "erigon" ]]; then
    echo "Invalid client input. Please enter 'heimdall' or 'bor' or 'erigon'."
    exit 1
  fi
}

function validate_checksum() {
  if [[ "$1" != "true" && "$1" != "false" ]]; then
    echo "Invalid checksum input. Please enter 'true' or 'false'."
    exit 1
  fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -n | --network)
      validate_network "$2"
      network="$2"
      shift # past argument
      shift # past value
      ;;
    -c | --client)
      validate_client "$2"
      client="$2"
      shift # past argument
      shift # past value
      ;;
    -d | --extract-dir)
      extract_dir="$2"
      shift # past argument
      shift # past value
      ;;
    -v | --validate-checksum)
      validate_checksum "$2"
      checksum="$2"
      shift # past argument
      shift # past value
      ;;
    *) # unknown option
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set default values if not provided through command-line arguments
network=${network:-mainnet}
client=${client:-heimdall}
extract_dir=${extract_dir:-"${client}_extract"}
checksum=${checksum:-false}


# install dependencies and cursor to extract directory
mkdir -p "$extract_dir"
cd "$extract_dir"

# download compiled incremental snapshot files list
aria2c -x6 -s6 "https://snapshot-download.polygon.technology/$client-$network-parts.txt"

# remove hash lines if user declines checksum verification
if [ "$checksum" == "false" ]; then
    sed -i '/checksum/d' $client-$network-parts.txt
fi

# download all incremental files, includes automatic checksum verification per increment
aria2c -c -x6 -s6 -k1024M -i $client-$network-parts.txt

echo "downloaded" 

declare -A processed_dates

# Join bulk parts into valid tar.zst and extract
for file in $(find . -name "$client-$network-snapshot-bulk-*-part-*" -print | sort); do
    date_stamp=$(echo "$file" | grep -o 'snapshot-.*-part' | sed 's/snapshot-\(.*\)-part/\1/')

    # Check if we have already processed this date
    if [[ -z "${processed_dates[$date_stamp]}" ]]; then
        processed_dates[$date_stamp]=1
        output_tar="$client-$network-snapshot-${date_stamp}.tar.zst"
        echo "Join parts for ${date_stamp} then extract"
        cat $client-$network-snapshot-${date_stamp}-part* > "$output_tar"
        rm $client-$network-snapshot-${date_stamp}-part*
        pv $output_tar | tar -I zstd -xf - -C . && rm $output_tar
    fi
done

# Join incremental following day parts
for file in $(find . -name "$client-$network-snapshot-*-part-*" -print | sort); do
    date_stamp=$(echo "$file" | grep -o 'snapshot-.*-part' | sed 's/snapshot-\(.*\)-part/\1/')

    # Check if we have already processed this date
    if [[ -z "${processed_dates[$date_stamp]}" ]]; then
        processed_dates[$date_stamp]=1
        output_tar="$client-$network-snapshot-${date_stamp}.tar.zst"
        echo "Join parts for ${date_stamp} then extract"
        cat $client-$network-snapshot-${date_stamp}-part* > "$output_tar"
        rm $client-$network-snapshot-${date_stamp}-part*
        pv $output_tar | tar -I zstd -xf - -C . --strip-components=3 && rm $output_tar
    fi
done