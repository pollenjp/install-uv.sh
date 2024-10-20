# install-uv.sh

## Usage

Install uv at current directory.

```sh
curl https://raw.githubusercontent.com/pollenjp/install-uv.sh/refs/heads/main/install-uv.sh \
  | bash -eu -o pipefail

./pycmd -- uv --version
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
