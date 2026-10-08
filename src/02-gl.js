// ===== a small WebGL2 renderer: flat-shaded vertex-coloured meshes, instancing, one shadow map, outlines =====
const m4 = () => { const m = new Float32Array(16); m[0] = m[5] = m[10] = m[15] = 1; return m; };
function m4mul(o, a, b) {
  for (let c = 0; c < 4; c++) {
    const b0 = b[c * 4], b1 = b[c * 4 + 1], b2 = b[c * 4 + 2], b3 = b[c * 4 + 3];
    o[c * 4] = a[0] * b0 + a[4] * b1 + a[8] * b2 + a[12] * b3;
    o[c * 4 + 1] = a[1] * b0 + a[5] * b1 + a[9] * b2 + a[13] * b3;
    o[c * 4 + 2] = a[2] * b0 + a[6] * b1 + a[10] * b2 + a[14] * b3;
    o[c * 4 + 3] = a[3] * b0 + a[7] * b1 + a[11] * b2 + a[15] * b3;
  }
  return o;
}
// translate * rotate(yaw ry, then pitch rx, then roll rz) * scale. Local +z faces (sin ry, 0, cos ry).
function m4trs(o, x, y, z, ry, rx, rz, sx, sy, sz) {
  const cb = Math.cos(ry), sb = Math.sin(ry), ca = Math.cos(rx), sa = Math.sin(rx), cc = Math.cos(rz), sc = Math.sin(rz);
  o[0] = (cb * cc + sb * sa * sc) * sx; o[1] = (ca * sc) * sx; o[2] = (-sb * cc + cb * sa * sc) * sx; o[3] = 0;
  o[4] = (-cb * sc + sb * sa * cc) * sy; o[5] = (ca * cc) * sy; o[6] = (sb * sc + cb * sa * cc) * sy; o[7] = 0;
  o[8] = (sb * ca) * sz; o[9] = (-sa) * sz; o[10] = (cb * ca) * sz; o[11] = 0;
  o[12] = x; o[13] = y; o[14] = z; o[15] = 1;
  return o;
}
function m4persp(o, fovy, asp, n, f) { const t = 1 / Math.tan(fovy / 2); o.fill(0); o[0] = t / asp; o[5] = t; o[10] = (f + n) / (n - f); o[11] = -1; o[14] = 2 * f * n / (n - f); return o; }
function m4ortho(o, l, r, b, t, n, f) { o.fill(0); o[0] = 2 / (r - l); o[5] = 2 / (t - b); o[10] = -2 / (f - n); o[12] = -(r + l) / (r - l); o[13] = -(t + b) / (t - b); o[14] = -(f + n) / (f - n); o[15] = 1; return o; }
function m4look(o, ex, ey, ez, tx, ty, tz) {
  let zx = ex - tx, zy = ey - ty, zz = ez - tz, l = Math.hypot(zx, zy, zz); zx /= l; zy /= l; zz /= l;
  let xx = zz, xz = -zx; l = Math.hypot(xx, xz); xx /= l; xz /= l;
  const yx = zy * xz, yy = zz * xx - zx * xz, yz = -zy * xx;
  o[0] = xx; o[1] = yx; o[2] = zx; o[3] = 0; o[4] = 0; o[5] = yy; o[6] = zy; o[7] = 0; o[8] = xz; o[9] = yz; o[10] = zz; o[11] = 0;
  o[12] = -(xx * ex + xz * ez); o[13] = -(yx * ex + yy * ey + yz * ez); o[14] = -(zx * ex + zy * ey + zz * ez); o[15] = 1;
  return o;
}

