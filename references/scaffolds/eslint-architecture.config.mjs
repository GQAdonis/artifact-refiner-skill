// eslint-architecture.config.mjs
//
// Flat-config snippet enforcing the state-architecture rules from
// `references/scaffolds/state-architecture.md`.
//
// The scaffolder either creates a new `eslint.config.mjs` from this template
// or extends the project's existing one with these `files` + `rules` blocks.
//
// You can customize per project — these are starter rules, not gospel — but
// the default is the strict three-layer dependency rule.

import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,

  // ----------------------------------------------------------------------
  // Components: cannot import from stores or services
  // ----------------------------------------------------------------------
  {
    files: ["src/**/components/**/*.{ts,tsx}", "src/app/*.tsx"],
    rules: {
      "no-restricted-imports": ["error", {
        patterns: [
          {
            group: ["**/stores/*", "**/stores/**"],
            message:
              "Components must consume state via a hook. Import from `../hooks/<hook>` not the store.",
          },
          {
            group: ["**/services/*", "**/services/**", "axios", "ky"],
            message:
              "Components must not perform I/O. Move the call into a store action and consume via a hook.",
          },
          {
            group: ["@supabase/*", "socket.io-client", "partysocket"],
            message:
              "Components must not create realtime subscriptions. Lift to a store's initRealtime() action.",
          },
        ],
      }],
    },
  },

  // ----------------------------------------------------------------------
  // Hooks: cannot import services or perform I/O directly
  // ----------------------------------------------------------------------
  {
    files: ["src/**/hooks/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": ["error", {
        patterns: [
          {
            group: ["**/services/*", "**/services/**", "axios", "ky"],
            message:
              "Hooks must not perform I/O. Lift the call into a store action.",
          },
          {
            group: ["@supabase/*", "socket.io-client", "partysocket"],
            message:
              "Hooks must not create realtime subscriptions. Lift to a store's initRealtime() action.",
          },
        ],
      }],
      // Hooks may not call fetch / WebSocket directly either; this rule is
      // best-enforced by code review, but we can lint a common variant:
      "no-restricted-globals": ["error",
        { name: "fetch", message: "Hooks must not call fetch. Lift into a store action." },
        { name: "WebSocket", message: "Hooks must not open WebSocket connections. Lift into a store." },
        { name: "EventSource", message: "Hooks must not open SSE connections. Lift into a store." },
      ],
    },
  },

  // ----------------------------------------------------------------------
  // Stores: cannot import React (framework-agnostic state)
  // ----------------------------------------------------------------------
  {
    files: ["src/**/stores/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": ["error", {
        paths: [
          {
            name: "react",
            message:
              "Stores must be framework-agnostic. Move React-specific logic into hooks.",
          },
          {
            name: "react-dom",
            message: "Stores must be framework-agnostic. Move React-specific logic into hooks.",
          },
        ],
        patterns: [
          {
            group: ["**/components/**"],
            message: "Stores must not import from components. Layering violation.",
          },
        ],
      }],
    },
  },
);
