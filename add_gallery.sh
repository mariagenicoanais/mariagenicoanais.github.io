#!/bin/bash
set -euo pipefail

script_directory=$(dirname $(readlink -f $0))

die()
{
    error "$@"
    exit 1
}

error()
{
    echo "ERROR: $@"
}

info()
{
    echo "INFO: $@"
}

generate_index()
{
    [ $# -ne 1 ] && die "generate_index: gallery_folder"

    local gallery_folder=$1
    shift

    pushd "$gallery_folder" > /dev/null

    local index_rst="index.rst"
    local index_html="index.html"

    cat << EOF > $index_rst
Mes galeries
============

EOF
    for gal in $(find . -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*'\
                 | sort -n)
    do
        local gal_name="$(cat $gal/gallery_name)"
        echo "- \`$gal_name <$gal>\`_" >> $index_rst
    done

    local total_size=$(du -h --exclude .git | tail -n 1 | cut -f 1)
    cat << EOF >> $index_rst

Taille totale: $total_size
EOF

    pandoc $index_rst > $index_html

    popd > /dev/null
}

add_gallery()
{
    [ $# -ne 3 ] && die "add_gallery: gallery_folder input_folder gallery_name"

    local gallery_folder=$1
    shift
    local input_folder=$1
    shift
    local gallery_name=$1
    shift

    local gallery_name_escaped="$(echo $gallery_name | sed -e 's/\s/_/g')"
    local gallery_path="$gallery_folder/$gallery_name_escaped"
    info "generate gallery at $gallery_path"

    fgallery -j 4 -s --index '../' -c txt\
        --quality 80 --max-full 2000x2000 --max-thumb 300x300\
        "$input_folder" "$gallery_path" "$gallery_name"

    echo "$gallery_name" > "$gallery_path/gallery_name"
    info "generate index for $gallery_folder"
    generate_index "$gallery_folder"

    info "index at: $gallery_folder/index.html"
    info "gallery at: $gallery_path"
}

add_gallery "$script_directory" "$@"
