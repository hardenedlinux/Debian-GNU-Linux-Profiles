# Hardening tweaks via CHIPSEC framework:
#	Enabling some security features at runtime in case of which vendor provided implementation improperly.
# WARNING: Please note that this script might put your prodcution at risk

from chipsec.chipset import *
from chipsec.hal.interrupts import *

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
        bioswe = cs.get_control( 'BiosWriteEnable')
        smm_bwp = cs.get_control( 'SmmBiosWriteProtection')

	if ble != 1 or bioswe != 0 or smm_bwp!= 1:
		bioswe = cs.set_control( 'BiosWriteEnable', 0)
		ble = cs.set_control( 'BiosLockEnable', 1)
                smm_bwp = cs.set_control( 'SmmBiosWriteProtection', 1)
		print "BLE | BIOSWE | SMM_BWP are looking good!"
	else:
		print "BLE is set already!"

def BIOS_TS_set():
        bild = cs.get_control( 'BiosInterfaceLockDown')

        if bild != 1:
                cs.set_control( 'BiosInterfaceLockDown', 1)
                print "BiosInterfaceLockDown (BILD) is enabled!"
        else:
                print "BILD is set already!"

def TSEG_LOCK_set():
        tseg_base_lock = cs.get_control( 'TSEGBaseLock')
        tseg_limit_lock = cs.get_control( 'TSEGLimitLock')

        if tseg_base_lock !=1 or tseg_limit_lock !=1:
                cs.set_control( 'TSEGBaseLock', 1)
                cs.set_control( 'TSEGLimitLock', 1)
                print "TSEGBase & TSEGLimit are locked!"
        else:
                print"TSEGBase & TSEGLimit are set already!"

def SPI_LOCK_set():
        flockdn = cs.get_control( 'FlashLockDown')

        if flockdn != 1:
                cs.set_control( 'FlashLockDown', 1)
                print "FLOCKDN is locked!"
        else:
                print "FLOCKDN is set already!"

def BIOS_SMI_set():
        tco_en = cs.get_control( 'TCOSMIEnable')
        gbl_smi_en = cs.get_control( 'GlobalSMIEnable')
        tco_lock = cs.get_control( 'TCOSMILock')
        smi_lock = cs.get_control( 'SMILock')

        if tco_en != 1 or gbl_smi_en != 1:
                return -1
        elif tco_lock != 1 or smi_lock != 1:
                cs.set_control( 'TCOSMILock', 1)
                cs.set_control( 'SMILock', 1)
                print "TCO/SMI are locked!"
        else:
                print "TCO/SMI are set already!"

def memconfig_LOCK_set():
        interrupts = Interrupts( cs)
        interrupts.send_SMI_APMC( 0xcb, 0xb2)

def rtclock_set():
        rc_reg = cs.read_register( 'RC')
        ll = cs.get_register_field( 'RC', rc_reg, 'LL')
        ul = cs.get_register_field( 'RC', rc_reg, 'UL')
        print rc_reg

        if ll != 1 or ul != 1:
                cs.write_register_field( 'RC', 'LL', 1)
                cs.write_register_field( 'RC', 'UL', 1)
        else:
                print "rtclock is set already!"

if __name__ == '__main__':
    	# hardening init...
    	cs = chipsec.chipset.cs()
    	cs.init(None, None, True)

    	# common.smm
    	D_LCK_set()

	# common.bios_wp
	BIOS_WP_set()

        # common.bios_ts
        BIOS_TS_set()

        # smm_dma
        TSEG_LOCK_set()

        # common.spi_lock
        SPI_LOCK_set()

        # common.bios_smi
        BIOS_SMI_set()

        # common.memconfig
        memconfig_LOCK_set()

        # common.rtclock
        rtclock_set()
