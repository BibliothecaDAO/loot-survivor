const { fontFamily } = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}",],
  theme: {
    extend: {
      colors: {
        'terminal-green': '#4AF626',
        'terminal-yellow': '#FFB000',
        'terminal-black': '#151515',
      },
      fontFamily: {
        mono: ['var(--font-vt323)', ...fontFamily.mono],
      },
    },
  },
  plugins: [],
}

