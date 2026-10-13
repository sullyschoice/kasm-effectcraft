#!/usr/bin/env bash
set -ex
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

REPO="storytold/effectcraft"

# Map the Debian architecture to the naming used in the release assets
case "$(dpkg --print-architecture)" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y curl ca-certificates

# Use EFFECTCRAFT_VERSION if given (e.g. 0.9.2), otherwise resolve the latest release tag.
# The /releases/latest redirect avoids the unauthenticated GitHub API rate limit.
if [ -z "${EFFECTCRAFT_VERSION}" ]; then
  TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" | sed 's#.*/tag/##')
  EFFECTCRAFT_VERSION="${TAG#v}"
fi

DEB="effectcraft-${EFFECTCRAFT_VERSION}-linux-${ARCH}.deb"
BASE_URL="https://github.com/${REPO}/releases/download/v${EFFECTCRAFT_VERSION}"

mkdir -p /tmp/effectcraft
cd /tmp/effectcraft
curl -fsSL -o "${DEB}" "${BASE_URL}/${DEB}"
curl -fsSL -o SHA256SUMS.txt "${BASE_URL}/SHA256SUMS.txt"
grep " ${DEB}\$" SHA256SUMS.txt | sha256sum -c -

# Recommends pulls in mesa-vulkan-drivers / libegl-mesa0 for software rendering without a GPU
apt-get install -y --install-recommends "./${DEB}"

# Desktop shortcut
mkdir -p $HOME/Desktop
cp /usr/share/applications/ai.storyteller.effectcraft.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/ai.storyteller.effectcraft.desktop
chown 1000:1000 $HOME/Desktop/ai.storyteller.effectcraft.desktop

# Cleanup
cd /
rm -rf /tmp/effectcraft
apt-get autoclean
rm -rf /var/lib/apt/lists/* /var/tmp/*
