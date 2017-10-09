DISKPATH:=EFIBOOT
GRUBMODPATH:=/usr/lib/grub/i386-coreboot
all: grub.elf

grub.elf: grub.cfg.embedded modules.lst instmod.lst font.pf2
	grub-mkstandalone -O i386-coreboot --fonts=$(FONTS) --locales=$(LOCALES) --modules="`cat $(word 2,$^)`" --install-modules="`cat $(word 3,$^)`" -o "$@" "boot/grub/grub.cfg=$<" "font.pf2=$(word 4,$^)" -v

grub.sec.elf: grub.sec.cfg.embedded modules.lst instmod.lst font.pf2
	grub-mkstandalone -O i386-coreboot --fonts=$(FONTS) --locales=$(LOCALES) --modules="`cat $(word 2,$^)`" --install-modules="`cat $(word 3,$^)`" -o "$@" "boot/grub/grub.cfg=$<" "font.pf2=$(word 4,$^)" -v

font.pf2: font.ttf
	grub-mkfont -o $@ $<

clean:
	-rm grub.elf font.pf2