// --- primitive shapes, as flat lists of triangle corners (counter-clockwise seen from outside)
function quads(q) { const p = []; for (const a of q) p.push(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[0], a[1], a[2], a[6], a[7], a[8], a[9], a[10], a[11]); return p; }
function gBox(w, h, d) {
  const x = w / 2, y = h / 2, z = d / 2;
  return quads([
    [-x, -y, z, x, -y, z, x, y, z, -x, y, z], [x, -y, -z, -x, -y, -z, -x, y, -z, x, y, -z],
    [x, -y, z, x, -y, -z, x, y, -z, x, y, z], [-x, -y, -z, -x, -y, z, -x, y, z, -x, y, -z],
    [-x, y, z, x, y, z, x, y, -z, -x, y, -z], [-x, -y, -z, x, -y, -z, x, -y, z, -x, -y, z]]);
}
function gCyl(rt, rb, h, seg) {
  const p = [], y = h / 2;
  for (let i = 0; i < seg; i++) {
    const a0 = i / seg * TAU, a1 = (i + 1) / seg * TAU, c0 = Math.cos(a0), s0 = Math.sin(a0), c1 = Math.cos(a1), s1 = Math.sin(a1);
    if (rt > 0) p.push(rb * c0, -y, rb * s0, rt * c0, y, rt * s0, rt * c1, y, rt * s1);
    p.push(rb * c0, -y, rb * s0, rt * c1, y, rt * s1, rb * c1, -y, rb * s1);
    if (rt > 0) p.push(0, y, 0, rt * c1, y, rt * s1, rt * c0, y, rt * s0);
    if (rb > 0) p.push(0, -y, 0, rb * c0, -y, rb * s0, rb * c1, -y, rb * s1);
  }
  return p;
}
function gPrism(w, h, d, drop) {   // gabled roof: base on y=0, ridge along z
  const x = w / 2, z = d / 2, y0 = drop || 0, y1 = h + y0;
  const a = [-x, y0, -z], b = [x, y0, -z], c = [x, y0, z], e = [-x, y0, z], r0 = [0, y1, -z], r1 = [0, y1, z];
  const t = [e, c, r1, b, a, r0, b, r0, r1, b, r1, c, a, e, r1, a, r1, r0, a, b, c, a, c, e];
  const p = []; for (const v of t) p.push(v[0], v[1], v[2]); return p;
}
const ICO_V = (() => { const t = (1 + Math.sqrt(5)) / 2, v = [-1, t, 0, 1, t, 0, -1, -t, 0, 1, -t, 0, 0, -1, t, 0, 1, t, 0, -1, -t, 0, 1, -t, t, 0, -1, t, 0, 1, -t, 0, -1, -t, 0, 1], l = Math.hypot(1, t); return v.map(n => n / l); })();
const ICO_I = [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1];
function gIco(r, sy) { const p = []; for (const i of ICO_I) p.push(ICO_V[i * 3] * r, ICO_V[i * 3 + 1] * r * (sy || 1), ICO_V[i * 3 + 2] * r); return p; }
function gQuad() { return [-0.5, -0.5, 0, 0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, 0.5, 0]; }
function gRing(r0, r1, seg) { const p = []; for (let i = 0; i < seg; i++) { const a0 = i / seg * TAU, a1 = (i + 1) / seg * TAU, c0 = Math.cos(a0), s0 = Math.sin(a0), c1 = Math.cos(a1), s1 = Math.sin(a1); p.push(r0 * c0, 0, r0 * s0, r1 * c1, 0, r1 * s1, r1 * c0, 0, r1 * s0, r0 * c0, 0, r0 * s0, r0 * c1, 0, r0 * s1, r1 * c1, 0, r1 * s1); } return p; }

