This helps building the ili9163 SPI TFT display tinydrm Linux kernel driver out of tree.

The source of the kernel module is https://patchwork.kernel.org/project/dri-devel/list/?series=457553 (disregard the wrong patch title), by Daniel Mack

Provided is also a device tree overlay file to connect the display to a Raspberry PI with the following connections:

| RPi function  | RPi physical pin  |  display physical pin |  display function |
| ------------- | ----------------- | ---------------------:| -----------------:|
| GND   |  | 1  | GND  |
| 3.3V  |  | 2  | VDD  |
| 3.3V  |  | 3  | VDD  |
| CS0, GPIO 8  | 24 |  4 | /CS |
| GPIO 25  | 22  |  5 | /RST |
| MOMI  | 19  |  6 | SDIO  |
| GND  |  |  7 | GND |
| GPIO 22  | 15  |  8  | D/C |
| SCL  | 23  |  9 | SCL |
| GND  |   |  10 | GND  |
| 3.3V |   |  11 | 4-wire mode |
| GND  |   |  20 | GND |
| 3.3V |   |  17 | LED Anode |
| GND  |   |  18 | LED Kathode |
| GND  |   |  19 | LED Kathode |

For (cross-)compiling for Raspberry Pi you'll need a kernel source tree that matches your pi. If you're using a standard Raspbian kernel you can follow the instructions at https://www.raspberrypi.org/documentation/linux/kernel/building.md and https://lostindetails.com/articles/compiling-a-kernel-module-for-the-raspberry-pi-2

On the pi:

````bash
FIRMWARE_HASH=$(zgrep "* firmware as of" /usr/share/doc/raspberrypi-bootloader/changelog.Debian.gz | head -1 | awk '{ print $5 }')
KERNEL_HASH=$(wget https://raw.github.com/raspberrypi/firmware/$FIRMWARE_HASH/extra/git_hash -O -)
echo $KERNEL_HASH
````

This will output a commit hash, such as `081f560bde7188ca6f40cf297bd55c680e0179c0`.

Then on your build host do:

````bash
sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev
sudo apt install crossbuild-essential-armhf
git clone https://github.com/raspberrypi/linux raspberrypi-linux
cd raspberrypi-linux
git checkout 081f560bde7188ca6f40cf297bd55c680e0179c0
````

Default configuration and build command differs between Raspberry Pi hardware versions, see the documentation linked above. For Pi 0 do, on your buildhost:

````bash
KERNEL=kernel
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j5 zImage modules dtbs
````

Now you have a fully built and usable Raspberry Pi linux kernel tree in `raspberrypi-linux`.

To build the module and device tree overlay in this directory you'll need to provide the path, such as `../raspberrypi-linux/` to the linux source directory. Then simply do

````bash
make KDIR=../raspberrypi-linux/ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
````

To install the module, copy the resulting `ili9163.ko` into `/lib/modules/$(uname -r)/extra/` and run `sudo depmod -a`. Also, create a `/etc/modules-load.d/ili9163.conf` with a single line `ili9163` to have the module autoloaded at boot (for some reason it's not automatically loaded by the device tree, FIXME).

To install the `kbdisp.dtbo` file, copy it into `/boot/overlays/` and append the line `dtoverlay=kbdisp` to `/boot/config.txt`.

Note: Even when the module is loaded and the `/dev/fb1` device is created, the display is *not* enabled by default: `/sys/class/drm/card0-SPI-1/enabled` shows `disabled`. I have not found the 'correct' way to enable it.

Hacky: Opening `/dev/dri/card0` seems to enable the display, even without writing anything into it. Simply do `cat /dev/zero > /dev/dri/card0` and ignore the 'invalid argument' error.

More proper: By editing `/boot/cmdline.txt` you can use the fbcon module to activate a console (tty) on the display.
Two variants: append `fbcon=map:10` to the command line to swap SPI display and broadcom video core, so the SPI display becomes tty1 and the normal raspberry pi display becomes tty2. You'll get normal linux/systemd boot messages on the SPI display.
Or: append `fbcon=map:01` to the command line. Now the SPI display will be tty2, which is normally unused and no output is written to it, but it is under control of `fbcon` and enabled.

To test:
````bash
sudo apt install fbi
sudo fbi -T 1 -d /dev/fb1 /usr/share/icons/hicolor/32x32/apps/rpi.png
````

Note: `fbi` tends to hang around. Do a `killall fbi` afterwards.
