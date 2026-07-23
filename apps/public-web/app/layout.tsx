import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://lappo-app.chatgpt.site"),
  title: {
    default: "Lappo — турбота про тварин",
    template: "%s | Lappo",
  },
  description:
    "Lappo — приватна медична картка тварини, документи, нагадування та оголошення для власників улюбленців.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
  robots: { index: true, follow: true },
  openGraph: {
    type: "website",
    locale: "uk_UA",
    siteName: "Lappo",
    title: "Lappo — усе важливе про здоров’я улюбленця поруч",
    description:
      "Приватна медична картка тварини, документи, нагадування та оголошення для власників улюбленців.",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "Lappo" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Lappo — усе важливе про здоров’я улюбленця поруч",
    description:
      "Приватна медична картка тварини, документи й нагадування.",
    images: ["/og.png"],
  },
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
