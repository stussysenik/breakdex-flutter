"use client";

import { useEffect, useRef, useState } from "react";
import type { VideoResolver } from "@/lib/types";

interface Props {
  title: string;
  subtitle?: string;
  contentHash: string | null;
  resolveVideo: VideoResolver;
  sourceLabel: string;
  onClose: () => void;
}

type State = "loading" | "ready" | "missing";

export default function VideoModal({
  title,
  subtitle,
  contentHash,
  resolveVideo,
  sourceLabel,
  onClose,
}: Props) {
  const [url, setUrl] = useState<string | null>(null);
  const [state, setState] = useState<State>("loading");
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    let active = true;
    setState("loading");
    resolveVideo(contentHash)
      .then((resolved) => {
        if (!active) return;
        if (resolved) {
          setUrl(resolved);
          setState("ready");
        } else {
          setState("missing");
        }
      })
      .catch(() => active && setState("missing"));
    return () => {
      active = false;
    };
  }, [contentHash, resolveVideo]);

  useEffect(() => {
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div
      inset="0"
      z="50"
      flex="~"
      items="center"
      justify="center"
      p="4"
      bg="black/55"
      className="fixed anim-rise"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        w="full"
        max-w="2xl"
        bg="white"
        rounded="xl"
        shadow="2xl"
        className="overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div
          flex="~"
          items="center"
          justify="between"
          p="x-4 y-3"
          border="b line"
        >
          <div className="min-w-0">
            <div text="sm ink" font="medium" className="truncate">
              {title}
            </div>
            {subtitle ? (
              <div text="xs muted" className="truncate">
                {subtitle}
              </div>
            ) : null}
          </div>
          <button
            ref={closeRef}
            onClick={onClose}
            aria-label="Close video"
            text="sm muted"
            p="x-2 y-1"
            m="l-3"
            rounded="md"
            className="focus-ring shrink-0 hover:text-ink"
          >
            Esc
          </button>
        </div>

        <div
          bg="black"
          flex="~"
          items="center"
          justify="center"
          className="aspect-video relative"
        >
          {state === "loading" ? (
            <div flex="~ col" items="center" gap="3" text="white/80">
              <span
                w="6"
                h="6"
                border="2 white/30 t-white"
                rounded="full"
                className="animate-spin"
                aria-hidden="true"
              />
              <span text="xs">Retrieving from {sourceLabel}…</span>
            </div>
          ) : null}

          {state === "ready" && url ? (
            <video
              src={url}
              controls
              autoPlay
              playsInline
              w="full"
              h="full"
              className="anim-rise"
            />
          ) : null}

          {state === "missing" ? (
            <div flex="~ col" items="center" gap="1" text="white/70" p="6">
              <span text="sm">Video unavailable</span>
              <span text="xs white/50">
                No matching file in your {sourceLabel} folder.
              </span>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}
