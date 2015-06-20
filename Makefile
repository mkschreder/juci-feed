JSONC:=json-c
CFLAGS:=-I$(shell pwd) -Iuci -Ilibubox -Iubus -I$(JSONC) -DJSONC
LDFLAGS:=-L$(shell pwd) -Llib 
PROGS:=bin/uci bin/questd bin/rpcd bin/ubus bin/ubusd bin/uhttpd bin/netifd
LIBS:= lib/libuci.so lib/libblobmsg_json.so lib/libubox.so lib/libubus.so lib/libuci.so lib/libnl.so

all: bin lib progs; 

progs: $(PROGS) $(LIBS) juci
	cp lib/*so bin/

juci-source: 
	git clone https://github.com/mkschreder/luci-express.git juci-source

juci: juci-source bin/uhttpd_ubus.so
	make -C juci-source DEFAULT_THEME=y
	
lib bin: 
	mkdir -p $@

$(JSONC): 
	git clone https://github.com/mkschreder/juci-json-c.git $(JSONC)

$(JSONC)/Makefile: $(JSONC)
	(cd $(JSONC); ./configure)
	
lib/$(JSONC).so: $(JSONC)/Makefile 
	mkdir -p lib
	make -C $(JSONC)
	cp $(JSONC)/.libs/libjson-c.* lib/

libnl: 
	https://github.com/mkschreder/juci-libnl.git libnl
	(cd libnl; ./configure)
	
lib/libnl.so: libnl
	make -C libnl 
	cp libnl/lib/.libs/libnl-3.* lib/
	ln -s libnl-3.so lib/libnl.so
	
netifd: 
	git clone https://github.com/mkschreder/juci-netifd.git netifd

bin/netifd: netifd
	(cd netifd; cmake .; make) 
	cp netifd/netifd bin/
	
bin/ubus lib/libubus.so: bin lib lib/libubox.so lib/$(JSONC).so ubus
	(cd ubus; cmake .; make) 
	cp ubus/ubus ubus/ubusd bin/
	cp ubus/libubus* lib/
	
ubus: 
	git clone https://github.com/mkschreder/juci-ubus.git ubus

ubox: 
	git clone https://github.com/mkschreder/juci-ubox.git ubox

bin/ubox: 
	(cd ubox; cmake .; make)
	
#bin/ubox: ubox
#	(cd ubox; cmake . ; make) 
	
bin/questd: uci lib/libuci.so lib/libubus.so lib/libubox.so
	make -C questd 
	cp questd/questd bin/ 
	
libubox: 
	git clone https://github.com/mkschreder/juci-libubox.git libubox

lib/libubox.so: lib/$(JSONC).so libubox
	(cd libubox; cmake .; make ) 
	cp libubox/libubox.* libubox/libblobmsg_json.* lib/
	
rpcd: 
	git clone https://github.com/mkschreder/juci-rpcd.git $@

bin/rpcd: rpcd 
	(cd rpcd; cmake .; make)
	cp rpcd/rpcd bin/
	
uci: 
	git clone https://github.com/mkschreder/juci-uci.git $@

bin/uci lib/libuci.so: uci
	(cd uci; cmake .; make) 
	cp uci/uci bin/
	cp uci/libuci.* lib/
	
uhttpd: 
	git clone https://github.com/mkschreder/juci-uhttpd.git $@

bin/uhttpd bin/uhttpd_ubus.so: lib/libubox.so lib/libubus.so uhttpd
	(cd uhttpd; cmake .; make)
	cp uhttpd/uhttpd uhttpd/uhttpd_ubus.so bin/
	
lib/ubus-mod-juci.so:
	(cd ubus-mod-juci; cmake .; make)
	cp ubus-mod-juci/ubus-mod-juci.so lib/
	#cp ubus-mod-juci/io/juci-cgi 
	
install_bin: $(PROGS)
	cp $(PROGS) /usr/local/bin

install_lib: $(LIBS)
	cp $(LIBS)  /usr/lib
	
install: install_bin install_lib
	mkdir -p /usr/share/rpcd/acl.d/
	mkdir -p /usr/lib/rpcd
	mkdir -p /etc/config/
	cp rpcd/config.default /etc/config/rpcd
	
	cp -R juci-source/menu.d /usr/share/rpcd/
	cp ubus-mod-juci/access.json /usr/share/rpcd/acl.d/juci.json
	cp ubus-mod-juci/ubus-mod-juci.so /usr/lib/rpcd/
