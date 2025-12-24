/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#2563EB',
        secondary: '#000000',
        tertiary: '#FFFFFF',
      },
    },
  },
  plugins: [],
}
