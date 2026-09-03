/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#0F9B8E', light: '#1ab5a6', dark: '#0c7d72' },
        sidebar: '#0D3B36',
        cream: { DEFAULT: '#F6F5EF', light: '#FBFBF8' },
        pharma: { amber: '#E8A33D', amberLight: '#FEF3DC' },
        softBorder: '#DCE6E2',
      },
      fontFamily: {
        sora: ['Sora', 'sans-serif'],
        inter: ['Inter', 'sans-serif'],
      },
      borderRadius: { card: '12px' },
      boxShadow: {
        card: '0 1px 3px 0 rgba(0,0,0,0.06)',
        modal: '0 20px 60px rgba(0,0,0,0.12)',
      },
    },
  },
  plugins: [],
};
