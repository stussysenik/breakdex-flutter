// Owner allowlist — only these emails may view the mirror. A signed-in account
// not on the list is rejected before any Drive request is made.

export function ownerAllowlist(): string[] {
  return (process.env.NEXT_PUBLIC_OWNER_ALLOWLIST ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
}

export function isOwner(email: string | null | undefined): boolean {
  if (!email) return false;
  return ownerAllowlist().includes(email.toLowerCase());
}
