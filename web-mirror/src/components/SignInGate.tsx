"use client";

interface Props {
  onSignIn: () => void;
  busy?: boolean;
  error?: string | null;
}

export default function SignInGate({ onSignIn, busy, error }: Props) {
  return (
    <div
      flex="~"
      items="center"
      justify="center"
      p="6"
      className="min-h-screen anim-rise"
    >
      <div w="full" max-w="sm" text="center">
        <div text="lg ink" font="semibold" className="tracking-tight">
          Breakdex <span text="muted" font="normal">mirror</span>
        </div>
        <p text="sm muted" m="t-3" className="leading-relaxed">
          A read-only view of your library — moves, combos, journal and plans,
          streamed from your own Google Drive.
        </p>
        <button
          type="button"
          onClick={onSignIn}
          disabled={busy}
          m="t-6"
          p="x-5 y-2.5"
          rounded="lg"
          bg="ink"
          text="sm white"
          font="medium"
          className="focus-ring hover:opacity-90 transition-opacity disabled:opacity-50"
        >
          {busy ? "Connecting…" : "Sign in with Google"}
        </button>
        {error ? (
          <p text="xs bad" m="t-4" className="anim-rise">
            {error}
          </p>
        ) : null}
        <p text="[11px] faint" m="t-6" className="leading-relaxed">
          Owner-only. Sign-in grants read access to your Breakdex Drive folder —
          nothing else, and it never writes.
        </p>
      </div>
    </div>
  );
}
