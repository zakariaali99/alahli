import { defineConfig, globalIgnores } from "eslint/config"
import pluginReact from "eslint-plugin-react"
import pluginReactHooks from "eslint-plugin-react-hooks"

export default defineConfig([
  pluginReact.configs.flat.recommended,
  pluginReactHooks.configs["recommended-latest"],
  globalIgnores(["node_modules/**", "dist/**", ".next/**"]),
  {
    rules: {
      "react/react-in-jsx-scope": "off",
    },
    settings: {
      react: { version: "detect" },
    },
  },
])