// --- builder: collects coloured parts (and their inflated copies for the outline) into one mesh
const PM = m4(), _bl = m4(), _bm = m4();
function at(x, z, ry) { if (x === undefined) m4trs(PM, 0, 0, 0, 0, 0, 0, 1, 1, 1); else m4trs(PM, x, 0, z, ry || 0, 0, 0, 1, 1, 1); }
class Builder {
  constructor(t, ol) { this.t = t === undefined ? 0.07 : t; this.ol = ol !== false; this.p = []; this.c = []; this.o = []; }
  add(make, x, y, z, color, ry, rx, rz, ol) {
    m4trs(_bl, x, y, z, ry || 0, rx || 0, rz || 0, 1, 1, 1); m4mul(_bm, PM, _bl);
    const m = _bm, g = make(0), r = (color >> 16 & 255) / 255, gg = (color >> 8 & 255) / 255, b = (color & 255) / 255;
    for (let i = 0; i < g.length; i += 3) {
      const a = g[i], e = g[i + 1], d = g[i + 2];
      this.p.push(m[0] * a + m[4] * e + m[8] * d + m[12], m[1] * a + m[5] * e + m[9] * d + m[13], m[2] * a + m[6] * e + m[10] * d + m[14]);
      this.c.push(r, gg, b);
    }
    if (this.ol && ol !== false) {
      const g2 = make(this.t);
      for (let i = 0; i < g2.length; i += 3) {
        const a = g2[i], e = g2[i + 1], d = g2[i + 2];
        this.o.push(m[0] * a + m[4] * e + m[8] * d + m[12], m[1] * a + m[5] * e + m[9] * d + m[13], m[2] * a + m[6] * e + m[10] * d + m[14]);
      }
    }
    return this;
  }
  // box and cyl sit on y (their base); rotations turn them about their own centre
  box(w, h, d, x, y, z, color, ry, rx, rz, ol) { return this.add(t => gBox(w + 2 * t, h + 2 * t, d + 2 * t), x, y + h / 2, z, color, ry, rx, rz, ol); }
  cyl(rt, rb, h, seg, x, y, z, color, ry, rx, rz, ol) { return this.add(t => gCyl(rt + t, rb + t, h + 2 * t, seg), x, y + h / 2, z, color, ry, rx, rz, ol); }
  cone(r, h, seg, x, y, z, color, ry, rx, rz, ol) { return this.add(t => gCyl(0, r + t * 1.5, h + 2.5 * t, seg), x, y + h / 2, z, color, ry, rx, rz, ol); }
  ico(r, x, y, z, color, sy, ol) { return this.add(t => gIco(r + t, sy), x, y, z, color, 0, 0, 0, ol); }
  roof(w, h, d, x, y, z, color, ry) { return this.add(t => gPrism(w + 2 * t, h + 2 * t, d + 2 * t, -t), x, y, z, color, ry); }
}

// --- renderer
const GFX = { gl: null, items: [], pools: [], SM: 2048 };
const L = {                                    // lighting, filled in by setLight()
  vp: m4(), lvp: m4(), view: m4(), proj: m4(), eye: [0, 66, 56], dist: 86,
  sun: [0, 1, 0], sunC: [1, 1, 1], sky: [1, 1, 1], gnd: [0.5, 0.5, 0.5], fog: [0.8, 0.9, 0.7], fogN: 80, fogF: 200,
  pl: new Float32Array(16), plc: new Float32Array(12), emi: [0, 0, 0], glow: [1, 1, 1], outline: [0.17, 0.13, 0.2]
};
const VS_LIT = `#version 300 es
layout(location=0) in vec3 aPos; layout(location=1) in vec3 aNor; layout(location=2) in vec3 aCol;
layout(location=3) in mat4 iMat; layout(location=7) in vec4 iCol;
uniform mat4 uVP,uLVP; out vec3 vN,vC,vW; out vec4 vL;
void main(){ vec4 w=iMat*vec4(aPos,1.); vW=w.xyz; vN=mat3(iMat)*aNor; vC=aCol*iCol.rgb; vL=uLVP*w; gl_Position=uVP*w; }`;
const FS_LIT = `#version 300 es
precision highp float; precision highp sampler2DShadow;
in vec3 vN,vC,vW; in vec4 vL;
uniform vec3 uSun,uSunC,uSky,uGnd,uFog,uCam,uTint,uEmi; uniform float uFogN,uFogF,uUnlit,uAlpha,uTexel;
uniform vec4 uPLp[4]; uniform vec3 uPLc[4]; uniform sampler2DShadow uSM; out vec4 o;
float shadow(){ vec3 p=vL.xyz/vL.w*.5+.5; if(p.x<0.||p.x>1.||p.y<0.||p.y>1.||p.z>1.) return 1.;
  float s=0.; for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) s+=texture(uSM,vec3(p.xy+vec2(float(x),float(y))*uTexel*1.4,p.z-.0016)); return s/9.; }
void main(){ vec3 c;
  if(uUnlit>.5){ c=vC*uTint; }
  else { vec3 n=normalize(vN); vec3 l=mix(uGnd,uSky,n.y*.5+.5); float d=max(dot(n,uSun),0.); if(d>0.) l+=uSunC*d*shadow();
    for(int i=0;i<4;i++){ vec3 dl=uPLp[i].xyz-vW; float dd=length(dl); float a=max(0.,1.-dd/uPLp[i].w); l+=uPLc[i]*a*a*max(dot(n,dl/dd),.2); }
    c=vC*uTint*l+uEmi; }
  float f=clamp((length(vW-uCam)-uFogN)/(uFogF-uFogN),0.,1.); o=vec4(mix(c,uFog,f),uAlpha); }`;
