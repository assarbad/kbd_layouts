TARGETFILES:=evdev.lst.patch evdev.xml.patch

all: $(TARGETFILES)

%.patch: % %.base
	diff --label="$<.base" --label="$<.patched" -u $<.base $<|tee $@

rebuild: clean all

clean:
	rm -f $(TARGETFILES)

.PHONY: all clean rebuild
.NOTPARALLEL: rebuild clean
