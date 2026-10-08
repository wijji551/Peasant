# Draws the scroll that every notice is framed with, as one SVG used as a CSS border-image, and writes it into src/shell.html.
import math, random, re, urllib.parse
random.seed(7)
W = H = 340; SL, ST = 100, 110          # slices: left/right, top/bottom
OUT, PAPER, PAPER_D, TAN, BROWN = '#4a2a12', '#edd69d', '#d9b872', '#d9a55a', '#6b3f1a'
f = lambda v: ('%.1f' % v).rstrip('0').rstrip('.')
def ragged(base, a, b, sign, step=6.5):
    """points down (or up) one side; returns to the base line at the slice boundaries so the middle strip tiles"""
    pts, y, marks = [], a, [ST, H - ST]
    while y < b:
        d = 0 if any(abs(y - m) < step * 0.7 for m in marks) or y == a else random.uniform(-3.4, 3.4)
        if d and random.random() < 0.10: d = sign * random.uniform(5, 8)          # a small tear inward
        pts.append((base + d, y)); y += step * random.uniform(0.75, 1.25)
        for m in marks:
            if y - step < m < y: y = m
    pts.append((base, b)); return pts
left = ragged(18, 30, 310, 1); right = ragged(322, 30, 310, -1)
outer = left + right[::-1]
dpath = 'M' + ' L'.join(f(x) + ',' + f(y) for x, y in outer) + ' Z'
side = lambda pts: 'M' + ' L'.join(f(x) + ',' + f(y) for x, y in pts)
hole = 'M30,50 H310 V290 H30 Z'
o = []
A = o.append
A(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
A('<defs>')
A('<linearGradient id="roll" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fbeec2"/><stop offset=".35" stop-color="#eccf8c"/><stop offset=".8" stop-color="#c99a52"/><stop offset="1" stop-color="#a87a3a"/></linearGradient>')
A('<radialGradient id="wax" cx=".36" cy=".3" r=".8"><stop offset="0" stop-color="#e8503f"/><stop offset=".45" stop-color="#b9211b"/><stop offset="1" stop-color="#7f100e"/></radialGradient>')
A('<linearGradient id="shade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a2a12" stop-opacity=".42"/><stop offset="1" stop-color="#4a2a12" stop-opacity="0"/></linearGradient>')
A(f'<clipPath id="pc"><path d="{dpath}"/></clipPath>')
# --- a wax seal
blob = []
for i in range(64):
    t = i / 64 * math.tau; r = 24 + 2.0 * math.sin(7 * t + 1) + 1.1 * math.sin(13 * t + 2) + 0.7 * math.sin(3 * t)
    blob.append((r * math.cos(t), r * math.sin(t)))
bp = 'M' + ' L'.join(f(x) + ',' + f(y) for x, y in blob) + ' Z'
emb = 'M0,-10 C5,-5 5,1 0,5 C-5,1 -5,-5 0,-10 Z M-2,3 C-9,4 -11,-3 -6,-6 M2,3 C9,4 11,-3 6,-6 M-6,8 H6 M0,5 V11'
A(f'<g id="seal"><path d="{bp}" fill="url(#wax)" stroke="#4a0c0a" stroke-width="2.4" stroke-linejoin="round"/><circle r="15.5" fill="none" stroke="#6e0d0b" stroke-width="2.2"/><path d="M-11,-11 A15.5,15.5 0 0 1 9,-12.5" fill="none" stroke="#f08a78" stroke-width="1.4" stroke-linecap="round" opacity=".8"/>'
  f'<path d="{emb}" fill="none" stroke="#6e0d0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="{emb}" fill="none" stroke="#f08a78" stroke-width=".8" stroke-linecap="round" opacity=".55" transform="translate(-.7,-.8)"/>'
  '<path d="M-17,-13 Q-12,-20 -3,-21" fill="none" stroke="#ffb3a3" stroke-width="2" stroke-linecap="round" opacity=".55"/></g>')
# --- knotwork for one corner (top left). Drawn piece by piece, dark then light, so later pieces pass over earlier ones.
def band(pts, wd=5.2, wl=2.5):
    d = 'M' + ' L'.join(f(x) + ',' + f(y) for x, y in pts)
    return f'<path d="{d}" stroke="{BROWN}" stroke-width="{wd}"/><path d="{d}" stroke="{TAN}" stroke-width="{wl}"/>'
cx, cy, s = 51, 74, 4.3
k = ['<g fill="none" stroke-linecap="round" stroke-linejoin="round">']
k.append(band([(cx + 9.6 * math.cos(i / 24 * math.tau), cy + 9.6 * math.sin(i / 24 * math.tau)) for i in range(25)], 4, 1.8))
N = 30
for i in range(N):
    seg = []
    for j in range(5):
        t = (i + j / 4) / N * math.tau + 0.4
        seg.append((cx + s * (math.sin(t) + 2 * math.sin(2 * t)), cy - s * (math.cos(t) - 2 * math.cos(2 * t))))
    k.append(band(seg, 4.6, 2.2))
# tails that run off down the side and along the top, with a curl where they leave the knot
k.append(band([(36, 112), (36, 104), (36.5, 99), (39, 95.5), (43, 95), (45, 98), (43, 101), (40, 100)]))
k.append(band([(102, 58), (88, 58), (83, 58.5), (79.5, 61), (79, 65), (82, 67), (85, 65), (84, 62)]))
k.append('</g>')
A('<g id="knot">' + ''.join(k) + '</g>')
# --- one end of a roller, with its seal
A(f'<g id="rend"><path d="M11,8 Q6,24 11,40" fill="none" stroke="{OUT}" stroke-width="1.6" opacity=".7"/><path d="M15,9 Q11,24 15,39" fill="none" stroke="#fff6d8" stroke-width="1.4" opacity=".6"/>'
  f'<path d="M84,41 l-3,-7 l4,-6 l-2,-6" fill="none" stroke="{OUT}" stroke-width="1.2" opacity=".65" stroke-linejoin="round"/><use xlink:href="#seal" x="42" y="25"/></g>')
A('</defs>')
# --- the paper: only a band round the edge is filled here; the middle is the element's own background, so stains can sit on it
A(f'<path d="{dpath} {hole}" fill="{PAPER}" fill-rule="evenodd"/>')
A(f'<g clip-path="url(#pc)" fill="none" stroke="#a8652a"><path d="{side(left)}" stroke-width="20" opacity=".10"/><path d="{side(right)}" stroke-width="20" opacity=".10"/><path d="{side(left)}" stroke-width="9" opacity=".16"/><path d="{side(right)}" stroke-width="9" opacity=".16"/></g>')
A(f'<path d="{side(left)}" fill="none" stroke="{OUT}" stroke-width="2.6" stroke-linejoin="round"/><path d="{side(right)}" fill="none" stroke="{OUT}" stroke-width="2.6" stroke-linejoin="round"/>')
# cracks, kept inside the corner pieces so they are not repeated along an edge
for d in ['M322,236 l-9,3 l-6,-5 l-10,4 l-5,7', 'M18,246 l8,-3 l5,5 l8,-2', 'M300,52 l-4,8 l5,7 l-3,9', 'M52,290 l3,-9 l-4,-7']:
    A(f'<path d="{d}" fill="none" stroke="{OUT}" stroke-width="1.1" opacity=".5" stroke-linejoin="round" stroke-linecap="round"/>')
# the frame lines along each edge, between the corner knots
A('<g fill="none" stroke-linecap="butt">' + band([(36, 100), (36, 240)]) + band([(304, 100), (304, 240)]) + band([(90, 58), (250, 58)]) + band([(90, 282), (250, 282)]) + '</g>')
A('<use xlink:href="#knot"/><use xlink:href="#knot" transform="translate(340,0) scale(-1,1)"/><use xlink:href="#knot" transform="translate(0,340) scale(1,-1)"/><use xlink:href="#knot" transform="translate(340,340) scale(-1,-1)"/>')
# --- the rollers, top and bottom, with the shadow they throw on the paper
for y0, flip in [(7, False), (299, True)]:
    sy = 41 if not flip else 299
    A(f'<rect x="19" y="{sy if not flip else sy - 9}" width="302" height="9" fill="url(#shade)"' + (f' transform="translate(0,{2 * sy - 9}) scale(1,-1)"' if flip else '') + '/>')
    A(f'<rect x="3" y="{y0}" width="334" height="34" rx="7" fill="url(#roll)" stroke="{OUT}" stroke-width="2.8"/>')
    A(f'<path d="M20,{y0 + 6.5} H320" stroke="#fff8dc" stroke-width="2.2" opacity=".55" stroke-linecap="round"/><path d="M20,{y0 + 27} H320" stroke="{OUT}" stroke-width="1.2" opacity=".22" stroke-linecap="round"/>')
    A(f'<use xlink:href="#rend" transform="translate(0,{y0 - 7})"/><use xlink:href="#rend" transform="translate(340,{y0 - 7}) scale(-1,1)"/>')
A('</svg>')
svg = ''.join(o)
open('tools/scroll.svg', 'w').write(svg)
uri = 'url("data:image/svg+xml,' + urllib.parse.quote(svg, safe=" =:/,;.-_!*'()") + '")'
p = 'src/shell.html'; s = open(p).read()
s2, n = re.subn(r'/\*scroll\*/.*?/\*/scroll\*/', lambda m: '/*scroll*/--scroll:' + uri + ';/*/scroll*/', s, flags=re.S)
assert n == 1, 'marker not found in shell.html'
open(p, 'w').write(s2); print('scroll.svg', len(svg), 'bytes')
