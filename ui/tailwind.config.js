const { fontFamily } = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}",],
  theme: {
    extend: {
      colors: {
        'terminal-green': 'rgba(74, 246, 38, 1)', // base UI green
        'terminal-green-75': 'rgba(74, 246, 38, 0.75)', // 70% opacity
        'terminal-green-50': 'rgba(74, 246, 38, 0.5)', // 50% opacity
        'terminal-green-25': 'rgba(74, 246, 38, 0.25)', // 25% opacity
        'terminal-yellow': 'rgba(255, 176, 0, 1)', // base UI yellow
        'terminal-yellow-50': 'rgba(255, 176, 0, 0.5)', // 50% opacity
        'terminal-black': 'rgba(21, 21, 21, 1)', // 50% opacity,
      },
      backgroundImage: {
        conic: 'conic-gradient(var(--tw-gradient-stops))',
        'conic-to-t': 'conic-gradient(at top, var(--tw-gradient-stops))',
        'conic-to-b': 'conic-gradient(at bottom, var(--tw-gradient-stops))',
        'conic-to-l': 'conic-gradient(at left, var(--tw-gradient-stops))',
        'conic-to-r': 'conic-gradient(at right, var(--tw-gradient-stops))',
        'conic-to-tl': 'conic-gradient(at top left, var(--tw-gradient-stops))',
        'conic-to-tr': 'conic-gradient(at top right, var(--tw-gradient-stops))',
        'conic-to-bl':
          'conic-gradient(at bottom left, var(--tw-gradient-stops))',
        'conic-to-br':
          'conic-gradient(at bottom right, var(--tw-gradient-stops))',
        radial: 'radial-gradient(ellipse at center, var(--tw-gradient-stops))',
        'radial-at-t':
          'radial-gradient(ellipse at top, var(--tw-gradient-stops))',
        'radial-at-b':
          'radial-gradient(ellipse at bottom, var(--tw-gradient-stops))',
        'radial-at-l':
          'radial-gradient(ellipse at left, var(--tw-gradient-stops))',
        'radial-at-r':
          'radial-gradient(ellipse at right, var(--tw-gradient-stops))',
        'radial-at-tl':
          'radial-gradient(ellipse at top left, var(--tw-gradient-stops))',
        'radial-at-tr':
          'radial-gradient(ellipse at top right, var(--tw-gradient-stops))',
        'radial-at-bl':
          'radial-gradient(ellipse at bottom left, var(--tw-gradient-stops))',
        'radial-at-br':
          'radial-gradient(ellipse at bottom right, var(--tw-gradient-stops))',
      },
      fontFamily: {
        mono: ['var(--font-vt323)', ...fontFamily.mono],
      },
      fontSize: {
        xxs: '0.5rem',
      },
      inset: {
        '1/8': '12.5%',
        '3/8': '37.5%',
        '1/16': '6.25%',
      },
      textShadow: {
        'none': 'none',  // This line removes the text shadow
      },
      animation: {
        pulseFast: 'pulse 0.5s cubic-bezier(0.4, 0, 0.6, 1) infinite'
      }
    },
  },
  plugins: [
    function({ addUtilities }) {
      const newUtilities = {
        '.text-shadow-none': {
          textShadow: 'none',
        },
        // You can add more custom text shadow utilities here...
      }
      addUtilities(newUtilities)
    }
  ],
}

