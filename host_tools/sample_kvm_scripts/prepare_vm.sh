#
#  Copyright (c) 2023  NVIDIA CORPORATION & AFFILIATES. All rights reserved.
#
AMD_SEV_DIR=/shared/amdese-amdsev/snp-release-2025-02-08
VDD_IMAGE=/mnt/data/vm_disks/ubuntu22.04-2.qcow2
ISO=/mnt/data/vm_disks/ubuntu-22.04.5-live-server-amd64.iso
FWDPORT=7999

$AMD_SEV_DIR/usr/local/bin/qemu-system-x86_64 \
-enable-kvm -nographic -no-reboot -cpu EPYC-v4 -machine q35 \
-smp 12,maxcpus=31 -m 64G,slots=5,maxmem=120G \
-bios $AMD_SEV_DIR/usr/local/share/qemu/OVMF.fd \
-drive file=$VDD_IMAGE,if=none,id=disk0,format=qcow2 \
-device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=true \
-device scsi-hd,drive=disk0 \
-device virtio-net-pci,disable-legacy=on,iommu_platform=true,netdev=vmnic,romfile= \
-netdev user,id=vmnic,hostfwd=tcp::$FWDPORT-:22 \
-cdrom $ISO
