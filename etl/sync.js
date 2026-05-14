const fs = require('fs');
const path = require('path');

const inputPath = path.join(__dirname, 'city-seed.csv');
const outputPath = path.join(process.cwd(), 'data', 'mda', 'city-snapshots.json');

const parseBoolean = (value) => value === 'true';
const parseNumber = (value) => Number(value);
const parseList = (value) =>
  value
    ? value
        .split('|')
        .map((item) => item.trim())
        .filter(Boolean)
    : [];

const slugToCountryId = (value) => value.toLowerCase().replace(/[^a-z0-9]+/g, '-');

const calculateMobilityScore = ({ railHub, coachHub, airportWithin60, hsr, freqScore }) => {
  const score = (railHub ? 1 : 0) + (coachHub ? 1 : 0) + (airportWithin60 ? 1 : 0) + (hsr ? 1 : 0) + freqScore;
  return Math.min(5, Number(score.toFixed(1)));
};

const calculateNetScore = ({ fixedDown, fixedUp, fixedLatency, mobileDown, mobileUp, stabilityPositive }) => {
  const fixedEligible = fixedDown >= 50 && fixedUp >= 10 && fixedLatency <= 50;
  const mobileEligible = mobileDown >= 50 && mobileUp >= 10;

  let score = fixedEligible ? 2 : 0;

  if (fixedEligible && fixedDown >= 150 && fixedUp >= 50) {
    score += 1;
  }

  if (mobileDown >= 100 && mobileUp >= 20) {
    score += 1;
  }

  if (stabilityPositive) {
    score += 1;
  }

  if (!fixedEligible && mobileEligible) {
    score = Math.max(1, score) - 1;
  }

  return Math.max(0, Math.min(5, score));
};

const calculateTripLengthDays = (startDate, endDate) => {
  const millisecondsPerDay = 24 * 60 * 60 * 1000;
  const start = new Date(`${startDate}T00:00:00Z`);
  const end = new Date(`${endDate}T00:00:00Z`);
  return Math.floor((end - start) / millisecondsPerDay) + 1;
};

const calculateUwvTaskDue = (startDate) => {
  const start = new Date(`${startDate}T00:00:00Z`);
  start.setUTCDate(start.getUTCDate() - 14);
  return start.toISOString().slice(0, 10);
};

const parseSeed = (raw) => {
  const [headerLine, ...rows] = raw.trim().split(/\r?\n/);
  const headers = headerLine.split(';');

  return rows.map((row) => {
    const values = row.split(';');
    return headers.reduce((record, header, index) => {
      record[header] = values[index] ?? '';
      return record;
    }, {});
  });
};

