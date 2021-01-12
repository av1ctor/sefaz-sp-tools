rootdir := $(dir $(MAKEFILE_LIST))
targetdir := $(rootdir)/dist

SRC_DIRS := CSV2DDF CSV2OPS
SRC_EXES := CSV2DDF/CSV2DDF.exe CSV2OPS/CSV2OPS.exe
OUT_EXES := $(patsubst %,$(targetdir)/%,$(SRC_EXES))
OUT_DIRS := $(patsubst %,$(targetdir)/%,$(SRC_DIRS))

$(OUT_DIRS): $(OUT_EXES)
	mkdir $(subst /,\,$(dir $@))

$(OUT_EXES): $(SRC_EXES)
	copy $(subst dist\,,$(subst /,\,$(dir $@)/*.exe)) $(subst /,\,$(dir $@))
	copy $(subst dist\,,$(subst /,\,$(dir $@)/*.txt)) $(subst /,\,$(dir $@))

$(SRC_EXES): $(SRC_DIRS)
	cd $(subst /,\,$(dir $@)) && make && cd ..
