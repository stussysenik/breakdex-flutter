"use client";

import type { Bar, Stats, Tone } from "@/lib/stats";

const toneBg: Record<Tone, string> = {
  good: "bg-good",
  warn: "bg-warn",
  bad: "bg-bad",
  accent: "bg-accent",
  muted: "bg-faint",
};

function Section({
  title,
  hint,
  children,
}: {
  title: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <section m="b-9">
      <div flex="~" items="baseline" gap="2" m="b-3">
        <h2 text="xs ink" font="semibold" className="uppercase tracking-wide">
          {title}
        </h2>
        {hint ? (
          <span text="xs muted" m="l-auto">
            {hint}
          </span>
        ) : null}
      </div>
      {children}
    </section>
  );
}

function Figure({ value, label }: { value: number | string; label: string }) {
  return (
    <div>
      <div text="2xl ink" font="semibold" className="tnum leading-none">
        {value}
      </div>
      <div text="xs muted" m="t-1.5">
        {label}
      </div>
    </div>
  );
}

/** Headline view: upcoming review load as a column chart. */
function DueChart({ stats }: { stats: Stats }) {
  const max = Math.max(1, ...stats.due.map((d) => d.value));
  const label = stats.due.map((d) => `${d.label} ${d.value}`).join(", ");
  return (
    <div
      role="img"
      aria-label={`Cards due — ${label}`}
      border="~ line"
      rounded="lg"
      p="4"
    >
      <div flex="~" items="end" gap="1.5" aria-hidden="true">
        {stats.due.map((d, i) => (
          <div key={d.label} flex="~ 1 col" items="center" justify="end" gap="1.5">
            <span text="xs muted" className={`tnum ${d.value === 0 ? "opacity-40" : ""}`}>
              {d.value}
            </span>
            <div
              w="full"
              rounded="t-sm"
              className={`anim-rise ${d.overdue ? toneBg.bad : d.value ? "bg-accent" : "bg-line"}`}
              style={{
                height: `${Math.max(3, (d.value / max) * 96)}px`,
                animationDelay: `${i * 24}ms`,
              }}
            />
          </div>
        ))}
      </div>
      <div flex="~" gap="1.5" m="t-2">
        {stats.due.map((d) => (
          <span key={d.label} flex="1" text="[10px] muted center" className="truncate">
            {d.label}
          </span>
        ))}
      </div>
    </div>
  );
}

/** FSRS state distribution as one segmented bar + legend. */
function MasteryBar({ mastery }: { mastery: Bar[] }) {
  const total = mastery.reduce((a, b) => a + b.value, 0) || 1;
  return (
    <div
      role="img"
      aria-label={`Mastery — ${mastery.map((m) => `${m.label} ${m.value}`).join(", ")}`}
    >
      <div flex="~" h="2.5" rounded="full" bg="surface" className="overflow-hidden">
        {mastery.map((m) => (
          <div
            key={m.key}
            className={`${toneBg[m.tone]} anim-rise`}
            style={{ width: `${(m.value / total) * 100}%` }}
          />
        ))}
      </div>
      <div flex="~ wrap" gap="x-4 y-1.5" m="t-3">
        {mastery.map((m) => (
          <span key={m.key} flex="~" items="center" gap="1.5" text="xs muted">
            <span w="2" h="2" rounded="full" className={toneBg[m.tone]} aria-hidden="true" />
            {m.label}
            <span text="ink" className="tnum">
              {m.value}
            </span>
          </span>
        ))}
      </div>
    </div>
  );
}

/** Rating mix as labelled horizontal bars. */
function RatingBars({ ratings }: { ratings: Bar[] }) {
  const total = ratings.reduce((a, b) => a + b.value, 0) || 1;
  return (
    <div flex="~ col" gap="2.5">
      {ratings.map((r) => (
        <div key={r.key} flex="~" items="center" gap="3">
          <span text="xs muted" w="14">
            {r.label}
          </span>
          <div flex="1" h="2" rounded="full" bg="surface" className="overflow-hidden">
            <div
              h="full"
              rounded="full"
              className={`${toneBg[r.tone]} anim-rise`}
              style={{ width: `${(r.value / total) * 100}%` }}
            />
          </div>
          <span text="xs ink right" w="8" className="tnum">
            {r.value}
          </span>
        </div>
      ))}
    </div>
  );
}

export default function StatsPanel({
  stats,
  engine,
}: {
  stats: Stats;
  engine: string;
}) {
  const { totals } = stats;
  const maxCat = Math.max(...stats.categories.map((x) => x.count), 1);
  return (
    <div className="anim-rise">
      <Section title="At a glance">
        <div grid="~ cols-2 sm:cols-4" gap="y-5">
          <Figure value={totals.moves} label="Moves" />
          <Figure value={totals.combos} label="Combos" />
          <Figure value={totals.reviews} label="Reviews" />
          <Figure value={stats.dueNow} label="Due now" />
        </div>
      </Section>

      <Section
        title="Review load ahead"
        hint={stats.dueNow ? `${stats.dueNow} due now` : "all clear"}
      >
        <DueChart stats={stats} />
      </Section>

      <Section title="Mastery" hint={`${totals.cards} scheduled`}>
        <MasteryBar mastery={stats.mastery} />
      </Section>

      <Section title="Rating mix" hint={`${totals.reviews} logged`}>
        <RatingBars ratings={stats.ratings} />
      </Section>

      {stats.categories.length > 0 ? (
        <Section title="By category">
          <div flex="~ col" gap="2.5">
            {stats.categories.map((c) => (
              <div key={c.name} flex="~" items="center" gap="3">
                <span text="xs ink" w="28" className="truncate">
                  {c.name}
                </span>
                <div flex="1" h="2" rounded="full" bg="surface">
                  <div
                    h="full"
                    rounded="full"
                    bg="ink"
                    className="anim-rise"
                    style={{ width: `${(c.count / maxCat) * 100}%` }}
                  />
                </div>
                <span text="xs muted right" w="6" className="tnum">
                  {c.count}
                </span>
              </div>
            ))}
          </div>
        </Section>
      ) : null}

      <p text="[11px] faint" m="t-2">
        Computed by {engine}.
        {stats.avgStability != null
          ? ` Avg recall strength ${stats.avgStability.toFixed(1)}d.`
          : ""}
      </p>
    </div>
  );
}