const buildDataset = (seedRows) => {
  const generatedAt = new Date().toISOString();
  const rollingWindowDays = 365;

  const cities = seedRows.map((row) => {
    const mobilityScore = calculateMobilityScore({
      railHub: parseBoolean(row.railHub),
      coachHub: parseBoolean(row.coachHub),
      airportWithin60: parseBoolean(row.airportWithin60),
      hsr: parseBoolean(row.hsr),
      freqScore: parseNumber(row.freqScore),
    });

    const netScore = calculateNetScore({
      fixedDown: parseNumber(row.fixedDown),
      fixedUp: parseNumber(row.fixedUp),
      fixedLatency: parseNumber(row.fixedLatency),
      mobileDown: parseNumber(row.mobileDown),
      mobileUp: parseNumber(row.mobileUp),
      stabilityPositive: parseBoolean(row.stabilityPositive),
    });

    const tripLengthDays = calculateTripLengthDays(row.tripStart, row.tripEnd);
    const lastVerified = row.lastVerified;

    return {
      id: row.id,
      countryId: slugToCountryId(row.country),
      name: row.name,
      country: row.country,
      languageNotes: row.languageNotes,
      techSceneNotes: row.techSceneNotes,
      safetyIndex: parseNumber(row.safetyIndex),
      tradeOffs: parseList(row.tradeOffs),
      redFlags: parseList(row.redFlags),
      costBand: {
        low: parseNumber(row.costLow),
        median: parseNumber(row.costMedian),
        high: parseNumber(row.costHigh),
        currency: 'EUR',
        sourceUrl: row.costSourceUrl,
      },
      connectivity: {
        fixedMedianDownMbps: parseNumber(row.fixedDown),
        fixedMedianUpMbps: parseNumber(row.fixedUp),
        fixedLatencyMs: parseNumber(row.fixedLatency),
        mobileMedianDownMbps: parseNumber(row.mobileDown),
        mobileMedianUpMbps: parseNumber(row.mobileUp),
        stabilityNote: parseBoolean(row.stabilityPositive)
          ? 'Stable fixed line and favorable mobile fallback in seeded data.'
          : 'Seed data still needs stability verification.',
        lastVerified,
        evidenceLabel: row.evidenceLabel,
        sourceUrl: row.connectivitySourceUrl,
      },
      mobility: {
        railHub: parseBoolean(row.railHub),
        coachHub: parseBoolean(row.coachHub),
        airportWithin60Min: parseBoolean(row.airportWithin60),
        hsr: parseBoolean(row.hsr),
        freqScore: parseNumber(row.freqScore),
        notes: row.mobilityNotes,
        lastVerified,
        evidenceLabel: row.evidenceLabel,
        sourceUrl: row.mobilitySourceUrl,
      },
      coworking: {
        dayPassEur: parseNumber(row.coworkingDaypass),
        monthlyEur: parseNumber(row.coworkingMonthly),
        twentyFourSeven: parseBoolean(row.twentyFourSeven),
        distanceToStationMin: parseNumber(row.distanceStationMin),
        lastVerified,
        evidenceLabel: row.evidenceLabel,
        sourceUrl: row.coworkingSourceUrl,
      },
      compliance: {
        registrationNotes: row.registrationNotes,
        pitfalls: parseList(row.pitfalls),
        legalLinks: parseList(row.legalLinks),
        lastVerified,
        evidenceLabel: row.evidenceLabel,
        sourceUrl: parseList(row.legalLinks)[0] || row.costSourceUrl,
      },
      scores: {
        mobility: mobilityScore,
        net: netScore,
        updatedAt: generatedAt,
      },
      trip: {
        startDate: row.tripStart,
        endDate: row.tripEnd,
        tripLengthDays,
        uwvTaskDue: calculateUwvTaskDue(row.tripStart),
        ehicCheck: parseBoolean(row.ehicCheck),
        postReady: parseBoolean(row.postReady),
      },
      evidence: [
        {
          field: 'costBand',
          evidenceLabel: row.evidenceLabel,
          lastVerified,
          sourceUrl: row.costSourceUrl,
          notes: 'Seed reference used for the current housing and living cost band.',
        },
        {
          field: 'connectivity',
          evidenceLabel: row.evidenceLabel,
          lastVerified,
          sourceUrl: row.connectivitySourceUrl,
          notes: 'Seed reference used for the fixed/mobile connectivity snapshot.',
        },
        {
          field: 'mobility',
          evidenceLabel: row.evidenceLabel,
          lastVerified,
          sourceUrl: row.mobilitySourceUrl,
          notes: 'Seed reference used for rail, coach, airport, and HSR coverage.',
        },
        {
          field: 'coworking',
          evidenceLabel: row.evidenceLabel,
          lastVerified,
          sourceUrl: row.coworkingSourceUrl,
          notes: 'Seed reference used for coworking pricing and station proximity.',
        },
        ...parseList(row.legalLinks).map((link) => ({
          field: 'compliance',
          evidenceLabel: row.evidenceLabel,
          lastVerified,
          sourceUrl: link,
          notes: 'Seed compliance reference that should be refined with official local guidance.',
        })),
      ],
    };
  });

  const totalTripDays = cities.reduce((sum, city) => sum + city.trip.tripLengthDays, 0);

  return {
    meta: {
      generatedAt,
      sourceFile: path.relative(process.cwd(), inputPath),
      totalCities: cities.length,
      rollingWindowDays,
      totalTripDays,
    },
    countries: Array.from(
      new Map(
        cities.map((city) => [
          city.countryId,
          {
            id: city.countryId,
            name: city.country,
            legalLinks: city.compliance.legalLinks,
          },
        ])
      ).values()
    ),
    cities,
  };
};

const rawSeed = fs.readFileSync(inputPath, 'utf8');
const seedRows = parseSeed(rawSeed);
const dataset = buildDataset(seedRows);

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(dataset, null, 2)}\n`, 'utf8');
console.log(`Generated ${path.relative(process.cwd(), outputPath)} from ${path.relative(process.cwd(), inputPath)}`);
