// API Base URL
const API_BASE_URL = window.location.origin;

// State Management
let currentUser = null;
let authToken = null;
let refreshToken = null;
let currentPage = 1;
let totalPages = 1;
let organizations = [];
let response = null; // Store response globally for pagination

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
    // Check if user is already logged in
    const savedToken = localStorage.getItem('authToken');
    const savedUser = localStorage.getItem('currentUser');
    
    if (savedToken && savedUser) {
        authToken = savedToken;
        refreshToken = localStorage.getItem('refreshToken');
        currentUser = JSON.parse(savedUser);
        showDashboard();
        loadOrganizations();
    } else {
        showLogin();
    }

    // Event Listeners
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);
    document.getElementById('createOrgBtn').addEventListener('click', () => showModal('createOrgModal'));
    document.getElementById('closeCreateModal').addEventListener('click', () => hideModal('createOrgModal'));
    document.getElementById('cancelCreateBtn').addEventListener('click', () => hideModal('createOrgModal'));
    document.getElementById('createOrgForm').addEventListener('submit', handleCreateOrganization);
    document.getElementById('closeViewModal').addEventListener('click', () => hideModal('viewOrgModal'));
    document.getElementById('closeEditModal').addEventListener('click', () => hideModal('editOrgModal'));
    document.getElementById('cancelEditBtn').addEventListener('click', () => hideModal('editOrgModal'));
    document.getElementById('editOrgForm').addEventListener('submit', handleUpdateOrganization);
    const closeChangePlanModal = document.getElementById('closeChangePlanModal');
    const cancelChangePlanBtn = document.getElementById('cancelChangePlanBtn');
    const confirmChangePlanBtn = document.getElementById('confirmChangePlanBtn');
    if (closeChangePlanModal) closeChangePlanModal.addEventListener('click', () => hideModal('changePlanModal'));
    if (cancelChangePlanBtn) cancelChangePlanBtn.addEventListener('click', () => hideModal('changePlanModal'));
    if (confirmChangePlanBtn) confirmChangePlanBtn.addEventListener('click', handleChangePlan);
    document.getElementById('searchInput').addEventListener('input', debounce(handleSearch, 300));

    // Close modal on outside click
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal || e.target.classList.contains('modal-overlay')) {
                hideModal(modal.id);
            }
        });
    });

    // Event delegation for action buttons
    const tableBody = document.getElementById('organizationsTableBody');
    if (tableBody) {
        tableBody.addEventListener('click', (e) => {
            // Check if clicked element is an action button or inside one
            const button = e.target.closest('.action-btn');
            if (!button) return;

            // Prevent default button behavior
            e.preventDefault();
            e.stopPropagation();

            // Find the parent row
            const row = button.closest('tr');
            if (!row) {
                console.error('Could not find parent row for action button');
                return;
            }

            // Get organization data from data attributes
            const orgId = row.dataset.orgId;
            const orgName = row.dataset.orgName;
            const orgStatus = row.dataset.orgStatus === 'true';

            if (!orgId) {
                console.error('Organization ID not found in row data');
                return;
            }

            // Call appropriate function based on button class
            try {
                if (button.classList.contains('view')) {
                    viewOrganization(orgId);
                } else if (button.classList.contains('edit')) {
                    editOrganization(orgId);
                } else if (button.classList.contains('toggle')) {
                    toggleOrganizationStatus(orgId, orgStatus);
                } else if (button.classList.contains('delete')) {
                    deleteOrganization(orgId, orgName);
                }
            } catch (error) {
                console.error('Error handling action button click:', error);
                showNotification('An error occurred. Please try again.', 'error');
            }
        });
    }
});

