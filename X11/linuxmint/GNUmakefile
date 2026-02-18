TARGETFILES:=evdev.lst.patch evdev.xml.patch

all: $(TARGETFILES)

%.patch: % %.base
	diff --label="$<.base" --label="$<.patched" --unified=10 $<.base $<|tee $@

rebuild: clean all

clean:
	rm -f $(TARGETFILES)

.PHONY: all clean rebuild
.NOTPARALLEL: rebuild clean
