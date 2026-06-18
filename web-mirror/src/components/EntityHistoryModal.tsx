"use client";

import { useEffect, useRef } from "react";
import type { LifecycleEvent, LifecycleTimeline } from "@/lib/lifecycle";

const DOT_TONE: Record<LifecycleEvent["kind"], string> = {
  created: "bg-accent",
  edited: "bg-muted",
  combined: "bg-ink",
  reviewed: "bg-good",
  archived: "bg-warn",
};

function fmt(at: string | null): string {
  if (!at) return "—";
  const d = new Date(at);
  if (Number.isNaN(d.getTime())) return at;
  return d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

export default function EntityHistoryModal({
  timeline,
  onClose,
}: {
  timeline: LifecycleTimeline;
  onClose: () => void;
}) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const { name, archived, events, reconstructed } = timeline;

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
        aria-label={`${name} lifecycle`}
        w="full"
        max-w="lg"
        bg="white"
        rounded="xl"
        shadow="2xl"
        className="overflow-hidden flex flex-col"
        style={{ maxHeight: "80vh" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div flex="~" items="center" justify="between" p="x-4 y-3" border="b line">
          <div className="min-w-0">
            <div flex="~" items="center" gap="2">
              <span text="sm ink" font="medium" className="truncate">
                {name}
              </span>
              {archived ? (
                <span
                  text="xs warn"
                  font="semibold"
                  p="x-1.5 y-0.5"
                  rounded="full"
                  className="shrink-0 border border-warn/40 uppercase tracking-wide"
                >
                  Archived
                </span>
              ) : null}
            </div>
            <div text="xs muted">
              Lifecycle{reconstructed ? " · reconstructed from library" : ""}
            </div>
          </div>
          <button
            ref={closeRef}
            onClick={onClose}
            aria-label="Close lifecycle"
            text="sm muted"
            p="x-2 y-1"
            m="l-3"
            rounded="md"
            className="focus-ring shrink-0 hover:text-ink"
          >
            Esc
          </button>
        </div>

        <div p="x-4 y-4" className="overflow-y-auto">
          {events.length === 0 ? (
            <div text="sm muted center" p="y-8">
              No lifecycle events recorded yet.
            </div>
          ) : (
            <ol className="list-none p-0 m-0">
              {events.map((e, i) => (
                <li key={i} flex="~" gap="3" p="b-3" className="relative">
                  <span flex="~ col" items="center" className="shrink-0">
                    <span
                      w="2"
                      h="2"
                      rounded="full"
                      m="t-1.5"
                      className={`shrink-0 ${DOT_TONE[e.kind]}`}
                      aria-hidden="true"
                    />
                    {i < events.length - 1 ? (
                      <span w="px" flex="1" m="t-1" className="bg-line" aria-hidden="true" />
                    ) : null}
                  </span>
                  <div flex="1" className="min-w-0">
                    <div flex="~" items="baseline" justify="between" gap="3">
                      <span text="sm ink" font="medium">
                        {e.label}
                      </span>
                      <span text="xs faint" className="tnum shrink-0">
                        {fmt(e.at)}
                      </span>
                    </div>
                    {e.detail ? (
                      <div text="xs muted" m="t-0.5" className="truncate">
                        {e.detail}
                      </div>
                    ) : null}
                  </div>
                </li>
              ))}
            </ol>
          )}
        </div>

        {archived ? (
          // Recovery is a verified write-through (gated on the shared source of
          // truth, Phase 2). The tombstone state is shown as recoverable here;
          // the action itself ships with write support rather than faking one.
          <div
            flex="~"
            items="center"
            justify="between"
            gap="3"
            p="x-4 y-3"
            border="t line"
            className="bg-surface"
          >
            <span text="xs muted">Recovery restores this entity to active.</span>
            <button
              type="button"
              disabled
              aria-disabled="true"
              title="Recovery ships with write support"
              text="xs muted"
              p="x-3 y-1.5"
              rounded="md"
              className="border border-line opacity-60 cursor-not-allowed"
            >
              Recover
            </button>
          </div>
        ) : null}
      </div>
    </div>
  );
}
