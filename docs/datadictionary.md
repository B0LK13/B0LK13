# MDA Cross Platform Data Dictionary

## Dataset
- `meta.lastGeneratedAt`: ISO timestamp for the latest ETL run.
- `meta.totalCities`: Number of seeded cities included in the snapshot.
- `meta.rollingWindowDays`: Rolling monitoring window for buitenland-dagen.
- `meta.totalTripDays`: Sum of all seeded trip durations within the exported snapshot.

## City snapshot
- `id`: Stable slug used by the UI and API.
- `name`: Display name of the city.
- `country`: Country name for grouping and filtering.
- `languageNotes`: Short note about day-to-day language expectations.
- `techSceneNotes`: Short note about the local IT ecosystem.
- `tradeOffs[]`: Human-readable trade-offs surfaced in the detail panel.
- `redFlags[]`: Important constraints or warnings for the city.

## Cost band
- `costBand.low`: Lower monthly housing/living estimate in EUR.
- `costBand.median`: Median monthly estimate in EUR.
- `costBand.high`: Upper monthly estimate in EUR.
- `costBand.sourceUrl`: Seed reference URL for the cost estimate.

## Connectivity
- `connectivity.fixedMedianDownMbps`: Median fixed download speed.
- `connectivity.fixedMedianUpMbps`: Median fixed upload speed.
- `connectivity.fixedLatencyMs`: Reference latency in milliseconds.
- `connectivity.mobileMedianDownMbps`: Median mobile download speed.
- `connectivity.mobileMedianUpMbps`: Median mobile upload speed.
- `connectivity.stabilityNote`: Short qualifier used for the NetScore bonus.
- `connectivity.lastVerified`: ISO date of the seeded verification timestamp.
- `connectivity.evidenceLabel`: High, Medium, or Low.
- `connectivity.sourceUrl`: Seed reference URL for the connectivity inputs.

## Mobility
- `mobility.railHub`, `mobility.coachHub`, `mobility.airportWithin60Min`, `mobility.hsr`: Boolean indicators used in MobilityScore.
- `mobility.freqScore`: Decimal bonus between 0 and 1 representing connection density.
- `mobility.notes`: Short mobility summary shown in the detail panel.
- `mobility.lastVerified`: ISO date for the seeded mobility verification timestamp.
- `mobility.evidenceLabel`: High, Medium, or Low.
- `mobility.sourceUrl`: Seed reference URL for the mobility inputs.

## Coworking
- `coworking.dayPassEur`: Day-pass price in EUR.
- `coworking.monthlyEur`: Monthly membership estimate in EUR.
- `coworking.twentyFourSeven`: Whether at least one 24/7 option is seeded.
- `coworking.distanceToStationMin`: Travel minutes from the main station.
- `coworking.lastVerified`: ISO date of the seeded verification timestamp.
- `coworking.evidenceLabel`: High, Medium, or Low.
- `coworking.sourceUrl`: Seed reference URL for coworking data.

## Compliance
- `compliance.registrationNotes`: Summary of registration options and caveats.
- `compliance.pitfalls[]`: Known compliance pitfalls to monitor.
- `compliance.legalLinks[]`: Seeded official or reference links.
- `compliance.lastVerified`: ISO date for the seeded compliance verification timestamp.
- `compliance.evidenceLabel`: High, Medium, or Low.
- `compliance.sourceUrl`: Primary seeded reference URL.

## Scores
- `scores.mobility`: `min(5, railHub + coachHub + airportWithin60Min + hsr + freqScore)`.
- `scores.net`: Seeded NetScore based on fixed/mobile thresholds, stability, and mobile-only penalty.
- `scores.updatedAt`: ISO timestamp for the latest score calculation.

## Trip
- `trip.startDate`, `trip.endDate`: ISO dates for the seeded trip.
- `trip.tripLengthDays`: Inclusive number of days between start and end.
- `trip.uwvTaskDue`: ISO date 14 days before `startDate`.
- `trip.ehicCheck`: Whether EHIC preparation is complete.
- `trip.postReady`: Whether Dutch post/briefadres handling is ready.

## Evidence entries
- `evidence[].field`: Logical field or section that the reference supports.
- `evidence[].evidenceLabel`: High, Medium, or Low.
- `evidence[].lastVerified`: ISO date tied to the reference.
- `evidence[].sourceUrl`: URL stored alongside the snapshot.
- `evidence[].notes`: Short rationale for why the reference matters.
