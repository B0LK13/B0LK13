import fs from 'fs';
import path from 'path';

const getDatasetPath = () => {
  if (process.env.MDA_DATASET_PATH) {
    return path.resolve(process.cwd(), process.env.MDA_DATASET_PATH);
  }

  return path.join(process.cwd(), 'data', 'mda', 'city-snapshots.json');
};

export function getMdaDataset() {
  const datasetPath = getDatasetPath();
  const raw = fs.readFileSync(datasetPath, 'utf8');
  return JSON.parse(raw);
}
