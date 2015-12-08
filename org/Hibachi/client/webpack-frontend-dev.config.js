//example usage: webpack --config webpack-frontend-dev.config.js -p

var devConfig = require('./webpack.config');
var ngAnnotatePlugin = require('ng-annotate-webpack-plugin');

//points to the bootstrap located in the frontend modules directory.
devConfig.app.entry = "./src/frontend/bootstrap.ts";

//change output filename
devConfig.output.filename = "slatwall_frontend_dev.js";
module.exports = devConfig;