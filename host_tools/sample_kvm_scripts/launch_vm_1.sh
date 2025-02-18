#
#  Copyright (c) 2023  NVIDIA CORPORATION & AFFILIATES. All rights reserved.
#
AMD_SEV_DIR=/shared/AMDSEV/snp-release-2025-02-08
# AMD_SEV_DIR=/shared/amdese-amdsev-2024/snp-release-2025-02-10
VDD_IMAGE=/mnt/data/vm_disks/ubuntu22.04-cc-1.qcow2

#Hardware Settings
NVIDIA_GPU=45:00.0
MEM=32 #in GBs
FWDPORT=9889

doecho=false
docc=true

while getopts "exp:" flag
do
        case ${flag} in
                e) doecho=true;;
                x) docc=false;;
                p) FWDPORT=${OPTARG};;
        esac
done

NVIDIA_GPU="e3:00.0"
NVIDIA_PASSTHROUGH=$(lspci -n -s $NVIDIA_GPU | awk -F: '{print $4}' | awk '{print $1}')

if [ "$doecho" = true ]; then
         echo 10de $NVIDIA_PASSTHROUGH > /sys/bus/pci/drivers/vfio-pci/new_id
fi

if [ "$docc" = true ]; then
        USE_HCC=true
fi


# -drive if=pflash,format=raw,unit=0,file=$AMD_SEV_DIR/usr/local/share/qemu/OVMF.fd,readonly=on \
# -bios $AMD_SEV_DIR/usr/local/share/qemu/OVMF.fd \

$AMD_SEV_DIR/usr/local/bin/qemu-system-x86_64 \
${USE_HCC:+ -machine confidential-guest-support=snp,vmport=off} \
${USE_HCC:+ -object sev-snp-guest,id=snp,cbitpos=51,reduced-phys-bits=1} \
-enable-kvm -nographic -no-reboot \
-cpu EPYC-v4 -machine q35 -smp 8 -m ${MEM}G \
-bios $AMD_SEV_DIR/usr/local/share/qemu/OVMF.fd \
-drive file=$VDD_IMAGE,if=none,id=disk0,format=qcow2 \
-device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=true \
-device scsi-hd,drive=disk0 \
-device virtio-net-pci,disable-legacy=on,iommu_platform=true,netdev=vmnic,romfile= \
-netdev user,id=vmnic,hostfwd=tcp::$FWDPORT-:22,hostfwd=tcp::8081-:8080 \
-device pcie-root-port,id=pci.1,bus=pcie.0 \
-device vfio-pci,host=$NVIDIA_GPU,bus=pci.1 \
-fw_cfg name=opt/ovmf/X-PciMmio64Mb,string=262144