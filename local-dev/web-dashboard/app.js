// Local Dashboard JavaScript
class EmailDashboard {
    constructor() {
        this.workerUrl = 'http://localhost:3001';
        this.webhookUrl = 'http://localhost:3003';
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.checkServices();
        this.loadDashboard();
        
        // Auto-refresh every 30 seconds
        setInterval(() => {
            this.checkServices();
            if (document.querySelector('.tab-content.active').id === 'dashboard') {
                this.loadDashboard();
            }
        }, 30000);
    }

    setupEventListeners() {
        // Tab navigation
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const tab = e.target.dataset.tab;
                this.switchTab(tab);
            });
        });

        // Create form
        document.getElementById('create-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.createEmail();
        });

        // Test form
        document.getElementById('test-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.sendTestEmail();
        });

        // Action selector
        document.getElementById('action').addEventListener('change', (e) => {
            this.toggleActionFields(e.target.value);
        });

        // Webhook URL selector
        document.getElementById('webhook-url').addEventListener('change', (e) => {
            const customInput = document.getElementById('custom-webhook');
            if (e.target.value === 'custom') {
                customInput.style.display = 'block';
                customInput.required = true;
            } else {
                customInput.style.display = 'none';
                customInput.required = false;
            }
        });
    }

    async checkServices() {
        // Check worker
        try {
            const response = await fetch(`${this.workerUrl}/health`);
            const workerStatus = document.getElementById('worker-status');
            if (response.ok) {
                workerStatus.textContent = '✅ Worker Online';
                workerStatus.className = 'status online';
            } else {
                throw new Error('Worker offline');
            }
        } catch (error) {
            const workerStatus = document.getElementById('worker-status');
            workerStatus.textContent = '❌ Worker Offline';
            workerStatus.className = 'status offline';
        }

        // Check webhook server
        try {
            const response = await fetch(`${this.webhookUrl}/health`);
            const webhookStatus = document.getElementById('webhook-status');
            if (response.ok) {
                webhookStatus.textContent = '✅ Webhooks Online';
                webhookStatus.className = 'status online';
            } else {
                throw new Error('Webhook server offline');
            }
        } catch (error) {
            const webhookStatus = document.getElementById('webhook-status');
            webhookStatus.textContent = '❌ Webhooks Offline';
            webhookStatus.className = 'status offline';
        }
    }

    switchTab(tabName) {
        // Update nav buttons
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(tabName).classList.add('active');

        // Load tab-specific data
        switch (tabName) {
            case 'dashboard':
                this.loadDashboard();
                break;
            case 'emails':
                this.loadEmails();
                break;
            case 'logs':
                this.loadLogs();
                break;
            case 'test':
                this.loadTestOptions();
                break;
        }
    }

    async loadDashboard() {
        try {
            // Load stats
            const [configsRes, logsRes, webhookRes] = await Promise.all([
                fetch(`${this.workerUrl}/api/config`),
                fetch(`${this.workerUrl}/api/emails?limit=50`),
                fetch(`${this.webhookUrl}/logs`)
            ]);

            const configs = await configsRes.json();
            const logs = await logsRes.json();
            const webhooks = await webhookRes.json();

            // Update stats
            document.getElementById('total-configs').textContent = configs.configs?.length || 0;
            document.getElementById('total-emails').textContent = logs.emails?.length || 0;
            document.getElementById('webhook-calls').textContent = webhooks.total || 0;
            document.getElementById('stored-emails').textContent = 
                logs.emails?.filter(e => e.status === 'processed').length || 0;

            // Update recent activity
            this.updateRecentActivity(logs.emails?.slice(0, 5) || []);

        } catch (error) {
            console.error('Error loading dashboard:', error);
        }
    }

    updateRecentActivity(recentLogs) {
        const container = document.getElementById('recent-logs');
        
        if (recentLogs.length === 0) {
            container.innerHTML = '<p style="color: #666; text-align: center;">No recent activity</p>';
            return;
        }

        container.innerHTML = recentLogs.map(log => `
            <div class="activity-item">
                <div class="activity-icon">📧</div>
                <div class="activity-content">
                    <strong>${log.subject || '(no subject)'}</strong><br>
                    <small>${log.from_address || log.from} → ${log.to_address || log.to}</small>
                </div>
                <div class="activity-time">
                    ${new Date(log.received_at || log.receivedAt).toLocaleTimeString()}
                </div>
            </div>
        `).join('');
    }

    toggleActionFields(action) {
        document.getElementById('forward-group').style.display = action === 'forward' ? 'block' : 'none';
        document.getElementById('webhook-group').style.display = action === 'webhook' ? 'block' : 'none';
    }

    async createEmail() {
        const formData = {
            email: document.getElementById('email').value,
            action: document.getElementById('action').value
        };

        if (formData.action === 'forward') {
            const forwardTo = document.getElementById('forward-to').value;
            formData.forwardTo = forwardTo.split(',').map(e => e.trim()).filter(e => e);
        }

        if (formData.action === 'webhook') {
            let webhookUrl = document.getElementById('webhook-url').value;
            if (webhookUrl === 'custom') {
                webhookUrl = document.getElementById('custom-webhook').value;
            }
            formData.webhookUrl = webhookUrl;
            formData.includeBody = document.getElementById('include-body').checked;
        }

        try {
            const response = await fetch(`${this.workerUrl}/api/config`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });

            const result = await response.json();

            if (result.success) {
                this.showNotification('Email configuration created successfully!', 'success');
                document.getElementById('create-form').reset();
                this.toggleActionFields('');
            } else {
                this.showNotification(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            this.showNotification(`Error: ${error.message}`, 'error');
        }
    }

    async loadEmails() {
        try {
            const response = await fetch(`${this.workerUrl}/api/config`);
            const result = await response.json();

            const container = document.getElementById('email-list');

            if (!result.success || result.configs.length === 0) {
                container.innerHTML = '<p style="text-align: center; color: #666;">No email configurations found.</p>';
                return;
            }

            container.innerHTML = result.configs.map(config => `
                <div class="email-item">
                    <h3>${config.email}</h3>
                    <p><strong>Action:</strong> ${config.action}</p>
                    <p><strong>Details:</strong> ${this.getConfigDetails(config)}</p>
                    <p><strong>Created:</strong> ${new Date(config.createdAt).toLocaleString()}</p>
                    <div class="email-actions">
                        <button class="btn-danger" onclick="dashboard.deleteEmail('${config.email}')">
                            🗑️ Delete
                        </button>
                    </div>
                </div>
            `).join('');

        } catch (error) {
            console.error('Error loading emails:', error);
        }
    }

    getConfigDetails(config) {
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
    }

    async deleteEmail(email) {
        if (!confirm(`Are you sure you want to delete ${email}?`)) {
            return;
        }

        try {
            const response = await fetch(`${this.workerUrl}/api/config/${encodeURIComponent(email)}`, {
                method: 'DELETE'
            });

            const result = await response.json();

            if (result.success) {
                this.showNotification('Email configuration deleted successfully!', 'success');
                this.loadEmails();
            } else {
                this.showNotification(`Error: ${result.error}`, 'error');
            }
        } catch (error) {
            this.showNotification(`Error: ${error.message}`, 'error');
        }
    }

    async loadLogs() {
        try {
            const response = await fetch(`${this.workerUrl}/api/emails?limit=20`);
            const result = await response.json();

            const container = document.getElementById('logs-list');

            if (!result.success || result.emails.length === 0) {
                container.innerHTML = '<p style="text-align: center; color: #666;">No email logs found.</p>';
                return;
            }

            container.innerHTML = result.emails.map(log => `
                <div class="log-item">
                    <h3>${log.subject || '(no subject)'}</h3>
                    <p><strong>From:</strong> ${log.from_address || log.from}</p>
                    <p><strong>To:</strong> ${log.to_address || log.to}</p>
                    <p><strong>Status:</strong> ${log.status || 'unknown'}</p>
                    <p><strong>Received:</strong> ${new Date(log.received_at || log.receivedAt).toLocaleString()}</p>
                </div>
            `).join('');

        } catch (error) {
            console.error('Error loading logs:', error);
        }
    }

    async loadTestOptions() {
        try {
            const response = await fetch(`${this.workerUrl}/api/config`);
            const result = await response.json();

            const select = document.getElementById('test-to');
            select.innerHTML = '<option value="">Select email address...</option>';

            if (result.success && result.configs.length > 0) {
                result.configs.forEach(config => {
                    const option = document.createElement('option');
                    option.value = config.email;
                    option.textContent = `${config.email} (${config.action})`;
                    select.appendChild(option);
                });
            }
        } catch (error) {
            console.error('Error loading test options:', error);
        }
    }

    async sendTestEmail() {
        const testData = {
            to: document.getElementById('test-to').value,
            from: document.getElementById('test-from').value,
            subject: document.getElementById('test-subject').value,
            body: document.getElementById('test-body').value,
            headers: {
                'Content-Type': 'text/plain',
                'X-Test-Source': 'Local Dashboard'
            }
        };

        try {
            const response = await fetch(`${this.workerUrl}/test-email`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(testData)
            });

            const result = await response.json();
            const resultDiv = document.getElementById('test-result');

            if (result.success) {
                resultDiv.className = 'success';
                resultDiv.innerHTML = `
                    <h3>✅ Test Email Sent Successfully!</h3>
                    <p><strong>Action:</strong> ${result.action}</p>
                    <p><strong>Details:</strong> ${JSON.stringify(result, null, 2)}</p>
                `;
                this.showNotification('Test email sent successfully!', 'success');
            } else {
                resultDiv.className = 'error';
                resultDiv.innerHTML = `
                    <h3>❌ Test Email Failed</h3>
                    <p><strong>Error:</strong> ${result.error}</p>
                `;
                this.showNotification(`Test failed: ${result.error}`, 'error');
            }

            resultDiv.style.display = 'block';

        } catch (error) {
            const resultDiv = document.getElementById('test-result');
            resultDiv.className = 'error';
            resultDiv.innerHTML = `
                <h3>❌ Test Email Failed</h3>
                <p><strong>Error:</strong> ${error.message}</p>
            `;
            resultDiv.style.display = 'block';
            this.showNotification(`Test failed: ${error.message}`, 'error');
        }
    }

    showNotification(message, type) {
        const notification = document.getElementById('notification');
        notification.textContent = message;
        notification.className = `notification ${type}`;
        notification.classList.add('show');

        setTimeout(() => {
            notification.classList.remove('show');
        }, 3000);
    }
}

// Global functions
function refreshEmails() {
    dashboard.loadEmails();
}

function refreshLogs() {
    dashboard.loadLogs();
}

// Initialize dashboard
const dashboard = new EmailDashboard();
