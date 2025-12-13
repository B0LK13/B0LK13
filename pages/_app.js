import '../styles/globals.css';
import 'prismjs/themes/prism-tomorrow.css';

function MyApp({ Component, pageProps }) {
  const themeClass = `theme-${process.env.BLOG_THEME || 'tba'}`;

  return (
    <>
      <span className={themeClass} />
      <Component {...pageProps} />
    </>
  );
}

export default MyApp;
