# Hilfe für die Bildkontrolle: Ausschnitt eines Simulator-PNG (8 Bit RGB, ohne Filter) vergrössern. Aufruf: zuschnitt.py ein.png aus.png x y b h faktor
import sys, zlib, struct
ein, aus, x0, y0, b, h, f = sys.argv[1], sys.argv[2], *map(int, sys.argv[3:8])
d = open(ein, 'rb').read(); p = 8; idat = b''
while p < len(d):
    n, k = struct.unpack('>I4s', d[p:p+8])
    if k == b'IHDR': W, H = struct.unpack('>II', d[p+8:p+16])
    if k == b'IDAT': idat += d[p+8:p+8+n]
    p += 12 + n
roh = zlib.decompress(idat); zl = W * 3 + 1
rows = []
for y in range(y0, y0 + h):
    z = roh[y*zl+1:(y+1)*zl]
    zeile = b''.join(z[x*3:x*3+3] * f for x in range(x0, x0 + b))
    rows += [b'\x00' + zeile] * f
def st(k, c): return struct.pack('>I', len(c)) + k + c + struct.pack('>I', zlib.crc32(k + c))
open(aus, 'wb').write(b'\x89PNG\r\n\x1a\n' + st(b'IHDR', struct.pack('>IIBBBBB', b*f, h*f, 8, 2, 0, 0, 0)) + st(b'IDAT', zlib.compress(b''.join(rows))) + st(b'IEND', b''))
