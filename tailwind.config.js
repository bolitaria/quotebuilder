const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/assets/**/*.css',
  ],
  theme: {
    extend: {
      colors: {
        'asafe': {
          dark:    '#1a1a1a',   // casi negro, fondos principales
          darker: '#111111',    // hover oscuro
          gray:   '#4b5563',    // texto secundario
          light:  '#f3f4f6',    // fondo de tarjetas
          border: '#e5e7eb',    // bordes suaves
          yellow:  '#f2a900',   // amarillo corporativo
          'yellow-hover': '#d18e00',
        },
      },
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [],
}
