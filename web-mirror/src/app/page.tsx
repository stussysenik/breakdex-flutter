"use client";

import { useCallback, useEffect, useState } from "react";
import SignInGate from "@/components/SignInGate";
import Mirror from "@/components/Mirror";
import { isOwner } from "@/lib/allowlist";
import {
  getFirebaseAuth,
  readFirebaseConfig,
  signInWithGoogle,
  signOut,
} from "@/lib/firebase";
import { loadFromDrive } from "@/lib/drive";
import { loadDemo } from "@/lib/demo";
import type { MirrorData } from "@/lib/types";

type Phase =
  | "init"
  | "needConfig"
  | "signedOut"
  | "loading"
  | "ready"
  | "error";

function Centered({ children }: { children: React.ReactNode }) {
  return (
    <div
      flex="~"
      items="center"
      justify="center"
      p="6"
      text="sm muted center"
      className="min-h-screen anim-rise"
    >
      <div max-w="sm">{children}</div>
    </div>
  );
}

export default function Page() {
  const [phase, setPhase] = useState<Phase>("init");
  const [data, setData] = useState<MirrorData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [isDemo, setIsDemo] = useState(false);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get("demo") === "1") {
      setIsDemo(true);
      setPhase("loading");
      loadDemo()
        .then((d) => {
          setData(d);
          setPhase("ready");
        })
        .catch((e) => {
          setError(e instanceof Error ? e.message : String(e));
          setPhase("error");
        });
      return;
    }
    const config = readFirebaseConfig();
    setPhase(config ? "signedOut" : "needConfig");
  }, []);

  const handleSignIn = useCallback(async () => {
    const config = readFirebaseConfig();
    if (!config) {
      setPhase("needConfig");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const auth = getFirebaseAuth(config);
      const { email, accessToken } = await signInWithGoogle(auth);
      if (!isOwner(email)) {
        await signOut(auth);
        setError(
          `${email ?? "This account"} is not on the owner allowlist — access denied.`,
        );
        setPhase("signedOut");
        return;
      }
      if (!accessToken) {
        setError("Signed in, but Google returned no Drive token. Try again.");
        setPhase("signedOut");
        return;
      }
      setPhase("loading");
      const loaded = await loadFromDrive(accessToken);
      setData(loaded);
      setPhase("ready");
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
      setPhase("signedOut");
    } finally {
      setBusy(false);
    }
  }, []);

  const handleSignOut = useCallback(async () => {
    const config = readFirebaseConfig();
    if (config) {
      try {
        await signOut(getFirebaseAuth(config));
      } catch {
        /* ignore */
      }
    }
    setData(null);
    setPhase("signedOut");
  }, []);

  if (phase === "init") {
    return <Centered>Loading…</Centered>;
  }

  if (phase === "needConfig") {
    return (
      <Centered>
        <div text="base ink" font="semibold">
          Breakdex mirror
        </div>
        <p m="t-3" className="leading-relaxed">
          Not configured. Set the Firebase env vars (see{" "}
          <code bg="surface" p="x-1" rounded="sm" className="text-ink">
            .env.example
          </code>
          ) then reload. To preview without credentials, open{" "}
          <code bg="surface" p="x-1" rounded="sm" className="text-ink">
            ?demo=1
          </code>
          .
        </p>
      </Centered>
    );
  }

  if (phase === "loading") {
    return <Centered>Loading your library…</Centered>;
  }

  if (phase === "error") {
    return (
      <Centered>
        <p text="bad">{error ?? "Something went wrong."}</p>
      </Centered>
    );
  }

  if (phase === "ready" && data) {
    return (
      <>
        {isDemo ? (
          <div
            text="xs muted center"
            p="x-3 y-2"
            className="border-b border-line bg-surface"
          >
            Demo fixture — sample data, no Drive or sign-in.
          </div>
        ) : null}
        <Mirror data={data} onSignOut={isDemo ? undefined : handleSignOut} />
      </>
    );
  }

  return <SignInGate onSignIn={handleSignIn} busy={busy} error={error} />;
}
