### Using UPS with NUT

Setting UPS in our server room is very important in our road map

We got some American Power Conversion(APC) Smart-UPS 2500, which have 8
power socket. We going to use for 4 physical server per UPS, and some switch
or router.

We are using Network UPS Tools (NUT) for UPS management

#### Setting a NUT server

First of all, we need a nut server which directly connected to UPS through USB
cable.

Install NUT

```
apt update
apt install nut
```

Setting Driver

In this model, we can use `usbhid-ups`

/etc/nut/ups.conf

```
[sparky]
	driver = usbhid-ups
	port = auto
	serial = 1234567890
```

Connect to ups

```
# upsdrvctl start sparky
Network UPS Tools - UPS driver controller 2.7.2
Network UPS Tools - Generic HID driver 0.38 (2.7.2)
USB communication driver 0.32
Using subdriver: APC HID 0.95
```

Setting nut-server mode

/etc/nut/nut.conf

```
mode=netserver
```

#### Data server configuration

/etc/nut/upsd.conf

```
LISTEN <your local ip> 3493
```

Restart service

```
systemctl status nut-server
systemctl enable nut-server
```

#### Client Setting


/etc/nut/nut.conf

```
mode=netclient
```

Setting as a netclient in other physical server plug-in UPS

Testing

```
# upsc sparky@192.168.200.30
Init SSL without certificate database
battery.charge: 46
battery.charge.low: 10
battery.charge.warning: 50
battery.mfr.date: 2016/01/27
battery.runtime: 8400
battery.runtime.low: 120
battery.temperature: 25.2
battery.type: PbAc
battery.voltage: 48.6
battery.voltage.nominal: 48.0
device.mfr: American Power Conversion
device.model: Smart-UPS 3000
device.serial: US1605202929
device.type: ups
driver.name: usbhid-ups
driver.parameter.pollfreq: 30
driver.parameter.pollinterval: 2
driver.parameter.port: auto
driver.version: 2.7.2
driver.version.data: APC HID 0.95
driver.version.internal: 0.38
input.sensitivity: high
input.transfer.high: 253
input.transfer.low: 208
input.transfer.reason: input voltage out of range
input.voltage: 0.0
output.current: 0.00
output.frequency: 50.0
output.voltage: 229.6
output.voltage.nominal: 230.0
ups.beeper.status: enabled
ups.delay.shutdown: 20
ups.delay.start: 30
ups.firmware: 655.19.I
ups.firmware.aux: 7.4
ups.load: 0.0
ups.mfr: American Power Conversion
ups.mfr.date: 2016/01/27
ups.model: Smart-UPS 3000
ups.productid: 0002
ups.serial: US1605202929
ups.status: OB DISCHRG
ups.test.result: No test initiated
ups.timer.reboot: -1
ups.timer.shutdown: -1
ups.timer.start: -1
ups.vendorid: 051d
```

for now, we can use upsmon.conf to shutdown machine while UPS report there is no AC power, only use Battery.

`upsmon.conf` is a powerful configuration.


*(unfinished)*
