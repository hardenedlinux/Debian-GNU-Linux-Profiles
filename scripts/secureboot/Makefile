EFITOOLPATH:=/usr/lib/efitools/x86_64-linux-gnu
SIGNEDTOOLS:=$(shell ls $(EFITOOLPATH)|sed 's/efi/signed.efi/g')
DISKPATH:=EFIBOOT

# Prevent make(1) from removing any intermediate targets.
.SECONDARY:

all: auth signedtools

auth: pk.auth kek.auth db.auth dbx.auth nopk.auth

keys: pk.key kek.key db.key dbx.key

%.key:
	certtool -p --bits=2048 --outfile $@

certs: pk.crt kek.crt db.crt dbx.crt

#"$<" is equal to "$(word 1,$^)"
%.crt: %.key %.tmpl
	certtool -s --template $(word 2,$^) --load-privkey $< --outfile $@

uuid:
	uuidgen > $@

%.esl: %.crt uuid
	cert-to-efi-sig-list -g `cat $(word 2,$^)` $< $@

pk.auth: pk.esl pk.key pk.crt
	sign-efi-sig-list -k $(word 2,$^) -c $(word 3,$^) PK $< $@

kek.auth: kek.esl pk.key pk.crt
	sign-efi-sig-list -k $(word 2,$^) -c $(word 3,$^) KEK $< $@

db.auth: db.esl kek.key kek.crt
	sign-efi-sig-list -a -k $(word 2,$^) -c $(word 3,$^) db $< $@

dbx.auth: dbx.esl kek.key kek.crt
	sign-efi-sig-list -a -k $(word 2,$^) -c $(word 3,$^) dbx $< $@

nopk.auth: pk.key pk.crt
	sign-efi-sig-list -k $(word 1,$^) -c $(word 2,$^) PK /dev/null $@

%.signed.efi: $(EFITOOLPATH)/%.efi db.key db.crt
	sbsign --key $(word 2,$^) --cert $(word 3,$^) --output $@ $<

signedtools: $(SIGNEDTOOLS)

install: all
	mkdir -p $(DISKPATH)/EFI/BOOT
	cp *.auth $(DISKPATH)
	cp $(EFITOOLPATH)/*.efi $(DISKPATH)/EFI/BOOT
	cp $(SIGNEDTOOLS) $(DISKPATH)/EFI/BOOT

clean:
	-rm *.esl *.auth $(SIGNEDTOOLS) uuid


