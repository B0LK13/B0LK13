import { getMdaDataset } from '../../../lib/mda/loadDataset';

export default function handler(req, res) {
  const dataset = getMdaDataset();

  res.status(200).json({
    meta: dataset.meta,
    cities: dataset.cities.map((city) => ({
      id: city.id,
      name: city.name,
      country: city.country,
      costBandMedian: city.costBand.median,
      mobilityScore: city.scores.mobility,
      netScore: city.scores.net,
      evidenceLabel: city.connectivity.evidenceLabel,
      lastVerified: city.connectivity.lastVerified,
    })),
  });
}
