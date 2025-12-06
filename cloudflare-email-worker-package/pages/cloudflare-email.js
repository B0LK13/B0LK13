import { useState, useEffect } from 'react';
import EmailManager from '../components/CloudflareEmail/EmailManager';

export default function CloudflareEmailPage() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="container mx-auto px-4 py-8">
        <EmailManager />
      </div>
    </div>
  );
}
