import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  preview: {
    allowedHosts: ["masar-drd8.onrender.com"],
    host: "0.0.0.0"
  }
});
