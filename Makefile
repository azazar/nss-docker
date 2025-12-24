VERSION=$(shell git describe --tags --abbrev=0 2>/dev/null || echo "dev")

.PHONY: install uninstall clean

libnss_docker.so: *.go
	go build -o libnss_docker.so -buildmode=c-shared -ldflags '-extldflags "-Wl,-soname,libnss_docker.so.2"'

# dirty hack to avoid needing autoconf
# would be nice to also get SONAME dynamically
install: libnss_docker.so
	$(eval TARGET := $(shell dirname $(shell ldd libnss_docker.so | grep libc.so | awk '{ print $$3 }')))
	install -D libnss_docker.so $(DESTDIR)$(TARGET)/libnss_docker-$(VERSION).so

uninstall:
	$(eval TARGET := $(shell dirname $(shell ldd /lib/x86_64-linux-gnu/libc.so.6 2>/dev/null || echo /usr/lib)))
	rm -f $(DESTDIR)$(TARGET)/libnss_docker-$(VERSION).so

clean:
	rm -f libnss_docker.so libnss_docker.h