const VS_DEPTH = `#version 300 es
layout(location=0) in vec3 aPos; layout(location=3) in mat4 iMat; uniform mat4 uLVP;
void main(){ gl_Position=uLVP*iMat*vec4(aPos,1.); }`;
const FS_DEPTH = `#version 300 es
precision highp float; void main(){}`;

function initGfx(canvas) {
  const gl = canvas.getContext('webgl2', { antialias: true, alpha: false, powerPreference: 'high-performance' });
  if (!gl) return false;
  GFX.gl = gl; GFX.canvas = canvas;
  const prog = (vs, fs) => {
    const p = gl.createProgram();
    for (const [t, src] of [[gl.VERTEX_SHADER, vs], [gl.FRAGMENT_SHADER, fs]]) {
      const s = gl.createShader(t); gl.shaderSource(s, src); gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s));
      gl.attachShader(p, s);
    }
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(p));
    const u = {}, n = gl.getProgramParameter(p, gl.ACTIVE_UNIFORMS);
    for (let i = 0; i < n; i++) { const nm = gl.getActiveUniform(p, i).name.replace('[0]', ''); u[nm] = gl.getUniformLocation(p, nm); }
    return { p, u };
  };
  GFX.lit = prog(VS_LIT, FS_LIT); GFX.dep = prog(VS_DEPTH, FS_DEPTH);
  // shadow map
  const SM = GFX.SM, tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  gl.texStorage2D(gl.TEXTURE_2D, 1, gl.DEPTH_COMPONENT24, SM, SM);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR); gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE); gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_COMPARE_MODE, gl.COMPARE_REF_TO_TEXTURE); gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_COMPARE_FUNC, gl.LEQUAL);
  const fb = gl.createFramebuffer(); gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, tex, 0);
  gl.drawBuffers([gl.NONE]); gl.readBuffer(gl.NONE);
  gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  GFX.smTex = tex; GFX.smFb = fb;
  // attributes that a mesh does not supply fall back to these values
  gl.vertexAttrib3f(1, 0, 1, 0); gl.vertexAttrib3f(2, 1, 1, 1);
  return true;
}

