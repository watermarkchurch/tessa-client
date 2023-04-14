import resolve from "@rollup/plugin-node-resolve"
import commonjs from "@rollup/plugin-commonjs"
import { terser } from "rollup-plugin-terser"
import typescript from "@rollup/plugin-typescript"

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
    input: "app/javascript/tessa/index.ts",
    output: {
      file: "app/assets/javascripts/tessa.js",
      format: "umd",
      name: "Tessa"
    },
    plugins: [
      resolve(),
      typescript(),
      commonjs(),
      terser(terserOptions)
    ]
  },

  {
    input: "app/javascript/tessa/index.ts",
    output: {
      file: "app/assets/javascripts/tessa.esm.js",
      format: "es"
    },
    plugins: [
      resolve(),
      typescript(),
      commonjs(),
      terser(terserOptions)
    ]
  }
]
