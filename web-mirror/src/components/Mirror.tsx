"use client";

import { useMemo, useState } from "react";
import type { MirrorData, Move, Note } from "@/lib/types";
import { computeStats } from "@/lib/stats";
import StatsPanel from "./StatsPanel";
import VideoModal from "./VideoModal";

type Tab = "library" | "combos" | "journal" | "plans" | "stats";

interface Selection {
  title: string;
  subtitle?: string;
  contentHash: string | null;
}

function fmtDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function Chevron({ open }: { open: boolean }) {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 12 12"
      fill="none"
      aria-hidden="true"
      className="shrink-0 transition-transform duration-150"
      style={{ transform: open ? "rotate(90deg)" : "none" }}
    >
      <path
        d="M4 2.5L8 6L4 9.5"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function PlayGlyph({ dim }: { dim?: boolean }) {
  return (
    <span
      w="6"
      h="6"
      rounded="full"
      flex="~"
      items="center"
      justify="center"
      bg="surface"
      className={`shrink-0 ${dim ? "text-faint" : "text-accent"}`}
      aria-hidden="true"
    >
      <svg width="9" height="9" viewBox="0 0 9 9" fill="currentColor">
        {dim ? (
          <rect x="1" y="4" width="7" height="1.2" rx="0.6" />
        ) : (
          <path d="M2 1.5v6l5-3z" />
        )}
      </svg>
    </span>
  );
}

function Disclosure({
  title,
  count,
  defaultOpen = true,
  children,
}: {
  title: string;
  count: number;
  defaultOpen?: boolean;
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <section border="b line">
      <button
        type="button"
        aria-expanded={open}
        onClick={() => setOpen((o) => !o)}
        w="full"
        flex="~"
        items="center"
        gap="2"
        p="y-3"
        text="left muted"
        className="focus-ring"
      >
        <Chevron open={open} />
        <span text="sm ink" font="medium">
          {title}
        </span>
        <span text="xs muted" m="l-auto" className="tnum">
          {count}
        </span>
      </button>
      {open ? (
        <ul m="b-2" className="anim-rise list-none p-0">
          {children}
        </ul>
      ) : null}
    </section>
  );
}

function MoveRow({
  name,
  contentHash,
  onPlay,
}: {
  name: string;
  contentHash: string | null;
  onPlay: () => void;
}) {
  const playable = !!contentHash;
  const inner = (
    <>
      <PlayGlyph dim={!playable} />
      <span flex="1" text="sm ink" className="truncate">
        {name}
      </span>
      {!playable ? (
        <span text="xs faint" className="shrink-0">
          no video
        </span>
      ) : null}
    </>
  );
  return (
    <li>
      {playable ? (
        <button
          type="button"
          onClick={onPlay}
          w="full"
          flex="~"
          items="center"
          gap="3"
          p="x-2 y-2"
          rounded="md"
          text="left"
          className="focus-ring hover:bg-surface transition-colors"
        >
          {inner}
        </button>
      ) : (
        <div
          flex="~"
          items="center"
          gap="3"
          p="x-2 y-2"
          className="opacity-70 cursor-default"
        >
          {inner}
        </div>
      )}
    </li>
  );
}

export default function Mirror({
  data,
  onSignOut,
}: {
  data: MirrorData;
  onSignOut?: () => void;
}) {
  const { manifest, resolveVideo, sourceLabel } = data;
  const [tab, setTab] = useState<Tab>("library");
  const [sel, setSel] = useState<Selection | null>(null);

  const stats = useMemo(() => computeStats(manifest), [manifest]);
  const notes = manifest.notes ?? [];
  const plans = manifest.plans ?? [];

  const movesById = useMemo(() => {
    const m = new Map<string, Move>();
    for (const mv of manifest.moves) m.set(mv.id, mv);
    return m;
  }, [manifest.moves]);

  const comboName = useMemo(() => {
    const m = new Map<string, string>();
    for (const c of manifest.combos) m.set(c.id, c.name);
    return m;
  }, [manifest.combos]);

  const movesByCategory = useMemo(() => {
    const m = new Map<string, Move[]>();
    for (const mv of manifest.moves) {
      const arr = m.get(mv.category) ?? [];
      arr.push(mv);
      m.set(mv.category, arr);
    }
    return [...m.entries()].sort((a, b) => a[0].localeCompare(b[0]));
  }, [manifest.moves]);

  const notesByCombo = useMemo(() => {
    const m = new Map<string, Note[]>();
    for (const n of notes) {
      const arr = m.get(n.comboId) ?? [];
      arr.push(n);
      m.set(n.comboId, arr);
    }
    for (const arr of m.values())
      arr.sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt));
    return [...m.entries()];
  }, [notes]);

  const tabs: { id: Tab; label: string; count: number }[] = [
    { id: "library", label: "Library", count: manifest.moves.length },
    { id: "combos", label: "Combos", count: manifest.combos.length },
    { id: "journal", label: "Journal", count: notes.length },
    { id: "plans", label: "Plans", count: plans.length },
    { id: "stats", label: "Stats", count: manifest.reviews.length },
  ];

  const goHome = () => {
    setTab("library");
    setSel(null);
  };

  // Breadcrumb trail: Breakdex ▸ Section ▸ [Subsection] ▸ [Item]. The last
  // segment is the current location; earlier segments navigate back up.
  const sectionLabel = tabs.find((t) => t.id === tab)?.label ?? "";
  const crumbs: { label: string; onClick?: () => void }[] = [
    { label: "Breakdex", onClick: goHome },
    { label: sectionLabel, onClick: sel ? () => setSel(null) : undefined },
  ];
  if (sel) {
    if (sel.subtitle) crumbs.push({ label: sel.subtitle });
    crumbs.push({ label: sel.title });
  }

  return (
    <div flex="~ col" bg="white" className="min-h-screen">
      {/* Toolbar — persistent app chrome: brand lockup + status/actions cluster. */}
      <header
        role="banner"
        flex="~"
        items="center"
        justify="between"
        gap="3"
        p="x-4 y-3 sm:x-6"
        className="border-b border-line bg-white"
      >
        <button
          type="button"
          onClick={goHome}
          flex="~"
          items="center"
          gap="2"
          p="x-1 y-0.5"
          rounded="md"
          text="left"
          className="focus-ring min-w-0 hover:bg-surface transition-colors"
          aria-label="Breakdex home"
        >
          <span
            w="6"
            h="6"
            rounded="md"
            flex="~"
            items="center"
            justify="center"
            text="white xs"
            font="bold"
            className="shrink-0 bg-ink"
            aria-hidden="true"
          >
            B
          </span>
          <span text="base ink" font="semibold" className="tracking-tight">
            Breakdex
          </span>
          <span
            text="xs muted"
            font="medium"
            p="x-1.5 y-0.5"
            rounded="full"
            className="hidden sm:inline border border-line uppercase tracking-wider"
          >
            Mirror
          </span>
        </button>

        <div flex="~" items="center" gap="3" className="shrink-0">
          {/* Sync/status chip — anticipates live sync; today reflects load + read-only. */}
          <span
            flex="~"
            items="center"
            gap="1.5"
            p="x-2 y-1"
            rounded="full"
            text="xs muted"
            font="medium"
            className="hidden sm:flex border border-line"
            title={`${sourceLabel} · read-only`}
          >
            <span
              w="1.5"
              h="1.5"
              rounded="full"
              className="bg-good shrink-0"
              aria-hidden="true"
            />
            Synced
          </span>
          <span text="xs faint" className="hidden md:inline">
            {sourceLabel} · read-only
          </span>
          {onSignOut ? (
            <button
              type="button"
              onClick={onSignOut}
              text="xs muted"
              p="x-2 y-1"
              rounded="md"
              className="focus-ring hover:text-ink hover:bg-surface transition-colors"
            >
              Sign out
            </button>
          ) : null}
        </div>
      </header>

      <nav
        role="tablist"
        aria-label="Library sections"
        flex="~"
        gap="5"
        p="x-4 sm:x-6"
        className="border-b border-line overflow-x-auto sticky top-0 bg-white z-10"
      >
        {tabs.map((t) => {
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              role="tab"
              type="button"
              aria-selected={active}
              onClick={() => setTab(t.id)}
              p="y-2.5"
              text={active ? "sm ink" : "sm muted"}
              className={`focus-ring whitespace-nowrap border-b-2 -mb-px transition-colors ${
                active ? "border-ink" : "border-transparent hover:text-ink"
              }`}
            >
              {t.label}
              <span text="xs muted" m="l-1.5" className="tnum">
                {t.count}
              </span>
            </button>
          );
        })}
      </nav>

      <Breadcrumbs crumbs={crumbs} />

      <main flex="1" w="full" max-w="3xl" m="x-auto" p="x-4 y-6 sm:x-6">
        {/* key={tab} re-triggers the rise animation on each section change. */}
        <div key={tab} className="anim-rise">
        {tab === "library" &&
          (movesByCategory.length === 0 ? (
            <Empty>No moves yet.</Empty>
          ) : (
            <div>
              {movesByCategory.map(([cat, list]) => (
                <Disclosure key={cat} title={cat} count={list.length}>
                  {list.map((mv) => (
                    <MoveRow
                      key={mv.id}
                      name={mv.name}
                      contentHash={mv.contentHash}
                      onPlay={() =>
                        setSel({
                          title: mv.name,
                          subtitle: mv.category,
                          contentHash: mv.contentHash,
                        })
                      }
                    />
                  ))}
                </Disclosure>
              ))}
            </div>
          ))}

        {tab === "combos" &&
          (manifest.combos.length === 0 ? (
            <Empty>No combos yet.</Empty>
          ) : (
            <div>
              {manifest.combos.map((combo) => {
                const seq = manifest.comboMoves
                  .filter((cm) => cm.comboId === combo.id)
                  .sort((a, b) => a.sequenceIndex - b.sequenceIndex);
                return (
                  <Disclosure key={combo.id} title={combo.name} count={seq.length}>
                    {seq.length === 0 ? (
                      <li text="xs muted" p="x-2 y-2">
                        No moves linked.
                      </li>
                    ) : (
                      seq.map((cm, i) => {
                        const mv = movesById.get(cm.moveId);
                        return (
                          <MoveRow
                            key={`${cm.moveId}-${i}`}
                            name={`${i + 1}. ${mv?.name ?? cm.moveId}`}
                            contentHash={mv?.contentHash ?? null}
                            onPlay={() =>
                              setSel({
                                title: mv?.name ?? "Move",
                                subtitle: combo.name,
                                contentHash: mv?.contentHash ?? null,
                              })
                            }
                          />
                        );
                      })
                    )}
                  </Disclosure>
                );
              })}
            </div>
          ))}

        {tab === "journal" &&
          (notesByCombo.length === 0 ? (
            <Empty>No journal entries yet.</Empty>
          ) : (
            <div>
              {notesByCombo.map(([cid, list]) => (
                <Disclosure
                  key={cid}
                  title={comboName.get(cid) ?? cid}
                  count={list.length}
                >
                  {list.map((n) => (
                    <li key={n.id} p="x-2 y-2.5">
                      <div flex="~" items="baseline" justify="between" gap="3">
                        <span
                          text={n.kind === "status" ? "xs warn" : "xs muted"}
                          font="semibold"
                          className="uppercase tracking-wide"
                        >
                          {n.kind}
                        </span>
                        <span text="xs faint" className="tnum shrink-0">
                          {fmtDate(n.createdAt)}
                        </span>
                      </div>
                      <p text="sm ink" m="t-1" className="leading-relaxed">
                        {n.body}
                      </p>
                    </li>
                  ))}
                </Disclosure>
              ))}
            </div>
          ))}

        {tab === "plans" &&
          (plans.length === 0 ? (
            <Empty>No practice plans yet.</Empty>
          ) : (
            <PlansTree plans={plans} comboName={comboName} />
          ))}

        {tab === "stats" && <StatsPanel stats={stats} engine="local" />}
        </div>
      </main>

      {sel ? (
        <VideoModal
          title={sel.title}
          subtitle={sel.subtitle}
          contentHash={sel.contentHash}
          resolveVideo={resolveVideo}
          sourceLabel={sourceLabel}
          onClose={() => setSel(null)}
        />
      ) : null}
    </div>
  );
}

