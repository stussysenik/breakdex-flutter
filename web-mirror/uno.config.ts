import { defineConfig, presetWind3, presetAttributify } from "unocss";

// Utility-first (Tachyons-spirit) styling via UnoCSS. attributify mode keeps
// markup content-first: style lives in grouped attributes (`flex="~ items-center"`,
// `text="sm muted"`) rather than long className strings.
export default defineConfig({
  presets: [presetWind3(), presetAttributify({ strict: false })],
  theme: {
    colors: {
      ink: "#16191e",
      muted: "#79828e",
      faint: "#aab2bc",
      line: "#e7eaef",
      surface: "#f5f7f9",
      accent: "#2f7ef0",
      good: "#1a9456",
      warn: "#b07814",
      bad: "#d2403f",
    },
    fontFamily: {
      sans: "var(--font-sans), system-ui, sans-serif",
      mono: "var(--font-mono), ui-monospace, monospace",
    },
  },
  shortcuts: {
    // Accessible, consistent focus ring for any interactive element.
    "focus-ring":
      "outline-none focus-visible:ring-2 focus-visible:ring-accent/60 focus-visible:ring-offset-2 focus-visible:ring-offset-white",
  },
});
