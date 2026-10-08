// Playwright from this project if it is installed (npm i -D playwright), otherwise from the machine these tests were first written on.
try { module.exports = require('playwright'); } catch (e) { module.exports = require('/opt/npm-tools/node_modules/playwright'); }
