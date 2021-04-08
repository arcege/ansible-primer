:
# if run as a script, this still simply set up the pyhont3 virtualenv
# if run as a 'source' command, then it will also activate the virtualenv
# in the current shell
# if already in a virtualenv, then simply install the requirements

if [ -n "${BASH_VERSION}" ]; then
    PRIMER_PROG="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION}" ]; then
    PRIMER_PROG="${(%):-%N}"
else
    PRIMER_PROG="$0"
fi
PRIMER_SRCDIR="$(dirname ${PRIMER_PROG})"

if [ -z "${VIRTUAL_ENV}" -o ! -d "${VIRTUAL_ENV}" ]; then
    if [ ! -d "${PRIMER_SRCDIR}/.venv" ]; then
        echo "Creating virtualenv at ${PRIMER_SRCDIR}/.venv"
        python3 -m venv "${PRIMER_SRCDIR}/.venv"
    fi

    source "${PRIMER_SRCDIR}/.venv/bin/activate"
fi

if ! PRIMER_PIPOUT=$(pip3 install -r "${PRIMER_SRCDIR}/setup/requirements.txt"); then
    echo "Error installing pip ${PRIMER_SRCDIR}/setup/requirements.txt"
    echo "${PRIMER_PIPOUT}"
fi

if ! PRIMER_GXYOUT=$(ansible-galaxy install -r "${PRIMER_SRCDIR}/setup/galaxy.yml"); then
    echo "Error installing galaxy ${PRIMER_SRCDIR}/setup/galaxy.yml"
    echo "${PRIMER_GXYOUT}"
fi

unset PRIMER_PIPOUT PRIMER_GXYOUT PRIMER_PROG PRIMER_SRCDIR
