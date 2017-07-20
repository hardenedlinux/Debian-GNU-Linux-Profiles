# Hardening tweaks via CHIPSEC framework:
#	Enabling some security features at runtime in case of which vendor provided implementation improperly

from chipsec.chipset import *


def D_LCK_set():
	# check if BIOS_CNTL register is available
	if not cs.is_register_defined( 'PCI0.0.0_SMRAMC'  ) :
		raise Exception( "Couldn't find SMRAMC")

	regval = cs.read_register( 'PCI0.0.0_SMRAMC')
	d_lock = cs.get_register_field( 'PCI0.0.0_SMRAMC', regval, 'D_LCK')

	if d_lock == 0:
		cs.write_register( 'PCI0.0.0_SMRAMC', 0x1a)
		regval = cs.read_register( 'PCI0.0.0_SMRAMC')
		d_lock = cs.get_register_field( 'PCI0.0.0_SMRAMC', regval, 'D_LCK')
        
		if d_lock == 1:
			print "Enabled D_LCK successfully: SMRAMC: %x; D_LCK: %x" % (regval, d_lock)
	else:
		print "D_LCK is set already!"

def BIOS_WP_set():
	regval = cs.read_register( 'BC')
	ble = cs.get_control( 'BiosLockEnable')
	if ble != 1:
		ble = cs.set_control( 'BiosLockEnable', 1)
		print "BLE is enabled!"
	else:
		print "BLE is set already!"

if __name__ == '__main__':
    	# hardening init...
    	cs = chipsec.chipset.cs()
    	cs.init(None, True)

    	# common.smm
    	D_LCK_set()

	# common.bios_wp
	BIOS_WP_set()
