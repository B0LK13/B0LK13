import { useState, useEffect } from 'react';

export default function ConfigPanel({ onConfigUpdate }) {
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchConfig();
  }, []);

  const fetchConfig = async () => {
    try {
      const response = await fetch('/api/email-agent/config');
      const data = await response.json();
      if (data.success) {
        setConfig(data.config);
      }
    } catch (error) {
      console.error('Error fetching config:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveConfig = async () => {
    setSaving(true);
    try {
      const response = await fetch('/api/email-agent/config', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      });
      
      const result = await response.json();
      if (result.success && onConfigUpdate) {
        onConfigUpdate();
      }
    } catch (error) {
      console.error('Error saving config:', error);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4 mb-4"></div>
          <div className="space-y-3">
            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded"></div>
            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-5/6"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
      <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-white">
        Configuration
      </h2>
      
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Importance Threshold
          </label>
          <input
            type="range"
            min="0"
            max="1"
            step="0.1"
            value={config?.importanceThreshold || 0.7}
            onChange={(e) => setConfig({
              ...config,
              importanceThreshold: parseFloat(e.target.value)
            })}
            className="w-full"
          />
          <div className="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
            <span>Low (0.0)</span>
            <span className="font-medium">{config?.importanceThreshold || 0.7}</span>
            <span>High (1.0)</span>
          </div>
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id="markAsRead"
            checked={config?.markAsRead || false}
            onChange={(e) => setConfig({
              ...config,
              markAsRead: e.target.checked
            })}
            className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
          />
          <label htmlFor="markAsRead" className="ml-2 block text-sm text-gray-700 dark:text-gray-300">
            Mark processed emails as read
          </label>
        </div>

        <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
          <div className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
            <p><strong>Email Service:</strong> {config?.emailService}</p>
            <p><strong>GitHub User:</strong> {config?.githubUsername}</p>
            <p><strong>Project ID:</strong> {config?.projectId}</p>
          </div>
        </div>

        <button
          onClick={saveConfig}
          disabled={saving}
          className={`w-full py-2 px-4 rounded-lg font-medium transition-colors ${
            saving
              ? 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'
              : 'bg-green-600 hover:bg-green-700 text-white'
          }`}
        >
          {saving ? 'Saving...' : 'Save Configuration'}
        </button>
      </div>
    </div>
  );
}
