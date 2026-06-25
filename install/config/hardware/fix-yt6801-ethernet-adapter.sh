# Install drivers for Motorcomm YT6801 ethernet adapter used by the Slimbook Executive
if lspci | grep -i "YT6801\|Motorcomm.*Ethernet"; then
  # yt6801-dkms is not currently in [maitri] (its PKGBUILD doesn't build against the
  # current upstream vendor zip — BEYER-8), so don't let its absence abort the install.
  maitri-pkg-add linux-headers
  maitri-pkg-add yt6801-dkms || echo "maitri: yt6801-dkms unavailable (BEYER-8); skipping ethernet adapter driver"
fi
