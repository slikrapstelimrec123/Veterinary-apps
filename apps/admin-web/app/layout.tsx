import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Lappo — внутрішня аналітика",
  description: "Захищена панель аналітики клієнтів, тварин і монетизації Lappo.",
  robots: { index: false, follow: false },
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="uk">
      <body>{children}</body>
    </html>
  );
}
