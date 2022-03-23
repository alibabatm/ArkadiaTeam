#!/usr/bin/env bash
set -euo pipefail

if [[ ${DEBUG:-} -eq 1 ]]; then
  set -x
fi

declare git_raw_base_url='https://raw.githubusercontent.com'
declare kagura_base_dir; kagura_base_dir=$(git rev-parse --show-toplevel)
declare this_branch; this_branch=$(git rev-parse --abbrev-ref HEAD)
declare org_name='ArkadiaTeam'
declare repo_name='cabari-kagura-json'
declare git_io_url='https://git.io'
readonly cubari_reader_base_url='https://cubari.moe/read/gist'
declare output_file="$kagura_base_dir/surge/index.html"

mkdir -p "$kagura_base_dir/surge"
cat<<INDEX_HTML > "$output_file"
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="pl"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

<title>Arkadia Team reader</title>
<style>
body {
	max-width: 768px;
	margin-left: auto;
	margin-right: auto;
}
a:link {
  text-decoration: none;
}
a:visited {
  text-decoration: none;
}
a:hover {
  text-decoration: underline;
}
a:active {
  text-decoration: underline;
}
@media (min-width: 960px) {
	body {
		max-width: 100%;
	}
	#pageview {
		margin-left: auto;
		margin-right: auto;
		text-align: center;
	}
	#page {
		width: auto;
		max-width: 100%;
	}
}
@media (min-width: 1536px) {
	body {
		max-width: 1536px;
	}
}
</style>
</head>
<body bgcolor="#2E3440" text="#ECEFF4" link="#D8DEE9" vlink="#D8DEE9" alink="#E5E9F0">
<br>
<h2>Arkadia Team - tytuły</h2>
<ol>
INDEX_HTML

while read -r manga_cubari_json; do
  declare cubari_json_basename; cubari_json_basename=$(basename "$manga_cubari_json")
  declare manga_title; manga_title=$(jq -r '.title // ""' "$manga_cubari_json")
  if [[ -z $manga_title ]]; then
    echo "Failed to read title for $manga_cubari_json. Skipping."
    continue
  fi
  echo "Fetching reader URL for $manga_title" >&2
  declare shorten_url; shorten_url=$(
    curl -s -i "$git_io_url" -F "url=$git_raw_base_url/$org_name/$repo_name/$this_branch/${cubari_json_basename// /%20}" \
      | awk '/Location:/ {print $2}'
  )
  shorten_url=${shorten_url#${git_io_url%/}/}
  echo "<li><a href=\"$cubari_reader_base_url/$shorten_url\" target=\"_blank\">${manga_title}</a></li>" >> "$output_file"
done < <(find "$kagura_base_dir" -name '*json' -not -name 'empty-example.json')

cat<<INDEX_HTML >> "$output_file"
</ol>
</body>
INDEX_HTML
