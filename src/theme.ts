import { createTheme } from "@mui/material/styles";

export const theme = createTheme({
  palette: {
    mode: "dark",
    primary: { main: "#3d7bfd" },
    secondary: { main: "#19c37d" },
    background: {
      default: "#10131a",
      paper: "#181c26",
    },
    text: {
      primary: "#e8eaf0",
      secondary: "#9aa3b2",
    },
    divider: "rgba(255, 255, 255, 0.08)",
  },
  typography: {
    fontFamily:
      '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
  },
  shape: { borderRadius: 8 },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: { backgroundColor: "#10131a" },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: "none" },
      },
    },
  },
});
