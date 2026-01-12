import { useState, useEffect } from 'react';
import StatusCard from './StatusCard';
import ProcessButton from './ProcessButton';
import ConfigPanel from './ConfigPanel';

export default function Dashboard() {
  const [status, setStatus] = useState(null);
  const [processing, setProcessing] = useState(false);
  const [lastResult, setLastResult] = useState(null);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchStatus = async () => {
    try {
      const response = await fetch('/api/email-agent/status');
      const data = await response.json();
      setStatus(data);
    } catch (error) {
      console.error('Error fetching status:', error);
    }
  };

  const processEmails = async () => {
    setProcessing(true);
    try {
      const response = await fetch('/api/email-agent/process', {
        method: 'POST',
      });
      const result = await response.json();
      setLastResult(result);
      await fetchStatus();
    } catch (error) {
      console.error('Error processing emails:', error);
      setLastResult({
        success: false,
        error: error.message,
      });
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          Email Agent Dashboard
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Monitor and manage your automated email processing
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatusCard
          title="Agent Status"
          value={status?.status || 'Unknown'}
          icon="🤖"
          color={status?.success ? 'green' : 'red'}
        />
        
        <StatusCard
          title="Processed Emails"
          value={status?.processedCount || 0}
          icon="📧"
          color="blue"
        />
        
        <StatusCard
          title="Last Check"
          value={status?.lastProcessed ? new Date(status.lastProcessed).toLocaleTimeString() : 'Never'}
          icon="⏰"
          color="gray"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-white">
            Manual Processing
          </h2>
          <ProcessButton
            onClick={processEmails}
            processing={processing}
          />
          
          {lastResult && (
            <div className={`mt-4 p-4 rounded-lg ${
              lastResult.success 
                ? 'bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-200'
                : 'bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-200'
            }`}>
              {lastResult.success ? (
                <div>
                  <p className="font-medium">Processing completed!</p>
                  <p className="text-sm mt-1">
                    Processed: {lastResult.processed} emails, 
                    Created: {lastResult.tasksCreated} tasks
                  </p>
                </div>
              ) : (
                <div>
                  <p className="font-medium">Processing failed</p>
                  <p className="text-sm mt-1">{lastResult.error}</p>
                </div>
              )}
            </div>
          )}
        </div>

        <ConfigPanel onConfigUpdate={fetchStatus} />
      </div>
    </div>
  );
}
