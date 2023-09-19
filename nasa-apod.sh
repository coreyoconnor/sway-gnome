#!/bin/sh

source /etc/profile

# Sway Nasa Astronomy Picture of the Day background

set -ex

random=$(echo "random" | \
	fold -w1 | shuf | \
	tr -d '\n' \
)
img_regex='<IMG SRC="(.*)"'
script_path=$(dirname "$(readlink -f "$0")")
mkdir -p "$HOME/.cache/sway-nasa-apod/"
local_image_path="$HOME/.cache/sway-nasa-apod/nasa-apod-$(date -I).jpg"
latest_image_path="$HOME/.cache/sway-nasa-apod/latest.jpg"

get_img() {
	remote_image_path=$(curl "$1" 2>/dev/null | \
		pcregrep --only-matching=1 "$img_regex" \
	)
	image_url="https://apod.nasa.gov/apod/$remote_image_path"
	curl --silent --output "$local_image_path" "$image_url"
  cp "$local_image_path" "$latest_image_path"
}


if [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
	echo "Usage: ${0##*/} [-h] [-r]"
	echo ""
        echo "set Sway background to Nasa Astronomy Picture of the Day"
	echo ""
	echo "optional arguments:"
	echo "  -h, --help            show this help message and exit"
	echo "  -r, --$random          pick random day from the archive, url saved to $script_path/last_random_url"
	exit 0
elif [[ "$1" = "-r" ]] || [[ "$1" = "$random" ]] ; then
	archive_list_url="https://apod.nasa.gov/apod/archivepixFull.html"
	archive_regex='<a href="(ap.*.html)'
	archive_urls=$(curl --silent "$archive_list_url" | \
		pcregrep --only-matching=1 "$archive_regex" \
	)
	url=$(echo "$archive_urls" | \
		sort --random-sort | \
		head --lines=1 \
	)
	url=https://apod.nasa.gov/apod/"$url"
	get_img "$url"

	echo "$url" > "$script_path/last_random_url"
else
	url="https://apod.nasa.gov/apod/astropix.html"
	get_img "$url"
fi

swww img $latest_image_path --transition-type outer
