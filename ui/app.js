document.addEventListener('DOMContentLoaded', () => {
    const btnRefresh = document.getElementById('btn-refresh');

    // UI Elements
    const daemonStatus = document.getElementById('daemon-status');
    const workerCount = document.getElementById('worker-count');
    const providersList = document.getElementById('providers-list');
    const cpuDetect = document.getElementById('cpu-detect');
    const dockerDetect = document.getElementById('docker-detect');

    // Simulate checking system hardware and dependencies
    async function checkSystem() {
        cpuDetect.textContent = navigator.hardwareConcurrency ? `${navigator.hardwareConcurrency} Cores (Browser API)` : 'Unknown';

        // Try to reach the actual FindingNemos daemon
        try {
            const res = await fetch('http://127.0.0.1:8080/api/v1/status');
            if (res.ok) {
                const data = await res.json();
                daemonStatus.textContent = 'Online';
                daemonStatus.style.color = 'var(--accent-green)';

                // Fetch health
                const healthRes = await fetch('http://127.0.0.1:8080/api/v1/health');
                if (healthRes.ok) {
                    const healthData = await healthRes.json();
                    if (healthData.status === 'healthy') {
                        dockerDetect.textContent = 'Verified via Daemon';
                        dockerDetect.nextElementSibling.className = 'item-status badge badge-online';
                        dockerDetect.nextElementSibling.textContent = 'Healthy';
                    }
                }
            } else {
                setOffline();
            }
        } catch (e) {
            setOffline();
        }
    }

    function setOffline() {
        daemonStatus.textContent = 'Offline';
        daemonStatus.style.color = 'var(--text-muted)';
        dockerDetect.textContent = 'Daemon Unreachable';
        dockerDetect.nextElementSibling.className = 'item-status badge badge-offline';
        dockerDetect.nextElementSibling.textContent = 'Error';
    }

    btnRefresh.addEventListener('click', () => {
        btnRefresh.innerHTML = '<svg class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 11-6.219-8.56"></path></svg> Refreshing...';

        setTimeout(() => {
            checkSystem();
            btnRefresh.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"></polyline><polyline points="1 20 1 14 7 14"></polyline><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg> Refresh';
        }, 800);
    });

    // Initial check
    checkSystem();
});
