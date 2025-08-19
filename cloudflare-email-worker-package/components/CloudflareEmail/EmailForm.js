import { useState } from 'react';

export default function EmailForm({ onEmailCreated }) {
  const [formData, setFormData] = useState({
    email: '',
    action: 'forward',
    forwardTo: [''],
    webhookUrl: '',
    includeBody: false
  });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState({});

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const handleForwardToChange = (index, value) => {
    const newForwardTo = [...formData.forwardTo];
    newForwardTo[index] = value;
    setFormData(prev => ({ ...prev, forwardTo: newForwardTo }));
  };

  const addForwardAddress = () => {
    setFormData(prev => ({
      ...prev,
      forwardTo: [...prev.forwardTo, '']
    }));
  };

  const removeForwardAddress = (index) => {
    if (formData.forwardTo.length > 1) {
      const newForwardTo = formData.forwardTo.filter((_, i) => i !== index);
      setFormData(prev => ({ ...prev, forwardTo: newForwardTo }));
    }
  };

  const validateForm = () => {
    const newErrors = {};

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!formData.email) {
      newErrors.email = 'Email address is required';
    } else if (!emailRegex.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    // Validate action-specific fields
    if (formData.action === 'forward') {
      const validForwardAddresses = formData.forwardTo.filter(addr => addr.trim());
      if (validForwardAddresses.length === 0) {
        newErrors.forwardTo = 'At least one forward address is required';
      } else {
        const invalidAddresses = validForwardAddresses.filter(addr => !emailRegex.test(addr));
        if (invalidAddresses.length > 0) {
          newErrors.forwardTo = `Invalid email addresses: ${invalidAddresses.join(', ')}`;
        }
      }
    }

    if (formData.action === 'webhook') {
      if (!formData.webhookUrl) {
        newErrors.webhookUrl = 'Webhook URL is required';
      } else {
        try {
          new URL(formData.webhookUrl);
        } catch {
          newErrors.webhookUrl = 'Please enter a valid URL';
        }
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    
    try {
      const submitData = {
        email: formData.email,
        action: formData.action
      };

      if (formData.action === 'forward') {
        submitData.forwardTo = formData.forwardTo.filter(addr => addr.trim());
      } else if (formData.action === 'webhook') {
        submitData.webhookUrl = formData.webhookUrl;
        submitData.includeBody = formData.includeBody;
      }

      const response = await fetch('/api/cloudflare/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(submitData),
      });

      const result = await response.json();

      if (result.success) {
        onEmailCreated(result.config);
        // Reset form
        setFormData({
          email: '',
          action: 'forward',
          forwardTo: [''],
          webhookUrl: '',
          includeBody: false
        });
      } else {
        setErrors({ submit: result.error });
      }
    } catch (error) {
      setErrors({ submit: 'Failed to create email: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6">
      <h2 className="text-xl font-semibold mb-6 text-gray-900 dark:text-white">
        Create New Email Address
      </h2>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Email Address */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Email Address
          </label>
          <input
            type="email"
            name="email"
            value={formData.email}
            onChange={handleInputChange}
            placeholder="user@yourdomain.com"
            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white ${
              errors.email ? 'border-red-500' : 'border-gray-300'
            }`}
          />
          {errors.email && (
            <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.email}</p>
          )}
        </div>

        {/* Action Type */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Action
          </label>
          <select
            name="action"
            value={formData.action}
            onChange={handleInputChange}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
          >
            <option value="forward">Forward to other emails</option>
            <option value="webhook">Send to webhook</option>
            <option value="store">Store in database</option>
          </select>
        </div>

        {/* Forward Addresses */}
        {formData.action === 'forward' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Forward To
            </label>
            {formData.forwardTo.map((address, index) => (
              <div key={index} className="flex mb-2">
                <input
                  type="email"
                  value={address}
                  onChange={(e) => handleForwardToChange(index, e.target.value)}
                  placeholder="recipient@example.com"
                  className={`flex-1 px-3 py-2 border rounded-l-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white ${
                    errors.forwardTo ? 'border-red-500' : 'border-gray-300'
                  }`}
                />
                {formData.forwardTo.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeForwardAddress(index)}
                    className="px-3 py-2 bg-red-500 text-white rounded-r-lg hover:bg-red-600"
                  >
                    ✕
                  </button>
                )}
              </div>
            ))}
            <button
              type="button"
              onClick={addForwardAddress}
              className="mt-2 px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600"
            >
              + Add Address
            </button>
            {errors.forwardTo && (
              <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.forwardTo}</p>
            )}
          </div>
        )}

        {/* Webhook URL */}
        {formData.action === 'webhook' && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Webhook URL
              </label>
              <input
                type="url"
                name="webhookUrl"
                value={formData.webhookUrl}
                onChange={handleInputChange}
                placeholder="https://your-app.com/webhook/email"
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white ${
                  errors.webhookUrl ? 'border-red-500' : 'border-gray-300'
                }`}
              />
              {errors.webhookUrl && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.webhookUrl}</p>
              )}
            </div>
            
            <div className="flex items-center">
              <input
                type="checkbox"
                name="includeBody"
                checked={formData.includeBody}
                onChange={handleInputChange}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label className="ml-2 block text-sm text-gray-700 dark:text-gray-300">
                Include email body in webhook payload
              </label>
            </div>
          </div>
        )}

        {/* Store Action Info */}
        {formData.action === 'store' && (
          <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <p className="text-sm text-blue-800 dark:text-blue-200">
              📦 Emails will be stored in the database and can be retrieved via API or logs.
            </p>
          </div>
        )}

        {/* Submit Error */}
        {errors.submit && (
          <div className="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
            <p className="text-sm text-red-800 dark:text-red-200">{errors.submit}</p>
          </div>
        )}

        {/* Submit Button */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={loading}
            className={`px-6 py-2 rounded-lg font-medium transition-colors ${
              loading
                ? 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-700 text-white'
            }`}
          >
            {loading ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Creating...
              </div>
            ) : (
              'Create Email'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
