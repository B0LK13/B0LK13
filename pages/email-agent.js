import Layout from '../components/Layout';
import SEO from '../components/SEO';
import Header from '../components/Header';
import Footer from '../components/Footer';
import Dashboard from '../components/EmailAgent/Dashboard';
import { getGlobalData } from '../utils/global-data';

export default function EmailAgentPage({ globalData }) {
  return (
    <Layout>
      <SEO 
        title={`Email Agent - ${globalData.name}`} 
        description="Automated email processing and GitHub task creation" 
      />
      <Header name={globalData.name} />
      <Dashboard />
      <Footer copyrightText={globalData.footerText} />
    </Layout>
  );
}

export function getStaticProps() {
  const globalData = getGlobalData();
  return { props: { globalData } };
}
