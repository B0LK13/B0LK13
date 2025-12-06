import { useState, useEffect } from 'react';
import EmailForm from './EmailForm';
import EmailList from './EmailList';
import EmailLogs from './EmailLogs';

export default function EmailManager() {
  const [activeTab, setActiveTab] = useState('create');
  const [emails, setEmails] = useState([]);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [notification, setNotification] = useState(null);

  useEffect(() => {
    if (activeTab === 'list') {
      fetchEmails();
    } else if (activeTab === 'logs') {
      fetchLogs();
    }
  }, [activeTab]);

  const fetchEmails = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/cloudflare/emails');
      const data = await response.json();
      if (data.success) {
        setEmails(data.configs || []);
      } else {
        showNotification('Failed to fetch emails: ' + data.error, 'error');
      }
    } catch (error) {
      showNotification('Error fetching emails: ' + error.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/cloudflare/emails?type=logs&limit=50');
      const data = await response.json();
      if (data.success) {
        setLogs(data.emails || []);
      } else {
        showNotification('Failed to fetch logs: ' + data.error, 'error');
      }
    } catch (error) {
      showNotification('Error fetching logs: ' + error.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleEmailCreated = (newEmail) => {
    showNotification(`Email ${newEmail.email} created successfully!`, 'success');
    if (activeTab === 'list') {
      fetchEmails();
    }
  };

  const handleEmailDeleted = (email) => {
    setEmails(emails.filter(e => e.email !== email));
    showNotification(`Email ${email} deleted successfully!`, 'success');
  };

  const showNotification = (message, type) => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 5000);
  };

  const tabs = [
    { id: 'create', label: 'Create Email', icon: '➕' },
    { id: 'list', label: 'Manage Emails', icon: '📧' },
    { id: 'logs', label: 'Email Logs', icon: '📊' }
  ];

  return (
    <div className="max-w-6xl mx-auto p-6">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          Cloudflare Email Manager
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Create and manage email addresses with custom routing
        </p>
      </div>

      {/* Notification */}
      {notification && (
        <div className={`mb-6 p-4 rounded-lg ${
          notification.type === 'success' 
            ? 'bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-200 border border-green-200 dark:border-green-800'
            : 'bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-200 border border-red-200 dark:border-red-800'
        }`}>
          <div className="flex items-center">
            <span className="mr-2">
              {notification.type === 'success' ? '✅' : '❌'}
            </span>
            {notification.message}
          </div>
        </div>
      )}

      {/* Tab Navigation */}
      <div className="mb-8">
        <nav className="flex space-x-1 bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                activeTab === tab.id
                  ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              <span className="mr-2">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md">
        {activeTab === 'create' && (
          <EmailForm onEmailCreated={handleEmailCreated} />
        )}
        
        {activeTab === 'list' && (
          <EmailList 
            emails={emails}
            loading={loading}
            onEmailDeleted={handleEmailDeleted}
            onRefresh={fetchEmails}
          />
        )}
        
        {activeTab === 'logs' && (
          <EmailLogs 
            logs={logs}
            loading={loading}
            onRefresh={fetchLogs}
          />
        )}
      </div>

      {/* Quick Stats */}
      <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="p-3 bg-blue-100 dark:bg-blue-900/20 rounded-lg">
              <span className="text-2xl">📧</span>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
                Total Emails
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {emails.length}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="p-3 bg-green-100 dark:bg-green-900/20 rounded-lg">
              <span className="text-2xl">📨</span>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
                Recent Logs
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {logs.length}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
          <div className="flex items-center">
            <div className="p-3 bg-purple-100 dark:bg-purple-900/20 rounded-lg">
              <span className="text-2xl">⚡</span>
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
                Active Routes
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {emails.filter(e => e.action).length}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
