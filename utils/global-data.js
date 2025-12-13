export const getGlobalData = () => {
  const name = process.env.BLOG_NAME
    ? decodeURI(process.env.BLOG_NAME)
    : 'Jay Doe';
  const blogTitle = process.env.BLOG_TITLE
    ? decodeURI(process.env.BLOG_TITLE)
    : 'Next.js Blog Theme';
  const footerText = process.env.BLOG_FOOTER_TEXT
    ? decodeURI(process.env.BLOG_FOOTER_TEXT)
    : 'All rights reserved.';
  const logoUrl = process.env.BLOG_LOGO
    ? decodeURI(process.env.BLOG_LOGO)
    : '/images/tba-logo.svg';

  return {
    name,
    blogTitle,
    footerText,
    logoUrl,
  };
};
