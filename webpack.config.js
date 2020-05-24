const path = require('path');
const dotenv = require("dotenv")
const webpack = require("webpack")
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');

dotenv.config({ path: "./lambda/.env" })

module.exports = {
  entry: './src/Index.bs.js',
  output: {
    path: path.join(__dirname, "public/dist"),
    filename: 'bundle.js',
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin(),
    new webpack.EnvironmentPlugin({
      GRAPHQL_ENDPOINT: process.env.GRAPHQL_ENDPOINT,
      SENTRY_DSN: process.env.SENTRY_DSN,
      SENTRY_ENV: process.env.SENTRY_ENV,
    }),
  ],
  devServer: {
    contentBase: path.join(__dirname, 'public/dist'),
    compress: true,
    port: 8000,
  }
} 