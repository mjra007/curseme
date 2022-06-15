#!/bin/bash
if [[ $1 == '' ]]; then
	echo "usage: $0 <modpack.zip>"
	exit 1
fi
token="$(dirname "$(realpath $0)")/token"
meow="$(realpath $1)"

if [[ ! -f "$token" ]]; then
	echo "No tokenfile found. Try running ./getToken.sh..?"
	exit 1
fi

mkdir packwrk; cd packwrk
7z -y x "$meow"

# fetch mods
if [[ ! -d mods ]]; then
	mkdir mods; cd mods
	mods="$(cat ../manifest.json | jq -r '.files[] | "\(.projectID),\(.fileID)"')"
	echo "Downloading $(wc -l <<< "$mods") mods"
	while read line; do
		proj=${line/,*/}
		file=${line/*,/}

		url="$(curl -s -H "x-api-key: $(cat "$token")" \
				"https://api.curseforge.com/v1/mods/$proj/files/$file" \
				| jq -r '.data.downloadUrl')"
		url_fix="$(sed 's/\[/%5b/g;s/\]/%5d/g;'"s/'/%27/g;s/ /%20/g" <<< "$url")" #' handling for bad URLs
		curl -s -o "$(basename "$url")" -L "$url_fix" || echo "Failed to download $url" &
		printf "."
	done <<< "$mods"
	wait
	echo "Done"
	cd ..
fi

 