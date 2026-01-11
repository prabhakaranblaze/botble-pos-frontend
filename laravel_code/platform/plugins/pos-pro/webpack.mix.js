const mix = require('laravel-mix')
const path = require('path')

const directory = path.basename(path.resolve(__dirname))
const source = `platform/plugins/${directory}`
const dist = `public/vendor/core/plugins/${directory}`

mix
    .sass(`${source}/resources/sass/app.scss`, `${dist}/css`)
    .sass(`${source}/resources/sass/receipt.scss`, `${dist}/css`)
    .sass(`${source}/resources/sass/responsive.scss`, `${dist}/css`)
    .sass(`${source}/resources/sass/license-activation.scss`, `${dist}/css`)
    .js(`${source}/resources/js/app.js`, `${dist}/js`)
    .js(`${source}/resources/js/report.js`, `${dist}/js`)
    .js(`${source}/resources/js/receipt.js`, `${dist}/js`)
    .js(`${source}/resources/js/variables.js`, `${dist}/js`)
    .js(`${source}/resources/js/barcode-scanner.js`, `${dist}/js`)
    .js(`${source}/resources/js/responsive.js`, `${dist}/js`)
    .js(`${source}/resources/js/license-activation.js`, `${dist}/js`)
    .js(`${source}/resources/js/clock-calculator.js`, `${dist}/js`)


if (mix.inProduction()) {
    mix
        .copy(`${dist}/js/app.js`, `${source}/public/js`)
        .copy(`${dist}/js/report.js`, `${source}/public/js`)
        .copy(`${dist}/js/receipt.js`, `${source}/public/js`)
        .copy(`${dist}/js/variables.js`, `${source}/public/js`)
        .copy(`${dist}/js/barcode-scanner.js`, `${source}/public/js`)
        .copy(`${dist}/js/responsive.js`, `${source}/public/js`)
        .copy(`${dist}/js/license-activation.js`, `${source}/public/js`)
        .copy(`${dist}/js/clock-calculator.js`, `${source}/public/js`)
        .copy(`${dist}/css/app.css`, `${source}/public/css`)
        .copy(`${dist}/css/receipt.css`, `${source}/public/css`)
        .copy(`${dist}/css/responsive.css`, `${source}/public/css`)
        .copy(`${dist}/css/license-activation.css`, `${source}/public/css`)
}
