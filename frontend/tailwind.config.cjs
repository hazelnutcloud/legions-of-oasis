module.exports = {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      animation: {
        'oscillate-vertical': 'oscillate 1s alternate infinite ease-in-out'
      },
      keyframes: {
        oscillate: {
          "to": { transform: 'translateY(-1rem)' },
        }
      }
    },
  },
  plugins: [require("@tailwindcss/typography"), require("daisyui")],
  daisyui: {
    themes: [
      "night",
      {
        cupcake: {
          ...require("daisyui/src/colors/themes")["[data-theme=cupcake]"],
          "--rounded-btn": "0.5rem"
        }
      }
    ],
  }
}
