import path from "path";
import { fileURLToPath } from "url";

const dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Pin tracing to this app — the parent Flutter repo has its own lockfile.
  outputFileTracingRoot: dirname,
};

export default nextConfig;
