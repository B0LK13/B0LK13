import { useEffect, useMemo, useState } from 'react';

const formatCurrency = (value) =>
  new Intl.NumberFormat('en-GB', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 0,
  }).format(value);

const formatDate = (value) =>
  new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(`${value}T00:00:00Z`));

const formatDateTime = (value) =>
  new Intl.DateTimeFormat('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'UTC',
  }).format(new Date(value));

const scoreTone = (score) => {
  if (score >= 4) return 'bg-emerald-500/15 text-emerald-200 ring-emerald-400/30';
  if (score >= 3) return 'bg-amber-500/15 text-amber-100 ring-amber-300/30';
  return 'bg-rose-500/15 text-rose-100 ring-rose-300/30';
};

const evidenceTone = {
  High: 'bg-emerald-500/15 text-emerald-200 ring-emerald-400/30',
  Medium: 'bg-sky-500/15 text-sky-100 ring-sky-300/30',
  Low: 'bg-amber-500/15 text-amber-100 ring-amber-300/30',
};

function Pill({ children, className = '' }) {
  return (
    <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ring-1 ${className}`}>
      {children}
    </span>
  );
}

function StatCard({ label, value, detail }) {
  return (
    <div className="rounded-3xl border border-white/10 bg-slate-950/70 p-5 shadow-lg shadow-slate-950/30">
      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">{label}</p>
      <p className="mt-3 text-3xl font-semibold text-white">{value}</p>
      <p className="mt-2 text-sm text-slate-300">{detail}</p>
    </div>
  );
}

function SectionCard({ title, subtitle, children }) {
  return (
    <section className="rounded-[2rem] border border-white/10 bg-slate-950/70 p-6 shadow-lg shadow-slate-950/30">
      <div className="mb-5">
        <h2 className="text-xl font-semibold text-white">{title}</h2>
        {subtitle ? <p className="mt-2 text-sm text-slate-300">{subtitle}</p> : null}
      </div>
      {children}
    </section>
  );
}

export default function Dashboard({ dataset }) {
  const [search, setSearch] = useState('');
  const [maxMedianCost, setMaxMedianCost] = useState(1700);
  const [minimumNetScore, setMinimumNetScore] = useState(0);
  const [evidenceFilter, setEvidenceFilter] = useState('All');
  const [activeCityId, setActiveCityId] = useState(dataset.cities[0]?.id ?? null);

  const visibleCities = useMemo(() => {
    return dataset.cities.filter((city) => {
      const matchesSearch = `${city.name} ${city.country}`.toLowerCase().includes(search.toLowerCase());
      const matchesCost = city.costBand.median <= maxMedianCost;
      const matchesNet = city.scores.net >= minimumNetScore;
      const matchesEvidence = evidenceFilter === 'All' || city.connectivity.evidenceLabel === evidenceFilter;
      return matchesSearch && matchesCost && matchesNet && matchesEvidence;
    });
  }, [dataset.cities, evidenceFilter, maxMedianCost, minimumNetScore, search]);

  useEffect(() => {
    if (!visibleCities.length) {
      setActiveCityId(null);
      return;
    }

    const activeStillVisible = visibleCities.some((city) => city.id === activeCityId);
    if (!activeStillVisible) {
      setActiveCityId(visibleCities[0].id);
    }
  }, [activeCityId, visibleCities]);

  const activeCity = visibleCities.find((city) => city.id === activeCityId) ?? null;
  const averageMedianCost = Math.round(dataset.cities.reduce((sum, city) => sum + city.costBand.median, 0) / dataset.cities.length);
  const strongestEvidenceCount = dataset.cities.filter((city) => city.connectivity.evidenceLabel === 'High').length;

  return (
    <main className="w-full px-4 pb-12 sm:px-6 lg:px-8">
      <section className="rounded-[2rem] border border-white/10 bg-slate-950/80 p-8 text-white shadow-2xl shadow-slate-950/40">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div className="max-w-3xl">
            <Pill className="bg-sky-500/15 text-sky-100 ring-sky-300/30">MDA Cross Platform seed dashboard</Pill>
            <h1 className="mt-5 text-4xl font-semibold tracking-tight sm:text-5xl">
              Compare four starter cities with seeded costs, connectivity, mobility, and compliance context.
            </h1>
            <p className="mt-4 max-w-2xl text-base text-slate-200 sm:text-lg">
              This first development slice turns the dashboard plan into a working seeded snapshot with an ETL flow, evidence log, and trip-prep signals for micro-roaming and basecamp decisions.
            </p>
          </div>
          <div className="rounded-3xl border border-white/10 bg-white/5 p-5 text-sm text-slate-200">
            <p className="font-semibold text-white">Latest seed refresh</p>
            <p className="mt-2">{formatDateTime(dataset.meta.generatedAt)}</p>
            <p className="mt-2">{dataset.meta.totalTripDays} buitenland-dagen tracked in the current 365-day window.</p>
          </div>
        </div>

        <div className="mt-8 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <StatCard label="Starter cities" value={dataset.meta.totalCities} detail="Wrocław, Cluj-Napoca, Sofia, and Valencia are seeded end-to-end." />
          <StatCard label="Average median cost" value={formatCurrency(averageMedianCost)} detail="Current seeded midpoint for monthly housing/living estimates." />
          <StatCard label="High-evidence cities" value={strongestEvidenceCount} detail="Cities already seeded with High evidence on the current snapshot." />
          <StatCard label="Rolling window" value={`${dataset.meta.rollingWindowDays} days`} detail="Used for buitenland-dagen tracking and threshold alerts." />
        </div>
      </section>

      <div className="mt-8 grid gap-8 xl:grid-cols-[1.1fr_0.9fr]">
        <div className="space-y-8">
          <SectionCard title="City explorer" subtitle="Filter the seeded dataset before drilling into cost, internet, and mobility trade-offs.">
            <div className="grid gap-4 lg:grid-cols-4">
              <label className="text-sm text-slate-300">
                Search city or country
                <input
                  type="text"
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="Search..."
                  className="mt-2 w-full rounded-2xl border border-white/10 bg-slate-900 px-4 py-3 text-white outline-none ring-0 placeholder:text-slate-500"
                />
              </label>
              <label className="text-sm text-slate-300">
                Max median cost
                <input
                  type="range"
                  min="800"
                  max="1800"
                  step="20"
                  value={maxMedianCost}
                  onChange={(event) => setMaxMedianCost(Number(event.target.value))}
                  className="mt-4 w-full accent-sky-400"
                />
                <span className="mt-2 block text-white">{formatCurrency(maxMedianCost)}</span>
              </label>
              <label className="text-sm text-slate-300">
                Minimum NetScore
                <select
                  value={minimumNetScore}
                  onChange={(event) => setMinimumNetScore(Number(event.target.value))}
                  className="mt-2 w-full rounded-2xl border border-white/10 bg-slate-900 px-4 py-3 text-white outline-none"
                >
                  {[0, 1, 2, 3, 4, 5].map((value) => (
                    <option key={value} value={value}>
                      {value}+
                    </option>
                  ))}
                </select>
              </label>
              <label className="text-sm text-slate-300">
                Evidence level
                <select
                  value={evidenceFilter}
                  onChange={(event) => setEvidenceFilter(event.target.value)}
                  className="mt-2 w-full rounded-2xl border border-white/10 bg-slate-900 px-4 py-3 text-white outline-none"
                >
                  {['All', 'High', 'Medium', 'Low'].map((value) => (
                    <option key={value} value={value}>
                      {value}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <div className="mt-6 overflow-hidden rounded-[1.5rem] border border-white/10">
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-white/10 text-left text-sm text-slate-200">
                  <thead className="bg-white/5 text-xs uppercase tracking-[0.18em] text-slate-400">
                    <tr>
                      <th className="px-4 py-3">City</th>
                      <th className="px-4 py-3">Median cost</th>
                      <th className="px-4 py-3">Mobility</th>
                      <th className="px-4 py-3">Net</th>
                      <th className="px-4 py-3">Coworking</th>
                      <th className="px-4 py-3">Evidence</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/10 bg-slate-950/30">
                    {visibleCities.map((city) => (
                      <tr
                        key={city.id}
                        className={`cursor-pointer transition hover:bg-white/5 ${activeCityId === city.id ? 'bg-white/5' : ''}`}
                        onClick={() => setActiveCityId(city.id)}
                      >
                        <td className="px-4 py-4">
                          <p className="font-semibold text-white">{city.name}</p>
                          <p className="mt-1 text-xs text-slate-400">{city.country}</p>
                        </td>
                        <td className="px-4 py-4">{formatCurrency(city.costBand.median)}</td>
                        <td className="px-4 py-4">
                          <Pill className={scoreTone(city.scores.mobility)}>{city.scores.mobility.toFixed(1)}</Pill>
                        </td>
                        <td className="px-4 py-4">
                          <Pill className={scoreTone(city.scores.net)}>{city.scores.net.toFixed(1)}</Pill>
                        </td>
                        <td className="px-4 py-4">{formatCurrency(city.coworking.monthlyEur)}</td>
                        <td className="px-4 py-4">
                          <Pill className={evidenceTone[city.connectivity.evidenceLabel] || evidenceTone.Medium}>
                            {city.connectivity.evidenceLabel}
                          </Pill>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {!visibleCities.length ? <p className="mt-4 text-sm text-amber-200">No seeded cities match the current filter set.</p> : null}
          </SectionCard>

          {activeCity ? (
            <SectionCard title={`${activeCity.name} detail`} subtitle="Current seed snapshot across cost, connectivity, mobility, and compliance.">
              <div className="grid gap-4 md:grid-cols-2">
                <div className="rounded-3xl border border-white/10 bg-white/5 p-5">
                  <div className="flex flex-wrap gap-2">
                    <Pill className={scoreTone(activeCity.scores.mobility)}>Mobility {activeCity.scores.mobility.toFixed(1)}</Pill>
                    <Pill className={scoreTone(activeCity.scores.net)}>Net {activeCity.scores.net.toFixed(1)}</Pill>
                    <Pill className={evidenceTone[activeCity.connectivity.evidenceLabel] || evidenceTone.Medium}>
                      {activeCity.connectivity.evidenceLabel} evidence
                    </Pill>
                  </div>
                  <h3 className="mt-5 text-lg font-semibold text-white">Overview</h3>
                  <dl className="mt-4 space-y-3 text-sm text-slate-200">
                    <div className="flex items-center justify-between gap-4">
                      <dt>Cost band</dt>
                      <dd>{formatCurrency(activeCity.costBand.low)} — {formatCurrency(activeCity.costBand.high)}</dd>
                    </div>
                    <div className="flex items-center justify-between gap-4">
                      <dt>Safety index</dt>
                      <dd>{activeCity.safetyIndex}</dd>
                    </div>
                    <div className="flex items-center justify-between gap-4">
                      <dt>Monthly coworking</dt>
                      <dd>{formatCurrency(activeCity.coworking.monthlyEur)}</dd>
                    </div>
                    <div className="flex items-center justify-between gap-4">
                      <dt>Distance to station</dt>
                      <dd>{activeCity.coworking.distanceToStationMin} min</dd>
                    </div>
                  </dl>
                  <p className="mt-5 text-sm text-slate-300">{activeCity.languageNotes}</p>
                  <p className="mt-3 text-sm text-slate-300">{activeCity.techSceneNotes}</p>
                </div>

                <div className="rounded-3xl border border-white/10 bg-white/5 p-5">
                  <h3 className="text-lg font-semibold text-white">Trade-offs & red flags</h3>
                  <div className="mt-4 space-y-4 text-sm text-slate-200">
                    <div>
                      <p className="font-semibold text-white">Trade-offs</p>
                      <ul className="mt-2 list-disc space-y-2 pl-5">
                        {activeCity.tradeOffs.map((item) => (
                          <li key={item}>{item}</li>
                        ))}
                      </ul>
                    </div>
                    <div>
                      <p className="font-semibold text-white">Red flags</p>
                      <ul className="mt-2 list-disc space-y-2 pl-5">
                        {activeCity.redFlags.map((item) => (
                          <li key={item}>{item}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-6 grid gap-4 md:grid-cols-3">
                <div className="rounded-3xl border border-white/10 bg-white/5 p-5 text-sm text-slate-200">
                  <h3 className="text-lg font-semibold text-white">Internet snapshot</h3>
                  <ul className="mt-4 space-y-2">
                    <li>Fixed median: {activeCity.connectivity.fixedMedianDownMbps}/{activeCity.connectivity.fixedMedianUpMbps} Mbps</li>
                    <li>Mobile median: {activeCity.connectivity.mobileMedianDownMbps}/{activeCity.connectivity.mobileMedianUpMbps} Mbps</li>
                    <li>Latency: {activeCity.connectivity.fixedLatencyMs} ms</li>
                    <li>{activeCity.connectivity.stabilityNote}</li>
                  </ul>
                </div>
                <div className="rounded-3xl border border-white/10 bg-white/5 p-5 text-sm text-slate-200">
                  <h3 className="text-lg font-semibold text-white">Mobility coverage</h3>
                  <ul className="mt-4 space-y-2">
                    <li>Rail hub: {activeCity.mobility.railHub ? 'Yes' : 'No'}</li>
                    <li>Coach hub: {activeCity.mobility.coachHub ? 'Yes' : 'No'}</li>
                    <li>Airport within 60 min: {activeCity.mobility.airportWithin60Min ? 'Yes' : 'No'}</li>
                    <li>HSR: {activeCity.mobility.hsr ? 'Yes' : 'No'}</li>
                    <li>Frequency bonus: {activeCity.mobility.freqScore.toFixed(1)}</li>
                  </ul>
                  <p className="mt-4 text-slate-300">{activeCity.mobility.notes}</p>
                </div>
                <div className="rounded-3xl border border-white/10 bg-white/5 p-5 text-sm text-slate-200">
                  <h3 className="text-lg font-semibold text-white">Compliance pulse</h3>
                  <p className="mt-4">{activeCity.compliance.registrationNotes}</p>
                  <ul className="mt-4 list-disc space-y-2 pl-5">
                    {activeCity.compliance.pitfalls.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </div>
              </div>
            </SectionCard>
          ) : null}
        </div>

        <div className="space-y-8">
          {activeCity ? (
            <>
              <SectionCard title="Evidence log" subtitle="Each seed datapoint keeps a last-verified date, label, and source URL.">
                <div className="space-y-4">
                  {activeCity.evidence.map((entry) => (
                    <article key={`${entry.field}-${entry.sourceUrl}`} className="rounded-3xl border border-white/10 bg-white/5 p-4 text-sm text-slate-200">
                      <div className="flex flex-wrap items-center gap-2">
                        <Pill className={evidenceTone[entry.evidenceLabel] || evidenceTone.Medium}>{entry.evidenceLabel}</Pill>
                        <span className="text-xs uppercase tracking-[0.18em] text-slate-400">{entry.field}</span>
                      </div>
                      <p className="mt-3 text-slate-200">{entry.notes}</p>
                      <p className="mt-3 text-xs text-slate-400">Verified {formatDate(entry.lastVerified)}</p>
                      <a href={entry.sourceUrl} className="mt-3 inline-block break-all text-sky-300 underline-offset-4 hover:underline">
                        {entry.sourceUrl}
                      </a>
                    </article>
                  ))}
                </div>
              </SectionCard>

              <SectionCard title="Trips planner" subtitle="Seeded trip timing with UWV, EHIC, and post-prep reminders.">
                <div className="rounded-3xl border border-white/10 bg-white/5 p-5 text-sm text-slate-200">
                  <div className="flex flex-wrap gap-2">
                    <Pill className="bg-violet-500/15 text-violet-100 ring-violet-300/30">{activeCity.trip.tripLengthDays} days</Pill>
                    <Pill className={activeCity.trip.ehicCheck ? 'bg-emerald-500/15 text-emerald-200 ring-emerald-400/30' : 'bg-amber-500/15 text-amber-100 ring-amber-300/30'}>
                      EHIC {activeCity.trip.ehicCheck ? 'ready' : 'pending'}
                    </Pill>
                    <Pill className={activeCity.trip.postReady ? 'bg-emerald-500/15 text-emerald-200 ring-emerald-400/30' : 'bg-amber-500/15 text-amber-100 ring-amber-300/30'}>
                      Post {activeCity.trip.postReady ? 'ready' : 'pending'}
                    </Pill>
                  </div>
                  <dl className="mt-5 space-y-3">
                    <div className="flex items-center justify-between gap-4">
                      <dt>Start date</dt>
                      <dd>{formatDate(activeCity.trip.startDate)}</dd>
                    </div>
                    <div className="flex items-center justify-between gap-4">
                      <dt>End date</dt>
                      <dd>{formatDate(activeCity.trip.endDate)}</dd>
                    </div>
                    <div className="flex items-center justify-between gap-4">
                      <dt>UWV reminder due</dt>
                      <dd>{formatDate(activeCity.trip.uwvTaskDue)}</dd>
                    </div>
                  </dl>
                </div>
              </SectionCard>
            </>
          ) : null}

          <SectionCard title="What shipped in this slice" subtitle="Current development scope aligned to the repo plan.">
            <ul className="list-disc space-y-3 pl-5 text-sm text-slate-200">
              <li>Seed CSV for the first four cities and a repeatable `npm run etl:sync` command.</li>
              <li>Generated snapshot JSON for reuse in the page and API.</li>
              <li>Initial explorer, detail, evidence, and trip-prep UI without adding extra dependencies.</li>
              <li>Supporting docs for env vars, Make targets, data dictionary, OpenAPI, and DB migration scaffolding.</li>
            </ul>
          </SectionCard>
        </div>
      </div>
    </main>
  );
}
