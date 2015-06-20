JSONC:=json-c-0.11
CFLAGS+=-Iubus -I$(JSONC) -DJSONC
LD_FLAGS:=-Lubus -L$(JSONC) -ljson-c
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
	wget https://s3.amazonaws.com/json-c_releases/releases/$(JSONC).tar.gz 
	tar xzf $(JSONC).tar.gz 

$(JSONC)/Makefile: 
	(cd $(JSONC); ./configure)
	
lib/$(JSONC).so: $(JSONC)/Makefile $(JSONC)
	mkdir -p lib
	make -C $(JSONC)
	cp $(JSONC)/.libs/libjson-c.* lib/

libnl: 
	wget http://www.infradead.org/~tgr/libnl/files/libnl-3.2.21.tar.gz
	tar xzf libnl-3.2.21.tar.gz
	mv libnl-3.2.21 libnl
	(cd libnl; ./configure)
	
lib/libnl.so: libnl
	make -C libnl 
	cp libnl/lib/.libs/libnl-3.* lib/
	ln -s libnl-3.so lib/libnl.so
	
netifd: 
	git clone http://git.openwrt.org/project/netifd.git netifd

bin/netifd: netifd
	(cd netifd; cmake .; make) 
	cp netifd/netifd bin/
	
bin/ubus bin/libubus.so: lib/libubox.so lib/$(JSONC).so ubus
	(cd ubus; cmake .; make) 
	cp ubus/ubus ubus/ubusd bin/
	cp ubus/libubus* lib/
	
ubus: 
	git clone git://nbd.name/luci2/ubus.git

ubox: lib/libubox.a; 
	#git clone git://nbd.name/luci2/ubox.git $@

#bin/ubox: ubox
#	(cd ubox; cmake . ; make) 
	
bin/questd: uci lib/libuci.so lib/libubus.so lib/libubox.so
	make -C questd 
	cp questd/questd bin/ 
	
libubox: 
	git clone http://git.openwrt.org/project/libubox.git $@

lib/libubox.so: $(JSONC) libubox
	(cd libubox; cmake .; make ) 
	cp libubox/libubox.* libubox/libblobmsg_json.* lib/
	
rpcd: 
	git clone https://github.com/mkschreder/openwrt-rpcd.git $@

bin/rpcd: rpcd 
	(cd rpcd; cmake .; make)
	cp rpcd/rpcd bin/
	
uci: 
	git clone git://nbd.name/uci.git $@

bin/uci lib/libuci.so: uci
	(cd uci; cmake .; make) 
	cp uci/uci bin/
	cp uci/libuci.* lib/
	
uhttpd: 
	git clone git@iopsys.inteno.se:uhttpd2.git $@

bin/uhttpd bin/uhttpd_ubus.so: uhttpd
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
