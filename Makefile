JSONC:=json-c
export CFLAGS:=-I$(PWD) -I$(PWD)/rpcd/include -I$(PWD)/uci -I$(PWD)/libubox -I$(PWD)/ubus -I$(PWD)/$(JSONC) -DJSONC
LDFLAGS:=-L$(shell pwd) -Lbuild/lib 
BUILD_DIR:=build
LIB_DIR:=$(BUILD_DIR)/lib
BIN_DIR:=$(BUILD_DIR)/bin
PROGS:=$(BIN_DIR)/uci $(BIN_DIR)/questd $(BIN_DIR)/rpcd $(BIN_DIR)/ubus $(BIN_DIR)/ubusd $(BIN_DIR)/uhttpd $(BIN_DIR)/netifd
LIBS:= $(LIB_DIR)/libuci.so $(LIB_DIR)/libblobmsg_json.so $(LIB_DIR)/libubox.so $(LIB_DIR)/libubus.so $(LIB_DIR)/libuci.so $(LIB_DIR)/libnl.so

export LDFLAGS:=-L$(PWD)/build/lib/

all: $(BIN_DIR) $(LIB_DIR) progs; 

clean: 
	rm -rf 	$(BUILD_DIR) json-c juci-source libnl libubox netifd questd rpcd ubus uci uhttpd

progs: $(PROGS) $(LIBS) juci; 

juci-source: 
	git clone https://github.com/mkschreder/luci-express.git juci-source

juci: juci-source $(LIB_DIR)/uhttpd_ubus.so
	cp Makefile-juci.local juci-source/Makefile.local
	make -C juci-source 
	cp -Rp juci-source/bin/* build/
	
$(LIB_DIR) $(BIN_DIR): 
	mkdir -p $@

$(JSONC): 
	git clone https://github.com/mkschreder/juci-json-c.git $(JSONC)
	(cd $(JSONC); ./configure)

$(LIB_DIR)/$(JSONC).so: $(JSONC)
	make -C $(JSONC)
	cp $(JSONC)/.libs/libjson-c.* $(LIB_DIR)/

libnl: 
	git clone https://github.com/mkschreder/juci-libnl.git libnl
	(cd libnl; ./configure)
	
$(LIB_DIR)/libnl.so: libnl
	make -C libnl 
	cp libnl/lib/.libs/libnl-3.* $(LIB_DIR)/
	ln -s libnl-3.so $(LIB_DIR)/libnl.so
	
netifd: 
	git clone https://github.com/mkschreder/juci-netifd.git netifd

$(BIN_DIR)/netifd: $(LIB_DIR)/libnl.so netifd
	(cd netifd; cmake .; make) 
	cp netifd/netifd $(BIN_DIR)/
	
$(BIN_DIR)/ubus $(LIB_DIR)/libubus.so: $(BIN_DIR) $(LIB_DIR) $(LIB_DIR)/libubox.so $(LIB_DIR)/$(JSONC).so ubus
	(cd ubus; cmake .; make) 
	cp ubus/ubus ubus/ubusd $(BIN_DIR)/
	cp ubus/libubus*so $(LIB_DIR)/
	
ubus: 
	git clone https://github.com/mkschreder/juci-ubus.git ubus

ubox: 
	git clone https://github.com/mkschreder/juci-ubox.git ubox

$(BIN_DIR)/ubox: 
	(cd ubox; cmake .; make)
	
questd: 
	git clone https://github.com/mkschreder/juci-questd.git questd 
	
$(BIN_DIR)/questd: questd $(BIN_DIR)/uci $(LIB_DIR)/libuci.so $(LIB_DIR)/libubus.so $(LIB_DIR)/libubox.so
	make -C questd 
	cp questd/questd $(BIN_DIR)/ 
	
libubox: 
	git clone https://github.com/mkschreder/juci-libubox.git libubox

$(LIB_DIR)/libubox.so: $(LIB_DIR)/$(JSONC).so libubox
	(cd libubox; cmake .; make ) 
	cp libubox/libubox*so libubox/libblobmsg_json*so $(LIB_DIR)/
	
rpcd: 
	git clone https://github.com/mkschreder/juci-rpcd.git $@

$(BIN_DIR)/rpcd: rpcd 
	(cd rpcd; cmake .; make)
	mkdir -p $(BUILD_DIR)/etc/config/
	cp rpcd/rpcd $(BIN_DIR)/
	cp rpcd/config.default $(BUILD_DIR)/etc/config/rpcd
	
uci: 
	git clone https://github.com/mkschreder/juci-uci.git $@

$(BIN_DIR)/uci $(LIB_DIR)/libuci.so: $(LIB_DIR)/libubox.so uci
	(cd uci; cmake .; make) 
	cp uci/uci $(BIN_DIR)/
	cp uci/libuci*so $(LIB_DIR)/
	
uhttpd: 
	git clone https://github.com/mkschreder/juci-uhttpd.git $@

$(BIN_DIR)/uhttpd $(LIB_DIR)/uhttpd_ubus.so: $(LIB_DIR)/libubox.so $(LIB_DIR)/libubus.so uhttpd
	(cd uhttpd; cmake .; make)
	cp uhttpd/uhttpd  $(BIN_DIR)/
	cp uhttpd/uhttpd_ubus.so $(LIB_DIR)/
	
$(LIB_DIR)/ubus-mod-juci.so:
	(cd ubus-mod-juci; cmake .; make)
	cp ubus-mod-juci/ubus-mod-juci.so $(LIB_DIR)/
	#cp ubus-mod-juci/io/juci-cgi 
	
install_bin: $(PROGS)
	cp $(PROGS) /usr/local/bin

install_lib: $(LIBS)
	cp $(LIBS)  /usr/lib
	
install: 
	cp -R $(BIN_DIR)/* /usr/local/bin/
	cp -R $(LIB_DIR)/* /usr/lib/
	cp -R $(BUILD_DIR)/usr/* /usr/
	cp -R $(BUILD_DIR)/www / 
	cp -R $(BUILD_DIR)/etc/* /etc/
