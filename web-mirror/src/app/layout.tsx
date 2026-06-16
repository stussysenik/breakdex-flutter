import type { Metadata } from "next";
import { Inter, IBM_Plex_Mono } from "next/font/google";
import "@unocss/reset/tailwind.css";
import "./uno.generated.css";
import "./globals.css";

const sans = Inter({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
});

const mono = IBM_Plex_Mono({
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Breakdex — Library Mirror",
  description: "Read-only mirror of your Breakdex library, from your own Drive.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${sans.variable} ${mono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
