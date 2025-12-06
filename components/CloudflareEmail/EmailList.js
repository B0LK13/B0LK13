import { useState } from 'react';

export default function EmailList({ emails, loading, onEmailDeleted, onRefresh }) {
  const [deletingEmail, setDeletingEmail] = useState(null);

  const handleDelete = async (email) => {
    if (!confirm(`Are you sure you want to delete ${email}?`)) {
      return;
    }

    setDeletingEmail(email);
    
    try {
      const response = await fetch(`/api/cloudflare/emails?email=${encodeURIComponent(email)}`, {
        method: 'DELETE',
      });

      const result = await response.json();

      if (result.success) {
        onEmailDeleted(email);
      } else {
        alert('Failed to delete email: ' + result.error);
      }
    } catch (error) {
      alert('Error deleting email: ' + error.message);
    } finally {
      setDeletingEmail(null);
    }
  };

  const getActionBadge = (action) => {
    const badges = {
      forward: { color: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-200', icon: '↗️' },
      webhook: { color: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-200', icon: '🔗' },
      store: { color: 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-200', icon: '📦' }
    };

    const badge = badges[action] || badges.store;
    
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${badge.color}`}>
        <span className="mr-1">{badge.icon}</span>
        {action}
      </span>
    );
  };

  const getActionDetails = (config) => {
    switch (config.action) {
      case 'forward':
        return `Forward to: ${config.forwardTo?.join(', ') || 'None'}`;
      case 'webhook':
        return `Webhook: ${config.webhookUrl || 'Not set'}`;
      case 'store':
        return 'Store in database';
      default:
        return 'Unknown action';
    }
  };

  if (loading) {
    return (
      <div className="p-6">
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span className="ml-2 text-gray-600 dark:text-gray-400">Loading emails...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
          Email Configurations ({emails.length})
        </h2>
        <button
          onClick={onRefresh}
          className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors"
        >
          🔄 Refresh
        </button>
      </div>

      {emails.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-6xl mb-4">📧</div>
          <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
            No email addresses configured
          </h3>
          <p className="text-gray-600 dark:text-gray-400">
            Create your first email address to get started.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {emails.map((config, index) => (
            <div
              key={config.email || index}
              className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center mb-2">
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mr-3">
                      {config.email}
                    </h3>
                    {getActionBadge(config.action)}
                  </div>
                  
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                    {getActionDetails(config)}
                  </p>
                  
                  <div className="flex items-center text-xs text-gray-500 dark:text-gray-500">
                    <span>Created: {new Date(config.createdAt).toLocaleDateString()}</span>
                    {config.id && (
                      <span className="ml-4">ID: {config.id.slice(0, 8)}...</span>
                    )}
                  </div>
                </div>

                <div className="flex items-center space-x-2 ml-4">
                  <button
                    onClick={() => handleDelete(config.email)}
                    disabled={deletingEmail === config.email}
                    className={`px-3 py-1 rounded text-sm font-medium transition-colors ${
                      deletingEmail === config.email
                        ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                        : 'bg-red-500 text-white hover:bg-red-600'
                    }`}
                  >
                    {deletingEmail === config.email ? (
                      <div className="flex items-center">
                        <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-white mr-1"></div>
                        Deleting...
                      </div>
                    ) : (
                      '🗑️ Delete'
                    )}
                  </button>
                </div>
              </div>

              {/* Additional Details */}
              {config.action === 'webhook' && config.includeBody && (
                <div className="mt-3 p-2 bg-gray-50 dark:bg-gray-700 rounded text-xs text-gray-600 dark:text-gray-400">
                  ℹ️ Email body included in webhook payload
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
