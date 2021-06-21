ifneq ($(KERNELRELEASE),)
# kbuild part of makefile
obj-m += ili9163.o

else
# normal makefile
KDIR ?= /lib/modules/`uname -r`/build
DTC ?= $(KDIR)/scripts/dtc/dtc

default: kbdisp.dtbo
	$(MAKE) -C $(KDIR) M=$$PWD

%.dtbo: %-overlay.dts.pp
	$(DTC) -@ -Hepapr -I dts -O dtb -o $@ $<

%-overlay.dts.pp: %-overlay.dts
	$(CPP) -nostdinc -I include -I arch  -undef -x assembler-with-cpp -I $(KDIR)/include/ -o $@ $<

endif