function mkVao(data, stride, n, instBuf) {       // stride 9 = position, normal, colour; stride 3 = position only
  const gl = GFX.gl, vao = gl.createVertexArray(); gl.bindVertexArray(vao);
  const buf = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, buf); gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
  gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0, 3, gl.FLOAT, false, stride * 4, 0);
  if (stride === 9) { gl.enableVertexAttribArray(1); gl.vertexAttribPointer(1, 3, gl.FLOAT, false, 36, 12); gl.enableVertexAttribArray(2); gl.vertexAttribPointer(2, 3, gl.FLOAT, false, 36, 24); }
  if (instBuf) {
    gl.bindBuffer(gl.ARRAY_BUFFER, instBuf);
    for (let i = 0; i < 4; i++) { gl.enableVertexAttribArray(3 + i); gl.vertexAttribPointer(3 + i, 4, gl.FLOAT, false, 80, i * 16); gl.vertexAttribDivisor(3 + i, 1); }
    gl.enableVertexAttribArray(7); gl.vertexAttribPointer(7, 4, gl.FLOAT, false, 80, 64); gl.vertexAttribDivisor(7, 1);
  }
  gl.bindVertexArray(null);
  return { vao, count: n };
}
function litData(p, c) {                         // adds one flat normal per triangle
  const n = p.length / 3, d = new Float32Array(n * 9);
  for (let i = 0; i < n; i += 3) {
    const a = i * 3, ux = p[a + 3] - p[a], uy = p[a + 4] - p[a + 1], uz = p[a + 5] - p[a + 2], vx = p[a + 6] - p[a], vy = p[a + 7] - p[a + 1], vz = p[a + 8] - p[a + 2];
    let nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx; const l = Math.hypot(nx, ny, nz) || 1; nx /= l; ny /= l; nz /= l;
    for (let k = 0; k < 3; k++) { const s = (i + k) * 3, t = (i + k) * 9; d[t] = p[s]; d[t + 1] = p[s + 1]; d[t + 2] = p[s + 2]; d[t + 3] = nx; d[t + 4] = ny; d[t + 5] = nz; d[t + 6] = c[s]; d[t + 7] = c[s + 1]; d[t + 8] = c[s + 2]; }
  }
  return d;
}
const IDENT = m4();
// a single mesh drawn with one matrix. mode: lit | outline | glow | ghost | bar
function addMesh(b, o) {
  o = o || {};
  const main = Object.assign({ mode: 'lit', cast: true, mat: IDENT, col: [1, 1, 1], tint: [1, 1, 1], alpha: 1, visible: true }, o, mkVao(litData(b.p, b.c), 9, b.p.length / 3));
  if (main.mode !== 'lit') main.cast = false;
  GFX.items.push(main);
  if (b.o.length && o.outline !== false) GFX.items.push(Object.assign({ mode: 'outline', cast: false, mat: IDENT, col: [1, 1, 1], visible: true, of: main }, mkVao(new Float32Array(b.o), 3, b.o.length / 3)));
  return main;
}
// many copies of one mesh, each with its own matrix and colour
function addPool(b, max, o) {
  o = o || {};
  const gl = GFX.gl, buf = gl.createBuffer(), data = new Float32Array(max * 20);
  gl.bindBuffer(gl.ARRAY_BUFFER, buf); gl.bufferData(gl.ARRAY_BUFFER, data.byteLength, gl.DYNAMIC_DRAW);
  const pool = {
    buf, data, n: 0, max, dirty: false, keep: !!o.keep,
    put(m, r, g, bl) { if (this.n >= max) return -1; this.set(this.n, m, r, g, bl); return this.n++; },
    set(i, m, r, g, bl) { const k = i * 20; data.set(m, k); data[k + 16] = r === undefined ? 1 : r; data[k + 17] = g === undefined ? 1 : g; data[k + 18] = bl === undefined ? 1 : bl; data[k + 19] = 1; this.dirty = true; },
    upload() { if (!this.dirty || !this.n) return; gl.bindBuffer(gl.ARRAY_BUFFER, buf); gl.bufferSubData(gl.ARRAY_BUFFER, 0, data, 0, this.n * 20); this.dirty = false; }
  };
  GFX.pools.push(pool);
  const main = Object.assign({ mode: 'lit', cast: true, tint: [1, 1, 1], alpha: 1, visible: true, pool }, o, mkVao(litData(b.p, b.c), 9, b.p.length / 3, buf));
  if (main.mode !== 'lit') main.cast = false;
  GFX.items.push(main);
  if (b.o.length && o.outline !== false) GFX.items.push(Object.assign({ mode: 'outline', cast: false, visible: true, pool }, mkVao(new Float32Array(b.o), 3, b.o.length / 3, buf)));
  return pool;
}
function drawItem(it) {
  const gl = GFX.gl;
  if (it.pool) { if (!it.pool.n) return; gl.bindVertexArray(it.vao); gl.drawArraysInstanced(gl.TRIANGLES, 0, it.count, it.pool.n); return; }
  const src = it.of || it, m = src.mat, c = src.col;
  gl.bindVertexArray(it.vao);
  gl.vertexAttrib4f(3, m[0], m[1], m[2], m[3]); gl.vertexAttrib4f(4, m[4], m[5], m[6], m[7]); gl.vertexAttrib4f(5, m[8], m[9], m[10], m[11]); gl.vertexAttrib4f(6, m[12], m[13], m[14], m[15]);
  gl.vertexAttrib4f(7, c[0], c[1], c[2], 1);
  gl.drawArrays(gl.TRIANGLES, 0, it.count);
}
const MODES = ['lit', 'outline', 'glow', 'fade', 'ghost', 'bar'];   // fade: lit, but see-through (the keep, when something is behind it)
function renderFrame() {
  const gl = GFX.gl, cv = GFX.canvas;
  for (const p of GFX.pools) p.upload();
  gl.enable(gl.DEPTH_TEST); gl.depthMask(true); gl.enable(gl.CULL_FACE); gl.disable(gl.BLEND);
  // shadow pass (back faces, so lit faces do not shadow themselves)
  gl.bindFramebuffer(gl.FRAMEBUFFER, GFX.smFb); gl.viewport(0, 0, GFX.SM, GFX.SM); gl.clear(gl.DEPTH_BUFFER_BIT);
  gl.useProgram(GFX.dep.p); gl.uniformMatrix4fv(GFX.dep.u.uLVP, false, L.lvp); gl.cullFace(gl.FRONT);
  for (const it of GFX.items) if (it.cast && it.visible && (!it.of || it.of.visible)) drawItem(it);
  // main pass
  gl.bindFramebuffer(gl.FRAMEBUFFER, null); gl.viewport(0, 0, cv.width, cv.height);
  gl.clearColor(L.fog[0], L.fog[1], L.fog[2], 1); gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  const u = GFX.lit.u; gl.useProgram(GFX.lit.p);
  gl.uniformMatrix4fv(u.uVP, false, L.vp); gl.uniformMatrix4fv(u.uLVP, false, L.lvp);
  gl.uniform3fv(u.uSun, L.sun); gl.uniform3fv(u.uSunC, L.sunC); gl.uniform3fv(u.uSky, L.sky); gl.uniform3fv(u.uGnd, L.gnd);
  gl.uniform3fv(u.uFog, L.fog); gl.uniform3fv(u.uCam, L.eye); gl.uniform1f(u.uFogN, L.fogN); gl.uniform1f(u.uFogF, L.fogF); gl.uniform1f(u.uTexel, 1 / GFX.SM);
  gl.uniform4fv(u.uPLp, L.pl); gl.uniform3fv(u.uPLc, L.plc);
  gl.activeTexture(gl.TEXTURE0); gl.bindTexture(gl.TEXTURE_2D, GFX.smTex); gl.uniform1i(u.uSM, 0);
  for (const mode of MODES) {
    gl.cullFace(mode === 'outline' ? gl.FRONT : gl.BACK);
    if (mode === 'fade') { gl.enable(gl.BLEND); gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA); }
    if (mode === 'ghost') { gl.enable(gl.BLEND); gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA); gl.depthMask(false); }
    if (mode === 'bar') { gl.disable(gl.BLEND); gl.depthMask(true); gl.disable(gl.DEPTH_TEST); gl.disable(gl.CULL_FACE); }
    gl.uniform1f(u.uUnlit, mode === 'lit' || mode === 'fade' ? 0 : 1);
    for (const it of GFX.items) {
      if (it.mode !== mode || !it.visible || (it.of && (!it.of.visible || it.of.mode === 'fade'))) continue;
      const t = mode === 'outline' ? L.outline : mode === 'glow' ? L.glow : it.tint;
      gl.uniform3fv(u.uTint, t); gl.uniform1f(u.uAlpha, it.alpha === undefined ? 1 : it.alpha);
      gl.uniform3fv(u.uEmi, it.emi ? L.emi : [0, 0, 0]);
      drawItem(it);
    }
  }
  gl.bindVertexArray(null);
}

