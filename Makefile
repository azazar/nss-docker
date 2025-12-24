VERSION=$(shell git describe --tags --abbrev=0 2>/dev/null || echo dev)
LIBDIR?=/lib/x86_64-linux-gnu
NSSWITCH=/etc/nsswitch.conf
CONFIG_SRC=config.json
CONFIG_DST=/etc/nss_docker.json
LIB_NAME=libnss_docker
LIB_VERSIONED=$(LIB_NAME)-$(VERSION).so
LIB_SONAME=$(LIB_NAME).so.2

.PHONY: build install uninstall clean check-install check-uninstall reinstall

build: $(LIB_NAME).so

$(LIB_NAME).so: *.go
	go build -o $@ -buildmode=c-shared -ldflags '-extldflags "-Wl,-soname,$(LIB_SONAME)"'

check-install:
	! ls $(DESTDIR)$(LIBDIR)/$(LIB_NAME)*.so* >/dev/null 2>&1
	test ! -f "$(DESTDIR)$(CONFIG_DST)"
	! grep -q '\bdocker\b' $(NSSWITCH)

check-uninstall:
	test -f "$(DESTDIR)$(LIBDIR)/$(LIB_SONAME)"
	test -f "$(DESTDIR)$(CONFIG_DST)"

install: $(LIB_NAME).so check-install
	install -m 755 $(LIB_NAME).so $(DESTDIR)$(LIBDIR)/$(LIB_VERSIONED)
	ln -sf $(LIB_VERSIONED) $(DESTDIR)$(LIBDIR)/$(LIB_SONAME)
	install -m 644 $(CONFIG_SRC) $(DESTDIR)$(CONFIG_DST)
	sed -i 's/^\(hosts:.*files\)/\1 docker/' $(NSSWITCH)

uninstall: check-uninstall
	rm -f $(DESTDIR)$(LIBDIR)/$(LIB_VERSIONED)
	rm -f $(DESTDIR)$(LIBDIR)/$(LIB_SONAME)
	rm -f $(DESTDIR)$(CONFIG_DST)
	sed -i 's/ docker//' $(NSSWITCH)

reinstall: uninstall install

clean:
	rm -f $(LIB_NAME).so $(LIB_NAME).h
