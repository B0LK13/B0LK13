## B0LK13 site + MDA Cross Platform seed dashboard

This repository now contains:

- the existing Next.js blog and email-agent pages
- an initial **MDA Cross Platform** seeded dashboard at `/mda-cross-platform`
- a repeatable mock ETL flow that generates the dashboard snapshot from `etl/city-seed.csv`

## Local development

```bash
npm ci
npm run etl:sync
npm run lint
npm run build
npm run dev
```

## Project files for the dashboard slice

- `etl/city-seed.csv`: starter-city seed input
- `etl/sync.js`: transforms the seed into `data/mda/city-snapshots.json`
- `pages/mda-cross-platform.js`: dashboard route
- `pages/api/mda-cross-platform/summary.js`: summary API endpoint
- `docs/datadictionary.md`: seeded dataset contract
- `docs/openapi.json`: initial API skeleton
- `db/migrations/001_initial_schema.sql`: first schema scaffold
