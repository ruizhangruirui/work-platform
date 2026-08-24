import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";
import "./language.css";

const geist = Geist({ variable: "--font-geist", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Team Workbench",
  description: "Internal operations workspace for people, cases, tasks and communication.",
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body className={geist.variable}>{children}</body></html>;
}
