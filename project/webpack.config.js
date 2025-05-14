var path = require('path');

var BUILD_DIR = path.resolve(__dirname, 'public');

module.exports = env => {
    const isDev = env.noMini ? true : env.development ? true : false;
    const expMode = env.production ? 'production' : 'development';
    const mini = env.noMini ? false : true;

    console.log('Env = ' + env);
    console.log(env);
    console.log('isDev: ' + isDev);

    return {
        mode: expMode,
        entry: {
            //'index': __dirname + '/index.js'
            index: path.resolve(__dirname, './src/index.js')
        },
        output: {
            //library: "ud-reactquerybuilder",
            library: "udcomponent",
            libraryTarget: "var",
            path: BUILD_DIR,
            filename: isDev ? '[name].bundle.js' : '[name].[fullhash].bundle.js',
            sourceMapFilename: '[name].[fullhash].bundle.map',
            publicPath: ""
        },
        module: {
            rules: [
                {
                    test: /\.(js|jsx)$/,
                    exclude: [/node_modules/, /output/],
                    use: {
                        loader: 'babel-loader',
                        options: {
                            sourceType: "unambiguous",
                            presets: [
                                '@babel/preset-env',
                                '@babel/preset-react'
                              ],
                              plugins: [
                                '@babel/plugin-proposal-class-properties',
                                '@babel/plugin-syntax-dynamic-import'
                              ]
                        }
                    },
                },
                {
                    test: /\.css$/,
                    use: ['style-loader', 'css-loader']

                },
                {
                    test: /\.(eot|ttf|woff2?|otf|svg|png)$/,
                    use: {
                        loader: 'file-loader',
                        options: {
                            name: '[name].[ext]'
                        }
                    }
                }
            ]
        },
        externals: {
            UniversalDashboard: 'UniversalDashboard',
            $: "$",
            'react': 'react',
            'react-dom': 'reactdom'
        },
        resolve: {
            extensions: ['.json', '.js', '.jsx']
        },
        devtool: 'source-map',
        optimization: {
            minimize: mini
        },
        devServer: {
            disableHostCheck: true,
            historyApiFallback: true,
            port: 10000,
            // hot: true,
            compress: true,
            publicPath: '/',
            //stats: "minimal"
        },
    };
}