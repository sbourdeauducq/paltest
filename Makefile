all: build/paltest.bit

SRC=paltest.v patgen.v

build/paltest.ucf: paltest.ucf
	cp paltest.ucf build/paltest.ucf

build/paltest.prj: $(SRC)
	rm -f build/paltest.prj
	for i in `echo $^`; do \
	    echo "verilog work ../$$i" >> build/paltest.prj; \
	done

build/paltest.ngc: build/paltest.prj
	cd build && xst -ifn ../paltest.xst

build/paltest.ngd: build/paltest.ngc build/paltest.ucf
	cd build && ngdbuild -uc paltest.ucf paltest.ngc

timing: build/paltest-routed.twr

build/paltest.ncd: build/paltest.ngd
	cd build && map -ol high -w paltest.ngd

build/paltest-routed.ncd: build/paltest.ncd
	cd build && par -ol high -w paltest.ncd paltest-routed.ncd

build/paltest.bit: build/paltest-routed.ncd
	cd build && bitgen -g LCK_cycle:6 -w paltest-routed.ncd paltest.bit

build/paltest-routed.twr: build/paltest-routed.ncd
	cd build && trce -e 100 paltest-routed.ncd paltest.pcf

load: build/paltest.bit
	jtag load.batch

clean:
	rm -rf build/*

.PHONY: timing load clean
