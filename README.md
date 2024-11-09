# install-uv.sh

## Usage

Install uv at current directory.

### Usage on Linux

```sh
curl https://raw.githubusercontent.com/pollenjp/install-uv.sh/refs/heads/main/install-uv.sh | bash

./pycmd -- uv --version
```

### Usage on WindowsOS

```ps1
powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/pollenjp/install-uv.sh/refs/heads/main/install-uv.ps1 | iex"

powershell -ExecutionPolicy ByPass -F .\pycmd.ps1 uv --version
```

### Customize

- `INSTALL_UV_TARGET_VERSION`: Specify the version of uv. Default is `latest`.
- `INSTALL_UV_BASE_DIR`: Specify the base directory of the installation. Default is `.` (current directory).
  - `${INSTALL_UV_BASE_DIR}/.uv`
  - `${INSTALL_UV_BASE_DIR}/.cache`
  - `${INSTALL_UV_BASE_DIR}/.local`

```sh
curl https://raw.githubusercontent.com/pollenjp/install-uv.sh/refs/heads/main/install-uv.sh \
 | env INSTALL_UV_TARGET_VERSION=0.4.23 INSTALL_UV_BASE_DIR=custom_path bash -eu -o pipefail
```

## Development

### Debug on Linux

```sh
make debug-run
```

### Debug on WindowsOS

```ps1
powershell -ExecutionPolicy ByPass -F ".\install-uv.ps1"
powershell -ExecutionPolicy ByPass -c "type .\install-uv.ps1 | Out-String | iex"
```

```ps1
powershell -ExecutionPolicy ByPass -F .\pycmd.ps1 uv --version
```
