// Joins the source files into the one HTML file that gets played.
const fs = require('fs'), path = require('path');
const dir = path.join(__dirname, 'src');
const js = fs.readdirSync(dir).filter(f => f.endsWith('.js')).sort().map(f => fs.readFileSync(path.join(dir, f), 'utf8')).join('\n');
fs.mkdirSync(path.join(__dirname, 'out'), { recursive: true });
fs.writeFileSync(path.join(__dirname, 'out', 'bundle.js'), "(() => {'use strict';\n" + js + '\n})();');
require('child_process').execFileSync(process.execPath, ['--check', path.join(__dirname, 'out', 'bundle.js')], { stdio: 'inherit' });
if (js.includes('</script')) throw new Error('script would close early');
const html = fs.readFileSync(path.join(dir, 'shell.html'), 'utf8').replace('/*__JS__*/', () => js);
fs.mkdirSync(path.join(__dirname, 'out'), { recursive: true });
fs.writeFileSync(path.join(__dirname, 'out', 'defend-the-village.html'), html);
fs.writeFileSync(path.join(__dirname, 'out', 'index.html'), html);            // the same file under the name a web server looks for
fs.rmSync(path.join(__dirname, 'out', 'bundle.js'));
console.log('built', (html.length / 1024).toFixed(1) + ' KB');
