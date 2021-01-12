AUTOIT := "C:\Program Files (x86)\AutoIt3\aut2exe\Aut2exe_x64.exe"

exename := CSV2OPS

rootdir := $(dir $(MAKEFILE_LIST))
srcdir := $(rootdir)
bindir := $(rootdir)/..

SRC_FILE := $(exename).au3
OUTPUT_EXE := $(bindir)/$(exename).exe

$(OUTPUT_EXE): $(SRC_FILE)
	$(AUTOIT) /in $< /out $(notdir $@) /console
	move "$(subst /,\,$(notdir $@))" "$(subst /,\,$(bindir))"