// Screen Management
function showLogin() {
    document.getElementById('loginScreen').classList.add('active');
    document.getElementById('dashboardScreen').classList.remove('active');
    // Clear any saved credentials
    localStorage.removeItem('authToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('currentUser');
    authToken = null;
    refreshToken = null;
    currentUser = null;
}

function showDashboard() {
    document.getElementById('loginScreen').classList.remove('active');
    document.getElementById('dashboardScreen').classList.add('active');
    if (currentUser) {
        // Update sidebar user info
        const sidebarUserName = document.getElementById('sidebarUserName');
        const userInitials = document.getElementById('userInitials');
        if (sidebarUserName) {
            sidebarUserName.textContent = currentUser.name || 'Super Admin';
        }
        if (userInitials && currentUser.name) {
            const initials = currentUser.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
            userInitials.textContent = initials || 'SA';
        }
    }
}

// Modal Management
function showModal(modalId) {
    document.getElementById(modalId).classList.add('active');
}

function hideModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
    if (modalId === 'createOrgModal') {
        document.getElementById('createOrgForm').reset();
        document.getElementById('createOrgError').classList.remove('show');
    }
    if (modalId === 'editOrgModal') {
        document.getElementById('editOrgForm').reset();
        document.getElementById('editOrgError').classList.remove('show');
    }
}

