#!/usr/bin/env bash

set -e

prompt1="Enter your option: "
ESP="/boot/efi"
MOUNTPOINT="/mnt"

contains_element() {
	#check if an element exist in a string
	for e in "${@:2}"; do [[ $e == "$1" ]] && break; done
}

#SELECT DEVICE
select_device() {
	devices_list=($(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
	PS3="$prompt1"
	echo -e "Attached Devices:\n"
	lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135,259 | awk '{print $1,$4,$6,$7}' | column -t
	echo -e "\n"
	echo -e "Select device to partition:\n"
	select device in "${devices_list[@]}"; do
		if contains_element "${device}" "${devices_list[@]}"; then
			break
		else
			exit 1
		fi
	done
	if [ "$1" = "-n" ]; then
		ROOT_PARTITION="${device}p1"
		SWAP_PARTITION="${device}p2"
		ESP_PARTITION="${device}p3"
	else
		ROOT_PARTITION="${device}1"
		SWAP_PARTITION="${device}2"
		ESP_PARTITION="${device}3"
	fi
	echo "Root partition: ${ROOT_PARTITION}"
	echo "Swap partition: ${SWAP_PARTITION}"
	echo "ESP partition: ${ESP_PARTITION}"
}

#CREATE_PARTITION
create_partition() {
	wipefs -a "${device}"
	# Set GPT scheme
	parted "${device}" mklabel gpt &>/dev/null
	parted "${device}" -- mkpart primary 512MiB -6GiB &>/dev/null
	parted "${device}" -- mkpart primary linux-swap -6GiB 100% &>/dev/null
	parted "${device}" -- mkpart ESP fat32 1MiB 512MiB &>/dev/null
	parted "${device}" -- set 3 esp on &>/dev/null
}

#FORMAT_PARTITION
format_partition() {
	mkfs.ext4 -L nixos "${ROOT_PARTITION}" >/dev/null
	mkswap -L swap "${SWAP_PARTITION}" >/dev/null
	swapon "${SWAP_PARTITION}" >/dev/null
	mkfs.fat -F 32 -n boot "${ESP_PARTITION}" >/dev/null
}

#MOUNT_PARTITION
mount_partition() {
	mount /dev/disk/by-label/nixos "${MOUNTPOINT}"
	mkdir -p "${MOUNTPOINT}"${ESP}
	mount "${ESP_PARTITION}" "${MOUNTPOINT}"${ESP}
}

# NIXOS_INSTALL
nixos_install() {
	git clone https://github.com/flibrary/infra .

	# Install NixOS. We don't need root password.
	nixos-install --flake "./infra#bootstrap" --no-root-passwd

	echo "Finished!"
}

# INSTALLATION
select_device "$@"
create_partition
format_partition
mount_partition
nixos_install
