This folder contains a base system for the zu board. When you run make you will generate the XSA of the system.
The PL model is just HPM0 and HPM1 connected to a brams.

After getting the xsa you should start a petalinux project:

`petalinux-create --type project --template zynqMP --name zu_board_base`

Then you feed the project with the xsa:

`petalinux-config --get-hw-description=fpga.xsa`

This will open a prompt to configure the system,
To use EXT4 instead of initramfs:
You need to select subsystem auto hw settings->SD settings -> Primary SD = psu_sd_1
Then in DTG settings-> kernel bootargs= console=ttyPS0,115200 earlycon clk_ignore_unused earlyprintk root=/dev/mmcblk1p2 rootfstype=ext4 rw rootwait cma=512M
Finally, Image Package configuration->root filesystem type -> EXT4 

Remember to activate the fpga manager to be able to reconfigure the pl.

If you want to select certain packages your image:
`petalinux-config -c rootfs`

Here I recommend going into image features and select debug-tweaks and auto login (by default petalinux dont let you enter as root)
Also if you want to use scp to pass bit files mark openssh instead of dropbear. (also you need to unmark it from the Filesystem packages)

If you want to modify the uboot and the kernel you can do it (its not necessary)
You can tweak the uboot options with:
`petalinux-config -c u-boot`

In the same way to tweak the kernel:
`petalinux-config -c kernel`

To finally build the images you use:
`petalinux-build`

When it finished you can pack the images using:
`petalinux-package --boot --u-boot --fpga`

This will generate the files BOOT.BIN, boot.scr, image.ub, rootfs.ext4 (or the rootfs.tar.gz if you are using initramfs)

We need to create two partitions in a SD card:
The first one in FAT32 of approx 30MB where you have to place BOOT.BIN, boot.scr and image.ub
The second one in ext4 with the rest of the memeory available, in that partition you have to put the rootfs. If you are using ext4: `dd if=rootfs.ext4 of=/dev/mmcblk0p2`, if you are using initramfs just untar the file in the partition: `tar -xvf rootfs.tar.gz`



** Notes
BTW there is a pynq image [here](https://github.com/Avnet/ZUBoard_1CG-PYNQ/tree/main)