// API Functions
async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE_URL}/api/v1${endpoint}`;
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers,
    };

    if (authToken) {
        headers['Authorization'] = `Bearer ${authToken}`;
    }

    try {
        const response = await fetch(url, {
            ...options,
            headers,
        });

        const data = await response.json();

        if (!response.ok) {
            if (response.status === 401) {
                // Token expired, try to refresh
                const refreshed = await refreshAuthToken();
                if (refreshed) {
                    // Retry request with new token
                    headers['Authorization'] = `Bearer ${authToken}`;
                    const retryResponse = await fetch(url, {
                        ...options,
                        headers,
                    });
                    return await retryResponse.json();
                } else {
                    handleLogout();
                    throw new Error('Session expired. Please login again.');
                }
            }
            throw new Error(data.message || 'Request failed');
        }

        return data;
    } catch (error) {
        console.error('API Request Error:', error);
        throw error;
    }
}

async function refreshAuthToken() {
    if (!refreshToken) return false;

    try {
        const response = await fetch(`${API_BASE_URL}/api/v1/auth/refresh`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ refreshToken }),
        });

        const data = await response.json();

        if (response.ok && data.data) {
            authToken = data.data.token || data.data.accessToken;
            refreshToken = data.data.refreshToken || refreshToken;
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('refreshToken', refreshToken);
            return true;
        }
        return false;
    } catch (error) {
        console.error('Token refresh error:', error);
        return false;
    }
}

// Authentication
async function handleLogin(e) {
    e.preventDefault();
    const errorDiv = document.getElementById('loginError');
    errorDiv.classList.remove('show');
    errorDiv.textContent = '';

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const role = document.getElementById('role').value;

    try {
        const response = await apiRequest('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password, role }),
        });

        if (response.data) {
            authToken = response.data.token || response.data.accessToken;
            refreshToken = response.data.refreshToken;
            currentUser = response.data.user;

            // Check if user is super admin
            if (!currentUser.isSuperAdmin) {
                errorDiv.textContent = 'Access denied. Super admin access required.';
                errorDiv.classList.add('show');
                return;
            }

            // Save to localStorage
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('refreshToken', refreshToken);
            localStorage.setItem('currentUser', JSON.stringify(currentUser));

            showDashboard();
            loadOrganizations();
        } else {
            throw new Error(response.message || 'Login failed');
        }
    } catch (error) {
        errorDiv.textContent = error.message || 'Login failed. Please check your credentials.';
        errorDiv.classList.add('show');
    }
}

function handleLogout() {
    authToken = null;
    refreshToken = null;
    currentUser = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('currentUser');
    showLogin();
}

// Organizations Management
async function loadOrganizations(page = 1, search = '') {
    try {
        const params = new URLSearchParams({
            page: page.toString(),
            limit: '20',
        });
        if (search) {
            params.append('search', search);
        }

        response = await apiRequest(`/organizations?${params.toString()}`);

        if (response.data) {
            organizations = Array.isArray(response.data) ? response.data : response.data.data || [];
            currentPage = response.page || page;
            totalPages = response.totalPages || 1;

            updateStats(response);
            renderOrganizationsTable();
            renderPagination();
        }
    } catch (error) {
        console.error('Error loading organizations:', error);
        document.getElementById('organizationsTableBody').innerHTML = `
            <tr>
                <td colspan="6" class="table-loading">
                    <div>Error loading organizations: ${error.message}</div>
                </td>
            </tr>
        `;
    }
}

function updateStats(response) {
    const total = response.total || organizations.length;
    const active = organizations.filter(org => org.is_active).length;
    
    const totalEl = document.getElementById('totalOrganizations');
    const activeEl = document.getElementById('activeOrganizations');
    const usersEl = document.getElementById('totalUsers');
    
    if (totalEl) totalEl.textContent = total.toLocaleString();
    if (activeEl) activeEl.textContent = active.toLocaleString();
    if (usersEl) usersEl.textContent = '-';
}

function renderOrganizationsTable() {
    const tbody = document.getElementById('organizationsTableBody');
    
    if (organizations.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" class="table-loading">
                    <div>No organizations found</div>
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = organizations.map(org => `
        <tr data-org-id="${org.id}" data-org-name="${escapeHtml(org.name)}" data-org-status="${org.is_active}">
            <td>
                <div style="display: flex; flex-direction: column; gap: 4px;">
                    <strong>${escapeHtml(org.name)}</strong>
                    <span style="font-size: 0.875rem; color: var(--text-secondary);">${escapeHtml(org.email)}</span>
                </div>
            </td>
            <td>${escapeHtml(org.industry || '-')}</td>
            <td>
                <span style="padding: 4px 8px; background: var(--gray-100); border-radius: 4px; font-size: 0.875rem; font-weight: 500;">
                    ${escapeHtml(org.subscription_plan || 'Free')}
                </span>
            </td>
            <td>
                <span class="status-badge ${org.is_active ? 'active' : 'inactive'}">
                    ${org.is_active ? 'Active' : 'Inactive'}
                </span>
            </td>
            <td>${formatDate(org.created_at)}</td>
            <td>
                <div class="action-buttons">
                    <button class="action-btn view" title="View Details" type="button">
                        <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M10 12.5C11.3807 12.5 12.5 11.3807 12.5 10C12.5 8.61929 11.3807 7.5 10 7.5C8.61929 7.5 7.5 8.61929 7.5 10C7.5 11.3807 8.61929 12.5 10 12.5Z" stroke="currentColor" stroke-width="1.5"/>
                            <path d="M10 3.4375C6.21875 3.4375 3.125 6.53125 3.125 10.3125C3.125 14.0938 6.21875 17.1875 10 17.1875C13.7812 17.1875 16.875 14.0938 16.875 10.3125C16.875 6.53125 13.7812 3.4375 10 3.4375ZM10 15.625C7.24375 15.625 5 13.3812 5 10.625C5 7.86875 7.24375 5.625 10 5.625C12.7562 5.625 15 7.86875 15 10.625C15 13.3812 12.7562 15.625 10 15.625Z" fill="currentColor"/>
                        </svg>
                    </button>
                    <button class="action-btn edit" title="Edit" type="button">
                        <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M14.1667 2.5C14.3855 2.28113 14.6453 2.10752 14.9313 1.98906C15.2173 1.87061 15.5238 1.80957 15.8333 1.80957C16.1429 1.80957 16.4494 1.87061 16.7354 1.98906C17.0214 2.10752 17.2812 2.28113 17.5 2.5C17.7189 2.71887 17.8925 2.97871 18.0109 3.26472C18.1294 3.55073 18.1904 3.85725 18.1904 4.16667C18.1904 4.47609 18.1294 4.78261 18.0109 5.06862C17.8925 5.35463 17.7189 5.61447 17.5 5.83333L6.25 17.0833L1.66667 18.3333L2.91667 13.75L14.1667 2.5Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </button>
                    <button class="action-btn toggle" title="${org.is_active ? 'Deactivate' : 'Activate'}" type="button">
                        <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M10 18.3333C14.6024 18.3333 18.3333 14.6024 18.3333 10C18.3333 5.39763 14.6024 1.66667 10 1.66667C5.39763 1.66667 1.66667 5.39763 1.66667 10C1.66667 14.6024 5.39763 18.3333 10 18.3333Z" stroke="currentColor" stroke-width="1.5"/>
                            <path d="M7.5 10L9.16667 11.6667L12.5 8.33333" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </button>
                    <button class="action-btn delete" title="Delete" type="button">
                        <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M5 5L15 15M15 5L5 15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
}

