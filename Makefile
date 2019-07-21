# get nginx version
ifeq (, $(shell which nginx))
    $(error "nginx not found, please install it and make sure it's in PATH")
endif
NGX_VER ?= $(shell nginx -v 2>&1 | grep -oE '[0-9.]+')
NGX_DIR ?= build/nginx-$(NGX_VER)

# get nginx modules path
NGX_MODULES_PATH ?= $(shell nginx -V 2>&1 | grep -oE -- '--modules-path=\S+' | sed 's/--modules-path=//')

# get the configuration that nginx was compiled with, then do the following modifications
# - remove --add-dynamic-module options to avoid building other modules
# - remove --with-*=dynamic, again to avoid building other modules
# - we add our LD_OPT to the existing --with-ld-opt='...'
#
LD_OPT = ..\/..\/libalpaca\/target\/release\/libalpaca.a -lm
NGX_CONF ?= $(shell \
	nginx -V 2>&1 | \
	grep configure | \
	perl -pe " \
		s/configure arguments://; \
		s/--add-dynamic-module=\S+//g; \
		s/--with-\S+=dynamic//g; \
		s/--with-ld-opt='/--with-ld-opt='$(LD_OPT) / or s/^/--with-ld-opt='$(LD_OPT)' /; \
	" \
)
# $(info NGX_CONF: $(NGX_CONF))
# $(info NGX_MODULES_PATH: $(NGX_MODULES_PATH))


all: $(NGX_DIR)/objs/ngx_http_alpaca_module.so

# we link libalpaca statically so that we don't need to install libalpaca.so
libalpaca/target/release/libalpaca.a: libalpaca/src/*.rs
	cd libalpaca && \
	cargo build --release

$(NGX_DIR)/objs/ngx_http_alpaca_module.so: $(NGX_DIR)/Makefile libalpaca/target/release/libalpaca.a ngx_http_alpaca_module.c
	cd $(NGX_DIR) && make modules

$(NGX_DIR)/Makefile: $(NGX_DIR) config libalpaca/target/release/libalpaca.a
	cd $(NGX_DIR) && ./configure --add-dynamic-module=../.. $(NGX_CONF)

# download nginx source from nginx.org
$(NGX_DIR):
	mkdir -p build
	cd build && (wget -O - https://nginx.org/download/nginx-$(NGX_VER).tar.gz | tar -xzf -)

install: $(NGX_DIR)/objs/ngx_http_alpaca_module.so
ifeq (, $(NGX_MODULES_PATH))
	@echo "\nCannot detect the nginx modules dir, please use:\n\nsudo make install NGX_MODULES_PATH=<path>\n"
else
	cp $(NGX_DIR)/objs/ngx_http_alpaca_module.so $(NGX_MODULES_PATH)
	@echo "\nModule installed, to enable add this to your nginx config:\n"
	@echo "load_module $(NGX_MODULES_PATH)/ngx_http_alpaca_module.so;\n"
endif

clean:
	rm -f libalpaca/target/release/libalpaca.a $(NGX_DIR)/objs/ngx_http_alpaca_module.so  $(NGX_DIR)/Makefile

cleanall:
	rm -rf libalpaca/target $(NGX_DIR)
