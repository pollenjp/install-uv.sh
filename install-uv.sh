#!/usr/bin/env bash
set -eu -o pipefail

uv_version=${INSTALL_UV_TARGET_VERSION:-"latest"}
base_dir=${INSTALL_UV_BASE_DIR:-$(pwd)}
readonly uv_install_dir="${base_dir}/.uv"

usage=$(
  cat <<__EOS
Description: Install uv and generate pycmd
Usage: "install-uv.sh [options]

Options:
  -h  Show help
  -v  Specify the version of uv e.g. '0.4.24' (default: ${uv_version})
__EOS
)

while getopts hv: OPT; do
  case "$OPT" in
    h) echo "$usage"; exit 0 ;;
    v) uv_version=$OPTARG ;;
    *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;; # 不正なオプション (OPT = ?)
  esac
done
shift $((OPTIND - 1))

if [[ $# -gt 0 ]]; then
  echo "Unknown argument: $1" >&2
  exit 1
fi

if [[ "${uv_version}" == "latest" ]]; then
  if ! command -v jq > /dev/null; then
    echo "jq is required to get the 'latest' version of uv" >&2
    exit 1
  fi
  uv_version=$(
    curl -s  "https://api.github.com/repos/astral-sh/uv/tags" \
    | jq -r '
map(.name)
| sort_by(
  # sort by semantic versioning
  # https://stackoverflow.com/a/77961624
  #
  # ignore build
  split("+")[0]
  # extract version core and pre-release as arrays of numbers and strings
  |split("-")
  |(.[0]|split(".")|map(tonumber? // .)) as $version_core
  |(.[1:]|join("-")|split(".")|map(tonumber? // .)) as $pre_release
  # sort by version core
  |$version_core,
  # pre-release versions have a lower precedence than the associated normal version
  ($pre_release|length)==0,
  # sort by pre-release
  $pre_release
)
| last'
  )
fi


skip_download=0
if [[ -f "${uv_install_dir}/bin/uv" ]]; then
  _uv_version=$("${uv_install_dir}/bin/uv" --version)
  if [[ "${_uv_version}" == "uv ${uv_version}" ]]; then
    echo "The installed uv version is the same as the target version. Skip download."
    skip_download=1
  fi
fi

if [[ "${skip_download}" == "0" ]]; then
  curl -LsSf "https://astral.sh/uv/${uv_version}/install.sh" | env UV_INSTALL_DIR="${uv_install_dir}" INSTALLER_NO_MODIFY_PATH=1 sh
fi

##################
# Generate pycmd #
##################
#
# 任意のコマンドを pycmd の引数に渡すことでこの環境下で動作する
#

cat <<'__EOF__' >| "${base_dir}"/pycmd
#!/usr/bin/env bash
set -eu -o pipefail -o pipefail

script_path=$(realpath "${BASH_SOURCE[0]}")

prog_name=$(basename "${script_path}")
readonly prog_name

declare -a additional_paths=()
__EOF__
cat <<__EOF__ >> "${base_dir}/pycmd"
export XDG_CONFIG_HOME="${base_dir}/.config"
export XDG_CACHE_HOME="${base_dir}/.cache"
export XDG_DATA_HOME="${base_dir}/.local/share"
export XDG_BIN_HOME="${base_dir}/.local/bin"
additional_paths+=( "${uv_install_dir}/bin" )
__EOF__
cat <<'__EOF__' >> "${base_dir}/pycmd"
additional_paths+=( "${XDG_BIN_HOME}" )
joined_path=$(IFS=:; echo "${additional_paths[*]}")
export PATH="${joined_path}:$PATH"

usage=$(
  cat <<__EOS
Description: ローカルで完結した uv 環境を利用するためのコマンド
Usage: "${prog_name}" -- [command] [args...]

e.g.
  "${prog_name}" -- uv --version
  "${prog_name}" -- uv --help
  "${prog_name}" -- uv run python -V
__EOS
)

# 引数処理
while getopts h OPT; do
  case "$OPT" in
    h) echo "$usage"; exit 0 ;;
    *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

eval "$(printf "%q " "$@")"
__EOF__

chmod +x "${base_dir}/pycmd"

echo "Generated pycmd at ${base_dir}/pycmd"