// --- lighting and camera. nf: 0 = day, 1 = night
const mix3 = (a, b, t) => [lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t)];
const DAYL = { fog: [0.80, 0.86, 0.68], sky: [0.60, 0.60, 0.56], gnd: [0.40, 0.42, 0.37], sunC: [0.52, 0.47, 0.36], sp: [-26, 44, 20] };
const NIGHTL = { fog: [0.07, 0.09, 0.20], sky: [0.27, 0.33, 0.62], gnd: [0.14, 0.16, 0.31], sunC: [0.22, 0.27, 0.48], sp: [22, 46, -16] };
const DUSKL = { fog: [0.90, 0.60, 0.40], sky: [0.74, 0.50, 0.38], gnd: [0.36, 0.27, 0.32], sunC: [0.62, 0.36, 0.20] };
const _lv = m4(), _lp = m4();
function setLight(nf, fx, fz) {
  const k = 4 * nf * (1 - nf);                    // peaks at sunset
  for (const key of ['fog', 'sky', 'gnd', 'sunC']) L[key] = mix3(mix3(DAYL[key], NIGHTL[key], nf), DUSKL[key], k * 0.7);
  const sp = mix3(DAYL.sp, NIGHTL.sp, nf), sl = Math.hypot(sp[0], sp[1], sp[2]);
  L.sun = [sp[0] / sl, sp[1] / sl, sp[2] / sl];
  const tx = Math.round(fx), tz = Math.round(fz - 6);
  m4look(_lv, tx + sp[0] * 1.6, sp[1] * 1.6, tz + sp[2] * 1.6, tx, 0, tz);
  m4ortho(_lp, -56, 56, -56, 56, 1, 190); m4mul(L.lvp, _lp, _lv);
  L.glow = mix3([0.36, 0.30, 0.24], [1.0, 0.80, 0.42], nf);
  L.emi = [0.07 * nf, 0.20 * nf, 0.10 * nf];
  L.fogN = L.dist + lerp(34, 22, nf); L.fogF = L.dist + lerp(190, 150, nf);
  // warm lights at the keep door and the north-gate braziers come up at night
  const pl = [[0, 3.2, -6.2, 20], [-4.4, 2.4, -24.6, 17], [4.4, 2.4, -24.6, 17], [-13.4, 3, -3.6, 13]];
  for (let i = 0; i < 4; i++) { L.pl.set(pl[i], i * 4); const s = nf * (i === 0 ? 0.95 : 0.8); L.plc[i * 3] = 1.0 * s; L.plc[i * 3 + 1] = 0.62 * s; L.plc[i * 3 + 2] = 0.26 * s; }
}
function setCamera(fx, fz, zoom) {
  const cv = GFX.canvas, asp = cv.width / Math.max(1, cv.height);
  const ex = fx, ey = 66 * zoom, ez = fz + 56 * zoom;
  L.eye = [ex, ey, ez]; L.dist = Math.hypot(ey, ez - fz);
  m4look(L.view, ex, ey, ez, fx, 1, fz - 2);
  m4persp(L.proj, 20 * Math.PI / 180, asp, 4, 520);
  m4mul(L.vp, L.proj, L.view);
  L.pitch = Math.atan2(ey - 1, ez - (fz - 2));
}
function project(x, y, z) {                      // world point to CSS pixels
  const m = L.vp, w = m[3] * x + m[7] * y + m[11] * z + m[15];
  const cx = (m[0] * x + m[4] * y + m[8] * z + m[12]) / w, cy = (m[1] * x + m[5] * y + m[9] * z + m[13]) / w;
  return [(cx * 0.5 + 0.5) * innerWidth, (1 - (cy * 0.5 + 0.5)) * innerHeight, w];
}