function BreadcrumbSep() {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 12 12"
      fill="none"
      aria-hidden="true"
      className="shrink-0 text-faint"
    >
      <path
        d="M4.5 2.5L8 6L4.5 9.5"
        stroke="currentColor"
        strokeWidth="1.25"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function Breadcrumbs({
  crumbs,
}: {
  crumbs: { label: string; onClick?: () => void }[];
}) {
  return (
    <nav
      aria-label="Breadcrumb"
      flex="~"
      items="center"
      gap="1.5"
      p="x-4 y-2.5 sm:x-6"
      className="border-b border-line overflow-x-auto"
    >
      {crumbs.map((c, i) => {
        const last = i === crumbs.length - 1;
        return (
          <span key={`${c.label}-${i}`} flex="~" items="center" gap="1.5">
            {i > 0 ? <BreadcrumbSep /> : null}
            {last || !c.onClick ? (
              <span
                text={last ? "xs ink" : "xs muted"}
                font={last ? "medium" : undefined}
                className="whitespace-nowrap"
                aria-current={last ? "page" : undefined}
              >
                {c.label}
              </span>
            ) : (
              <button
                type="button"
                onClick={c.onClick}
                text="xs muted"
                rounded="sm"
                className="focus-ring whitespace-nowrap hover:text-ink transition-colors"
              >
                {c.label}
              </button>
            )}
          </span>
        );
      })}
    </nav>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return (
    <div text="sm muted center" p="y-20" className="anim-rise">
      {children}
    </div>
  );
}

function PlansTree({
  plans,
  comboName,
}: {
  plans: { id: string; comboId: string; planDate: string; completedAt: string | null }[];
  comboName: Map<string, string>;
}) {
  const upcoming = plans
    .filter((p) => !p.completedAt)
    .sort((a, b) => +new Date(a.planDate) - +new Date(b.planDate));
  const done = plans
    .filter((p) => p.completedAt)
    .sort((a, b) => +new Date(b.planDate) - +new Date(a.planDate));

  const Row = (p: (typeof plans)[number]) => (
    <li key={p.id} flex="~" items="center" justify="between" gap="3" p="x-2 y-2.5">
      <span text="sm ink" className="truncate">
        {comboName.get(p.comboId) ?? p.comboId}
      </span>
      <span flex="~" items="center" gap="2" className="shrink-0">
        <span
          text={p.completedAt ? "xs good" : "xs muted"}
          font="semibold"
          className="uppercase tracking-wide"
        >
          {p.completedAt ? "done" : "planned"}
        </span>
        <span text="xs faint" className="tnum">
          {fmtDate(p.planDate)}
        </span>
      </span>
    </li>
  );

  return (
    <div>
      {upcoming.length > 0 ? (
        <Disclosure title="Upcoming" count={upcoming.length}>
          {upcoming.map(Row)}
        </Disclosure>
      ) : null}
      {done.length > 0 ? (
        <Disclosure title="Completed" count={done.length} defaultOpen={false}>
          {done.map(Row)}
        </Disclosure>
      ) : null}
    </div>
  );
}
