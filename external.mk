lib%:
	$(eval srcdir := $@-$($@_vsn))
	@if [ ! -e $($@_tar) ]; then wget -O $($@_tar) $($@_url); fi
	@if [ ! -e $(srcdir) ]; then tar xf $($@_tar); fi
	@if [ ! -e $(srcdir)/config.h ]; then cd $(srcdir) && ./configure --prefix=$(TARGET) --host=$(MAKE_HOST) --build=$(BUILD);  fi
	@if [ ! -e $(TARGET)/lib/$@.a ]; then (make -C $(srcdir) && make -C $(srcdir) install); fi