function renderPagination() {
    const pagination = document.getElementById('pagination');
    const paginationInfo = document.getElementById('paginationInfo');
    
    const start = organizations.length > 0 ? (currentPage - 1) * 20 + 1 : 0;
    const end = start + organizations.length - 1;
    const total = response?.total || 0;
    
    if (paginationInfo) {
        paginationInfo.textContent = `Showing ${start} - ${end} of ${total}`;
    }
    
    if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
    }

    const prevDisabled = currentPage === 1 ? 'disabled' : '';
    const nextDisabled = currentPage === totalPages ? 'disabled' : '';

    pagination.innerHTML = `
        <button ${prevDisabled} onclick="loadOrganizations(${currentPage - 1}, '${document.getElementById('searchInput').value}')">Previous</button>
        <button ${nextDisabled} onclick="loadOrganizations(${currentPage + 1}, '${document.getElementById('searchInput').value}')">Next</button>
    `;
}

async function viewOrganization(orgId) {
    try {
        const response = await apiRequest(`/organizations/${orgId}`);
        
        if (response.data) {
            const org = response.data;
            const details = document.getElementById('orgDetails');
            const actions = document.getElementById('viewOrgActions');
            
            // Get admin user from users array
            const adminUser = org.users && org.users.length > 0 ? org.users.find(u => u.role === 'admin') : null;
            
            details.innerHTML = `
                <div class="detail-row">
                    <div class="detail-label">Name:</div>
                    <div class="detail-value">${escapeHtml(org.name)}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Email:</div>
                    <div class="detail-value">${escapeHtml(org.email)}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Phone:</div>
                    <div class="detail-value">${escapeHtml(org.phone || '-')}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Industry:</div>
                    <div class="detail-value">${escapeHtml(org.industry || '-')}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Address:</div>
                    <div class="detail-value">${escapeHtml(org.address || '-')}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Subscription Plan:</div>
                    <div class="detail-value">
                        <div style="display: flex; align-items: center; gap: 12px;">
                            <span class="plan-badge plan-${(org.subscription_plan || 'Free').toLowerCase()}" style="padding: 6px 12px; border-radius: 6px; font-size: 0.875rem; font-weight: 600;">
                                ${escapeHtml(org.subscription_plan || 'Free')}
                            </span>
                            <button class="btn-change-plan" onclick="showChangePlanModal('${org.id}', '${escapeHtml(org.subscription_plan || 'Free')}')" style="padding: 4px 12px; font-size: 0.75rem; background: var(--primary); color: white; border: none; border-radius: 4px; cursor: pointer; transition: all 0.2s;">
                                Change Plan
                            </button>
                        </div>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Employee Limit:</div>
                    <div class="detail-value">${org.employee_limit || '-'}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Status:</div>
                    <div class="detail-value">
                        <span class="status-badge ${org.is_active ? 'active' : 'inactive'}">
                            ${org.is_active ? 'Active' : 'Inactive'}
                        </span>
                    </div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Created:</div>
                    <div class="detail-value">${formatDate(org.created_at)}</div>
                </div>
                ${org.website ? `
                <div class="detail-row">
                    <div class="detail-label">Website:</div>
                    <div class="detail-value"><a href="${escapeHtml(org.website)}" target="_blank" rel="noopener noreferrer">${escapeHtml(org.website)}</a></div>
                </div>
                ` : ''}
                ${org.tax_id ? `
                <div class="detail-row">
                    <div class="detail-label">Tax ID:</div>
                    <div class="detail-value">${escapeHtml(org.tax_id)}</div>
                </div>
                ` : ''}
                ${adminUser ? `
                <div class="detail-row">
                    <div class="detail-label">Admin:</div>
                    <div class="detail-value">${escapeHtml(adminUser.name)} (${escapeHtml(adminUser.email)})</div>
                </div>
                ` : ''}
            `;
            
            // Add action buttons
            if (actions) {
                actions.innerHTML = `
                    <button type="button" class="btn btn-secondary" onclick="hideModal('viewOrgModal'); editOrganization('${org.id}')">
                        <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M14.1667 2.5C14.3855 2.28113 14.6453 2.10752 14.9313 1.98906C15.2173 1.87061 15.5238 1.80957 15.8333 1.80957C16.1429 1.80957 16.4494 1.87061 16.7354 1.98906C17.0214 2.10752 17.2812 2.28113 17.5 2.5C17.7189 2.71887 17.8925 2.97871 18.0109 3.26472C18.1294 3.55073 18.1904 3.85725 18.1904 4.16667C18.1904 4.47609 18.1294 4.78261 18.0109 5.06862C17.8925 5.35463 17.7189 5.61447 17.5 5.83333L6.25 17.0833L1.66667 18.3333L2.91667 13.75L14.1667 2.5Z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        <span>Edit</span>
                    </button>
                    <button type="button" class="btn ${org.is_active ? 'btn-warning' : 'btn-success'}" onclick="hideModal('viewOrgModal'); toggleOrganizationStatus('${org.id}', ${org.is_active})">
                        <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M10 18.3333C14.6024 18.3333 18.3333 14.6024 18.3333 10C18.3333 5.39763 14.6024 1.66667 10 1.66667C5.39763 1.66667 1.66667 5.39763 1.66667 10C1.66667 14.6024 5.39763 18.3333 10 18.3333Z" stroke="currentColor" stroke-width="1.5"/>
                            <path d="M7.5 10L9.16667 11.6667L12.5 8.33333" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        <span>${org.is_active ? 'Deactivate' : 'Activate'}</span>
                    </button>
                    <button type="button" class="btn btn-danger" onclick="hideModal('viewOrgModal'); deleteOrganization('${org.id}', '${escapeHtml(org.name)}')">
                        <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M5 5L15 15M15 5L5 15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                        <span>Delete</span>
                    </button>
                `;
            }
            
            showModal('viewOrgModal');
        }
    } catch (error) {
        showNotification('Error loading organization details: ' + error.message, 'error');
    }
}

