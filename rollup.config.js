import resolve from "@rollup/plugin-node-resolve"
import commonjs from "@rollup/plugin-commonjs"
import { terser } from "rollup-plugin-terser"
import coffeescript from 'rollup-plugin-coffee-script'

const terserOptions = {
 mangle: false,
 compress: false,
 format: {
   beautify: true,
   indent_level: 2
 }
}

export default [
  {
    input: "app/javascript/tessa/index.js.coffee",
    output: {
      file: "app/assets/javascripts/tessa.js",
      format: "umd",
      name: "Tessa"
    },
    plugins: [
      resolve(),
      coffeescript(),
      commonjs(),
      terser(terserOptions)
    ]
  },

  {
    input: "app/javascript/tessa/index.js.coffee",
    output: {
      file: "app/assets/javascripts/tessa.esm.js",
      format: "es"
    },
    plugins: [
      resolve(),
      coffeescript(),
      commonjs(),
      terser(terserOptions)
    ]
  }
]
