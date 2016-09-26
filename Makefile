QEMUDIR = qemu-2.3.1
LIBVIRTDIR = libvirt-1.2.19
USBDIR = libusb-1.0.20
VMNAME = tinycore
IPADDR = 172.17.28.84

QEMULNK = http://wiki.qemu-project.org/download
QEMUPKG = ${QEMUDIR}.tar.bz2
LIBVIRTLNK = http://libvirt.org/sources
LIBVIRTPKG = ${LIBVIRTDIR}.tar.gz
USBLNK = http://downloads.sourceforge.net/project/libusb/libusb-1.0/${USBDIR}
USBPKG = ${USBDIR}.tar.bz2

TESTLNK = http://distro.ibiblio.org/tinycorelinux/7.x/x86/release
TESTISO = Core-current.iso
VMXML = tiny_mod.xml

D1 = "${QEMUPKG} is existed"
D2 = "${LIBVIRTPKG} is existed"
D3 = "${USBPKG} is existed"
D4 = "${TESTISO} is existed"

U1 = "${USBDIR} is existed"
U2 = "untar ${USBPKG}"
Q1 = "${QEMUDIR} is existed"
Q2 = "untar ${QEMUPKG} ..."
L1 = "${LIBVIRTDIR} is existed"
L2 = "untar ${LIBVIRTPKG} ..."

all: preprocess qemu libvirt

preprocess:
	@echo "========================"
	@echo " Preprocess"
	@echo "========================"
	@[ -f ${QEMUPKG} ] && echo ${D1} || wget ${QEMULNK}/${QEMUPKG}
	@[ -f ${LIBVIRTPKG} ] && echo ${D2} || wget ${LIBVIRTLNK}/${LIBVIRTPKG}
	@[ -f ${USBPKG} ] && echo ${D3} || wget ${USBLNK}/${USBPKG}
	@[ -f ${TESTISO} ] && echo ${D4} || wget ${TESTLNK}/${TESTISO}
	sudo apt-get -y install build-essential p7zip-full pv subversion autoconf libtool 

libusb:
	@echo "========================"
	@echo " USB compilation"
	@echo "========================"
	@[ -d ${USBDIR} ] && echo ${U1} || (echo ${U2} && tar -xf ${USBPKG})
	cd ${USBDIR} && ./configure
	cd ${USBDIR} && make
	cd ${USBDIR} && sudo make install
	

qemu: libusb
	@echo "========================"
	@echo " Qemu compilation"
	@echo "========================"
	@[ -d ${QEMUDIR} ] && echo ${Q1} || (echo ${Q2} && tar -xf ${QEMUPKG})
	sudo apt-get -y install pkg-config zlib1g-dev libglib2.0-dev libsdl1.2-dev
	cd ${QEMUDIR} && sudo ./configure --target-list=x86_64-softmmu --enable-debug --enable-libusb --enable-sdl
	cd ${QEMUDIR} && sudo make
	cd ${QEMUDIR} && sudo make install

libvirt:
	@echo "========================"
	@echo " Libvirt compilation"
	@echo "========================"
	@[ -d ${LIBVIRTDIR} ] && echo ${L1} || (echo ${L2} && tar -xf ${LIBVIRTPKG})
	sudo apt-get -y install libyajl-dev libxml2-dev libdevmapper-dev libudev-dev libpciaccess-dev libnl-dev
	cd ${LIBVIRTDIR} && sudo ./configure
	cd ${LIBVIRTDIR} && sudo sudo make
	cd ${LIBVIRTDIR} && sudo sudo make install

MGRDIR = virt-manager-1.3.2
MGRLNK = https://virt-manager.org/download/sources/virt-manager
MGRPKG = ${MGRDIR}.tar.gz
D4 = "${MGRPKG} is existed"
M1 = "${MGRDIR} is existed"
M2 = "untar ${MGRDIR} ..."
virtmgr:
	@[ -f ${MGRPKG} ] && echo ${D4} || wget ${MGRLNK}/${MGRPKG}
	@[ -d ${MGRDIR} ] && echo ${M1} || (echo ${M2} && tar -xf ${MGRPKG})
	sudo apt-get -y install intltool
	cd ${MGRDIR} && sudo python setup.py install

test-qemu:
	@echo "========================"
	@echo " Test Qemu"
	@echo "========================"
	@echo "use VNC viewer to connect ${IPADDR}:5900"
	qemu-system-x86_64 -boot order=cd -cdrom Core-current.iso -vnc ${IPADDR}:0

test-libvirt-server:
	sudo ldconfig
	sudo libvirtd -d

QEMU_FULL = $(shell which qemu-system-x86_64 | sed 's/\//\\\//g')
TESTISO_FULL = $(shell readlink -f ${TESTISO} | sed 's/\//\\\//g')
test-libvirt:
	@echo "========================"
	@echo " Test Libvirt"
	@echo "========================"
	@cp tiny.xml ${VMXML}
	@sed -i "s/{{ VMNAME }}/${VMNAME}/g" ${VMXML}
	@sed -i "s/{{ QEMU }}/${QEMU_FULL}/g" ${VMXML}
	@sed -i "s/{{ TESTISO }}/${TESTISO_FULL}/g" ${VMXML}
	@echo "use VNC viewer to connect ${IPADDR}:5900"
	sudo virsh list --all
	sudo virsh define ${VMXML}
	sudo virsh list --all
	sudo virsh start ${VMNAME}
	sudo virsh list --all
	sleep 15
	sudo virsh destroy ${VMNAME}
	sudo virsh list --all
	sudo virsh undefine ${VMNAME}
	sudo virsh list --all

clean:
	sudo rm -rf ${VMXML}

cleanall:
	sudo rm -rf ${VMXML} ${QEMUDIR} ${QEMUPKG} ${LIBVIRTDIR} ${LIBVIRTPKG} ${USBDIR} ${USBPKG} ${MGRDIR} ${MGRPKG}
