DISKPATH:=EFIBOOT
GRUBMODPATH:=/usr/lib/grub/x86_64-efi
SHIMPATH:=/usr/lib/shim
all: grubx64.efi BOOTX64.EFI

install: all
	cp grubx64.efi BOOTX64.EFI $(DISKPATH)/EFI/BOOT

grubx64.unsigned.efi: grub.cfg.embedded modules.lst
	grub-mkstandalone --compress=xz -O x86_64-efi --fonts="unicode" --locales="en@quot" --modules="`cat $(word 2,$^)`" -o "$@" "boot/grub/grub.cfg=$<" -v

grubx64.efi: grubx64.unsigned.efi db.key db.crt
	sbsign --key $(word 2,$^) --cert $(word 3,$^) --output $@ $<

BOOTX64.EFI: $(SHIMPATH)/shimx64.efi db.key db.crt
	sbsign --key $(word 2,$^) --cert $(word 3,$^) --output $@ $<
