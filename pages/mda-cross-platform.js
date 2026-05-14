import Footer from '../components/Footer';
import Header from '../components/Header';
import Layout, { GradientBackground } from '../components/Layout';
import Dashboard from '../components/MdaDashboard/Dashboard';
import SEO from '../components/SEO';
import { getGlobalData } from '../utils/global-data';
import { getMdaDataset } from '../lib/mda/loadDataset';

export default function MdaCrossPlatformPage({ dataset, globalData }) {
  return (
    <Layout maxWidthClass="max-w-6xl">
      <SEO
        title={`MDA Cross Platform - ${globalData.name}`}
        description="Seeded city comparison dashboard for costs, connectivity, mobility, compliance, and trip planning."
      />
      <Header name={globalData.name} />
      <Dashboard dataset={dataset} />
      <Footer copyrightText={globalData.footerText} />
      <GradientBackground variant="large" className="fixed top-20 opacity-30 dark:opacity-50" />
      <GradientBackground variant="small" className="absolute bottom-0 opacity-20 dark:opacity-10" />
    </Layout>
  );
}

export function getStaticProps() {
  const globalData = getGlobalData();
  const dataset = getMdaDataset();

  return {
    props: {
      dataset,
      globalData,
    },
  };
}
