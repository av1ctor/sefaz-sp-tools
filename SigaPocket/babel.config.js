module.exports = {
  presets: [
    'module:metro-react-native-babel-preset'
  ],
  plugins: [
    ['transform-inline-environment-variables',
      {
        "include": [
          "REACT_VARS"
        ]
      }    
    ]
  ],
  env: {
    production: {
      plugins: ['react-native-paper/babel'],
    },
  },
};
