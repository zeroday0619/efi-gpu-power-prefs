# Based on the sample Makefile from Roderick W. Smith's EFI Hello World
# example:
# https://www.rodsbooks.com/efi-programming/
# (although it has diverged considerably since)
# 
# Use the build-all.sh shell script, in the same directory as this Makefile,
# to build for both x64 and ia32.

ARCH            = $(shell uname -m | sed s,i[3456789]86,ia32,)

TARGET          = gpu-power-prefs-igpu.efi gpu-power-prefs-dgpu.efi 
EFIINC          = /usr/include/efi
EFIINCS         = -I$(EFIINC) -I$(EFIINC)/$(ARCH) -I$(EFIINC)/protocol
LIB             = /usr/lib

ifeq ($(ARCH), x86_64)
    EFILIB	= /usr/lib
else
    EFILIB	= /usr/lib32
endif

EFI_CRT_OBJS    = $(EFILIB)/crt0-efi-$(ARCH).o
EFI_LDS         = $(EFILIB)/elf_$(ARCH)_efi.lds

CFLAGS          = $(EFIINCS) -fno-stack-protector -fpic \
		  -fshort-wchar -mno-red-zone -Wall 
ifeq ($(ARCH), x86_64)
    CFLAGS += -DEFI_FUNCTION_WRAPPER
else
    CFLAGS += -m32
endif

LDFLAGS         = -nostdlib -znocombreloc -T $(EFI_LDS) -shared \
		  -Bsymbolic -L $(EFILIB) -L $(LIB) $(EFI_CRT_OBJS) 

all: $(TARGET)

%.so: %.o
	ld $(LDFLAGS) $^ -o $@ -lefi -lgnuefi

%.efi: %.so
	objcopy -j .text -j .sdata -j .data -j .dynamic \
		-j .dynsym  -j .rel -j .rela -j .reloc \
		--target=efi-app-$(ARCH) $^ $@
	mv -f $@ `echo $@ | sed -e "s/.efi/-$(ARCH).efi/"`

.PHONY: clobber

clobber:
	rm -rf *.o *.so *.efi EFI EFI-verboseboot

install:
	sudo cp -v gpu-power-prefs-?gpu-x86_64.efi /boot/
	sudo cp -v 41_apple_gpu-power-prefs /etc/grub.d/
	: Please regenerate your grub config with "sudo grub-mkconfig -o /boot/grub/grub.cfg"
