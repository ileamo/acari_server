const path = require('path');
const glob = require('glob');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const webpack = require('webpack');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
      './js/app.js': ['./js/app.js'].concat(glob.sync('./vendor/**/*.js'))
  },
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },

  resolve: {
     alias: {
         "./images/layers.png$": path.resolve(
             __dirname,
             "./node_modules/leaflet/dist/images/layers.png"
         ),
         "./images/layers-2x.png$": path.resolve(
             __dirname,
             "./node_modules/leaflet/dist/images/layers-2x.png"
         ),
         "./images/marker-icon.png$": path.resolve(
             __dirname,
             "./node_modules/leaflet/dist/images/marker-icon.png"
         ),
         "./images/marker-icon-2x.png$": path.resolve(
             __dirname,
             "./node_modules/leaflet/dist/images/marker-icon-2x.png"
         ),
         "./images/marker-shadow.png$": path.resolve(
             __dirname,
             "./node_modules/leaflet/dist/images/marker-shadow.png"
         )
     }
  },


  module: {
    rules: [
      {
        test: /datatables\.net.*/,
        loader: 'imports-loader?define=>false'
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.scss$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader']
      },
      {
        test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
        use: [{
          loader: 'file-loader',
          options: {
            name: '[name].[ext]',
            outputPath: '../fonts'
          }
        }]
      },

      {
        test: /\.(jpg|png|gif)$/,
        loader: "file-loader",
        options: {
          name: "[name].[ext]",
          outputPath: "../images/"
        }
      }



    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
    new webpack.ProvidePlugin({
        $: "jquery",
        jQuery: "jquery",
        'window.jQuery': 'jquery',
        'window.$': 'jquery'
    }),
  ]
});
