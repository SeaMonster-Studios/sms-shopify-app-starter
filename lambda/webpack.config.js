const path = require('path');
const slsw = require('serverless-webpack');


module.exports = {
  entry: slsw.lib.entries,
  mode: "development",
  resolve: {
    extensions: [
      '.js',
    ]
  },
  output: {
    libraryTarget: 'commonjs',
    path: path.join(__dirname, '.webpack'),
    filename: '[name].js',
  },
  target: 'node',
};