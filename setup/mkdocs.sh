#!/bin/sh

cmd=$1
shift

mkdocs "${cmd}" --config-file setup/mkdocs.yml "$@"