async function editOrganization(orgId) {
    try {
        const response = await apiRequest(`/organizations/${orgId}`);
        
        if (response.data) {
            const org = response.data;
            
            // Populate edit form
            document.getElementById('editOrgId').value = org.id;
            document.getElementById('editOrgName').value = org.name || '';
            document.getElementById('editOrgEmail').value = org.email || '';
            document.getElementById('editOrgPhone').value = org.phone || '';
            document.getElementById('editOrgIndustry').value = org.industry || '';
            document.getElementById('editOrgAddress').value = org.address || '';
            document.getElementById('editSubscriptionPlan').value = org.subscription_plan || 'Free';
            document.getElementById('editTaxId').value = org.tax_id || '';
            document.getElementById('editWebsite').value = org.website || '';
            
            // Clear any previous errors
            document.getElementById('editOrgError').classList.remove('show');
            document.getElementById('editOrgError').textContent = '';
            
            showModal('editOrgModal');
        }
    } catch (error) {
        showNotification('Error loading organization: ' + error.message, 'error');
    }
}

async function handleUpdateOrganization(e) {
    e.preventDefault();
    const errorDiv = document.getElementById('editOrgError');
    errorDiv.classList.remove('show');
    errorDiv.textContent = '';

    const orgId = document.getElementById('editOrgId').value;
    const formData = new FormData(e.target);
    const data = {
        name: formData.get('name'),
        email: formData.get('email'),
        phone: formData.get('phone') || null,
        address: formData.get('address') || null,
        industry: formData.get('industry'),
        subscriptionPlan: formData.get('subscriptionPlan'),
        taxId: formData.get('taxId') || null,
        website: formData.get('website') || null,
    };

    try {
        const response = await apiRequest(`/organizations/${orgId}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });

        if (response.data) {
            hideModal('editOrgModal');
            loadOrganizations(currentPage, document.getElementById('searchInput').value);
            showNotification('Organization updated successfully!', 'success');
        } else {
            throw new Error(response.message || 'Failed to update organization');
        }
    } catch (error) {
        errorDiv.textContent = error.message || 'Failed to update organization. Please check all fields.';
        errorDiv.classList.add('show');
    }
}

async function toggleOrganizationStatus(orgId, currentStatus) {
    if (!confirm(`Are you sure you want to ${currentStatus ? 'deactivate' : 'activate'} this organization?`)) {
        return;
    }

    try {
        const response = await apiRequest(`/organizations/${orgId}/toggle-status`, {
            method: 'PATCH',
        });

        if (response.data) {
            loadOrganizations(currentPage, document.getElementById('searchInput').value);
            showNotification(response.message || `Organization ${currentStatus ? 'deactivated' : 'activated'} successfully!`, 'success');
        } else {
            throw new Error(response.message || 'Failed to toggle organization status');
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
    }
}

async function deleteOrganization(orgId, orgName) {
    if (!confirm(`Are you sure you want to delete "${orgName}"? This action cannot be undone and will delete all associated users and employees.`)) {
        return;
    }

    try {
        const response = await apiRequest(`/organizations/${orgId}`, {
            method: 'DELETE',
        });

        if (response.data || response.message) {
            loadOrganizations(currentPage, document.getElementById('searchInput').value);
            showNotification('Organization deleted successfully!', 'success');
        } else {
            throw new Error(response.message || 'Failed to delete organization');
        }
    } catch (error) {
        showNotification('Error: ' + error.message, 'error');
    }
}

async function handleCreateOrganization(e) {
    e.preventDefault();
    const errorDiv = document.getElementById('createOrgError');
    errorDiv.classList.remove('show');
    errorDiv.textContent = '';

    const formData = new FormData(e.target);
    const data = {
        name: formData.get('name'),
        email: formData.get('email'),
        phone: formData.get('phone') || null,
        address: formData.get('address') || null,
        industry: formData.get('industry'),
        subscriptionPlan: formData.get('subscriptionPlan'),
        taxId: formData.get('taxId') || null,
        website: formData.get('website') || null,
        adminName: formData.get('adminName'),
        adminEmail: formData.get('adminEmail'),
        adminPassword: formData.get('adminPassword'),
    };

    try {
        const response = await apiRequest('/organizations', {
            method: 'POST',
            body: JSON.stringify(data),
        });

        if (response.data) {
            hideModal('createOrgModal');
            // Reset search and reload from page 1
            const searchInput = document.getElementById('searchInput');
            if (searchInput) searchInput.value = '';
            loadOrganizations(1, '');
            // Show success notification
            showNotification('Organization created successfully!', 'success');
        } else {
            throw new Error(response.message || 'Failed to create organization');
        }
    } catch (error) {
        errorDiv.textContent = error.message || 'Failed to create organization. Please check all fields.';
        errorDiv.classList.add('show');
    }
}

function handleSearch(e) {
    const searchTerm = e.target.value;
    loadOrganizations(1, searchTerm);
}

// Utility Functions
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateString) {
    if (!dateString) return '-';
    try {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
        });
    } catch (e) {
        return '-';
    }
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Notification function
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 16px 24px;
        background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#2563eb'};
        color: white;
        border-radius: 8px;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        z-index: 10000;
        animation: slideIn 0.3s ease;
        max-width: 400px;
    `;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Add animation styles
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// Plan change functionality
let currentPlanOrgId = null;
let selectedPlan = null;

function showChangePlanModal(orgId, currentPlan) {
    currentPlanOrgId = orgId;
    selectedPlan = currentPlan;
    
    const planOptions = document.getElementById('planOptions');
    const plans = ['Free', 'Basic', 'Premium', 'Enterprise'];
    const planLimits = {
        'Free': { employees: 10, features: 'Basic features' },
        'Basic': { employees: 50, features: 'Standard features' },
        'Premium': { employees: 200, features: 'Advanced features' },
        'Enterprise': { employees: 1000, features: 'All features + Support' }
    };
    
    planOptions.innerHTML = plans.map(plan => `
        <div class="plan-option ${plan.toLowerCase() === currentPlan.toLowerCase() ? 'selected' : ''}" 
             data-plan="${plan}" 
             onclick="selectPlan('${plan}')">
            <div class="plan-option-header">
                <input type="radio" name="plan" value="${plan}" ${plan.toLowerCase() === currentPlan.toLowerCase() ? 'checked' : ''} 
                       onchange="selectPlan('${plan}')">
                <span class="plan-option-name plan-${plan.toLowerCase()}">${plan}</span>
                ${plan.toLowerCase() === currentPlan.toLowerCase() ? '<span class="current-badge">Current</span>' : ''}
            </div>
            <div class="plan-option-details">
                <div class="plan-detail">
                    <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M10 18.3333C14.6024 18.3333 18.3333 14.6024 18.3333 10C18.3333 5.39763 14.6024 1.66667 10 1.66667C5.39763 1.66667 1.66667 5.39763 1.66667 10C1.66667 14.6024 5.39763 18.3333 10 18.3333Z" stroke="currentColor" stroke-width="1.5"/>
                        <path d="M7.5 10L9.16667 11.6667L12.5 8.33333" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                    <span>Up to ${planLimits[plan].employees} employees</span>
                </div>
                <div class="plan-detail">
                    <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M10 18.3333C14.6024 18.3333 18.3333 14.6024 18.3333 10C18.3333 5.39763 14.6024 1.66667 10 1.66667C5.39763 1.66667 1.66667 5.39763 1.66667 10C1.66667 14.6024 5.39763 18.3333 10 18.3333Z" stroke="currentColor" stroke-width="1.5"/>
                        <path d="M7.5 10L9.16667 11.6667L12.5 8.33333" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                    <span>${planLimits[plan].features}</span>
                </div>
            </div>
        </div>
    `).join('');
    
    document.getElementById('changePlanError').classList.remove('show');
    document.getElementById('changePlanError').textContent = '';
    showModal('changePlanModal');
}

function selectPlan(plan) {
    selectedPlan = plan;
    document.querySelectorAll('.plan-option').forEach(option => {
        if (option.dataset.plan === plan) {
            option.classList.add('selected');
            option.querySelector('input[type="radio"]').checked = true;
        } else {
            option.classList.remove('selected');
            option.querySelector('input[type="radio"]').checked = false;
        }
    });
}

async function handleChangePlan() {
    if (!currentPlanOrgId || !selectedPlan) {
        showNotification('Please select a plan', 'error');
        return;
    }
    
    const errorDiv = document.getElementById('changePlanError');
    errorDiv.classList.remove('show');
    errorDiv.textContent = '';
    
    try {
        const response = await apiRequest(`/organizations/${currentPlanOrgId}`, {
            method: 'PUT',
            body: JSON.stringify({ subscriptionPlan: selectedPlan }),
        });
        
        if (response.data) {
            hideModal('changePlanModal');
            loadOrganizations(currentPage, document.getElementById('searchInput').value);
            showNotification(`Subscription plan updated to ${selectedPlan} successfully!`, 'success');
            // Refresh view modal if open
            if (document.getElementById('viewOrgModal').classList.contains('active')) {
                viewOrganization(currentPlanOrgId);
            }
        } else {
            throw new Error(response.message || 'Failed to update plan');
        }
    } catch (error) {
        let errorMessage = 'Failed to update subscription plan. Please try again.';
        if (error.message) {
            errorMessage = error.message;
            // If it's a validation error, try to extract the specific field error
            if (error.message.includes('phone') || error.message.includes('Phone')) {
                errorMessage = 'Phone number format is invalid. Please use a valid phone number format.';
            }
        }
        errorDiv.textContent = errorMessage;
        errorDiv.classList.add('show');
        console.error('Plan change error:', error);
    }
}

// Make functions available globally
window.viewOrganization = viewOrganization;
window.editOrganization = editOrganization;
window.toggleOrganizationStatus = toggleOrganizationStatus;
window.deleteOrganization = deleteOrganization;
window.showChangePlanModal = showChangePlanModal;
window.selectPlan = selectPlan;
