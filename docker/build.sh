#!/usr/bin/env bash
#
# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Monkey365 – Docker Image Build and Tagging Script
# Adapted from build.ps1 (PowerShell) to Bash
# Author: Juan Garrido (original) (bash adaptation by goldrak)


set -euo pipefail

NAME="monkey365"
VERSION="latest"
DOCKERFILE=""

usage() {
  cat <<EOF
Use: $0 [Options]

Options:
    -n, --name Name of the Docker image (default: $NAME)
    -v, --version Image label (default: $VERSION)
    -p, --path Path to the Dockerfile (required)
    -h, --help Show this help and exit

Example:
  $0 -n monkey365 -v latest -p ./docker/Dockerfile_linux
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      NAME="$2"; shift 2;;
    -v|--version)
      VERSION="$2"; shift 2;;
    -p|--path)
      DOCKERFILE="$2"; shift 2;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1"
      usage;;
  esac
done

if [[ -z "$DOCKERFILE" ]]; then
  echo "Error: You must specify the path to the Dockerfile with -p or --path."
  usage
fi

if [[ ! -f "$DOCKERFILE" ]]; then
  echo "Error: Dockerfile does not exist in '$DOCKERFILE'."
  exit 1
fi

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

TAG="${NAME}:${VERSION}"

echo "Building Dockerfile using file '${DOCKERFILE}' and tag '${TAG}'"

docker build \
  --rm \
  -f "$DOCKERFILE" \
  -t "$TAG" \
  --build-arg VERSION="$VERSION" \
  --build-arg VCS_URL="https://github.com/silverhack/monkey365" \
  --build-arg BUILD_DATE="$BUILD_DATE" \
  .

