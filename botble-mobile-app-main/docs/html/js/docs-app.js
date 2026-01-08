// Documentation App JavaScript

class DocsApp {
    constructor() {
        this.currentSection = 'overview';
        this.searchIndex = [];
        this.init();
    }

    init() {
        this.buildNavigation();
        this.buildContent();
        this.buildSearchIndex();
        this.showSection('overview');
        this.setupEventListeners();
        this.setupBackToTop();
        this.hideLoading();
    }

    buildNavigation() {
        const nav = document.getElementById('sidebar-nav');
        let navHTML = '';

        docsData.sections.forEach(section => {
            navHTML += `<div class="nav-section">`;
            navHTML += `<div class="nav-section-title">${section.title}</div>`;
            
            if (section.subsections) {
                section.subsections.forEach(subsection => {
                    navHTML += `<a href="#${subsection.id}" class="nav-item nav-subsection" data-section="${subsection.id}">${subsection.title}</a>`;
                });
            } else {
                navHTML += `<a href="#${section.id}" class="nav-item" data-section="${section.id}">${section.title}</a>`;
            }
            
            navHTML += `</div>`;
        });

        nav.innerHTML = navHTML;
    }

    buildContent() {
        const container = document.getElementById('content-container');
        let contentHTML = '';

        docsData.sections.forEach(section => {
            if (section.subsections) {
                section.subsections.forEach(subsection => {
                    contentHTML += `<div class="content-section" id="section-${subsection.id}">${subsection.content}</div>`;
                });
            } else {
                contentHTML += `<div class="content-section" id="section-${section.id}">${section.content}</div>`;
            }
        });

        container.innerHTML = contentHTML;
    }

    buildSearchIndex() {
        this.searchIndex = [];
        
        docsData.sections.forEach(section => {
            if (section.subsections) {
                section.subsections.forEach(subsection => {
                    this.searchIndex.push({
                        id: subsection.id,
                        title: subsection.title,
                        content: this.stripHTML(subsection.content).toLowerCase(),
                        section: section.title
                    });
                });
            } else {
                this.searchIndex.push({
                    id: section.id,
                    title: section.title,
                    content: this.stripHTML(section.content).toLowerCase(),
                    section: section.title
                });
            }
        });
    }

    stripHTML(html) {
        const tmp = document.createElement('div');
        tmp.innerHTML = html;
        return tmp.textContent || tmp.innerText || '';
    }

    showSection(sectionId) {
        // Hide all sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.classList.remove('active');
        });

        // Show target section
        const targetSection = document.getElementById(`section-${sectionId}`);
        if (targetSection) {
            targetSection.classList.add('active');
        }

        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });

        const activeNavItem = document.querySelector(`[data-section="${sectionId}"]`);
        if (activeNavItem) {
            activeNavItem.classList.add('active');
        }

        this.currentSection = sectionId;
        
        // Update URL hash
        window.location.hash = sectionId;

        // Scroll to top of content
        document.querySelector('.main-content').scrollTop = 0;
    }

    setupEventListeners() {
        // Navigation clicks
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('nav-item')) {
                e.preventDefault();
                const sectionId = e.target.getAttribute('data-section');
                this.showSection(sectionId);

                // Close sidebar on mobile after navigation
                if (window.innerWidth <= 768) {
                    closeSidebar();
                }
            }
        });

        // Handle browser back/forward
        window.addEventListener('hashchange', () => {
            const hash = window.location.hash.substring(1);
            if (hash && hash !== this.currentSection) {
                this.showSection(hash);
            }
        });

        // Handle initial hash
        const initialHash = window.location.hash.substring(1);
        if (initialHash) {
            this.showSection(initialHash);
        }
    }

    search(query) {
        if (!query.trim()) {
            this.clearSearchResults();
            return;
        }

        const results = this.searchIndex.filter(item => 
            item.title.toLowerCase().includes(query.toLowerCase()) ||
            item.content.includes(query.toLowerCase())
        );

        this.displaySearchResults(results, query);
    }

    displaySearchResults(results, query) {
        const nav = document.getElementById('sidebar-nav');
        
        if (results.length === 0) {
            nav.innerHTML = `
                <div class="nav-section">
                    <div class="nav-section-title">No Results</div>
                    <div style="padding: 1rem 1.5rem; color: #64748b; font-size: 0.875rem;">
                        No results found for "${query}"
                    </div>
                </div>
            `;
            return;
        }

        let navHTML = `
            <div class="nav-section">
                <div class="nav-section-title">Search Results (${results.length})</div>
        `;

        results.forEach(result => {
            navHTML += `<a href="#${result.id}" class="nav-item" data-section="${result.id}">
                ${result.title}
                <div style="font-size: 0.75rem; color: #94a3b8; margin-top: 0.25rem;">${result.section}</div>
            </a>`;
        });

        navHTML += `</div>`;
        nav.innerHTML = navHTML;
    }

    clearSearchResults() {
        this.buildNavigation();
        
        // Restore active state
        const activeNavItem = document.querySelector(`[data-section="${this.currentSection}"]`);
        if (activeNavItem) {
            activeNavItem.classList.add('active');
        }
    }

    hideLoading() {
        const loading = document.querySelector('.loading');
        if (loading) {
            loading.style.display = 'none';
        }
    }

    setupBackToTop() {
        const backToTopBtn = document.querySelector('.back-to-top');
        const mainContent = document.querySelector('.main-content');

        mainContent.addEventListener('scroll', () => {
            if (mainContent.scrollTop > 300) {
                backToTopBtn.classList.add('visible');
            } else {
                backToTopBtn.classList.remove('visible');
            }
        });
    }
}

// Global functions
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const isOpen = sidebar.classList.contains('open');

    if (isOpen) {
        closeSidebar();
    } else {
        openSidebar();
    }
}

function openSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('mobile-overlay');
    const menuIcon = document.getElementById('menu-icon');
    const menuBtn = document.querySelector('.mobile-menu-btn');
    const body = document.body;

    sidebar.classList.add('open');
    overlay.classList.add('active');
    menuIcon.innerHTML = '×';

    // Hide mobile menu button when sidebar is open
    if (window.innerWidth <= 768) {
        menuBtn.classList.add('hidden');
        body.style.overflow = 'hidden';
    }

    // Focus management for accessibility
    const firstFocusableElement = sidebar.querySelector('input, a, button');
    if (firstFocusableElement) {
        setTimeout(() => firstFocusableElement.focus(), 300);
    }
}

function closeSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('mobile-overlay');
    const menuIcon = document.getElementById('menu-icon');
    const menuBtn = document.querySelector('.mobile-menu-btn');
    const body = document.body;

    sidebar.classList.remove('open');
    overlay.classList.remove('active');
    menuIcon.innerHTML = '☰';

    // Show mobile menu button when sidebar is closed
    if (window.innerWidth <= 768) {
        menuBtn.classList.remove('hidden');
        body.style.overflow = '';

        // Return focus to menu button for accessibility
        setTimeout(() => menuBtn.focus(), 300);
    } else {
        // Restore body scroll for desktop
        body.style.overflow = '';
    }
}

function searchContent(query) {
    if (window.docsApp) {
        window.docsApp.search(query);
    }
}

function scrollToTop() {
    const mainContent = document.querySelector('.main-content');
    mainContent.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.docsApp = new DocsApp();
});

// Enhanced mobile interactions
document.addEventListener('click', (e) => {
    const sidebar = document.getElementById('sidebar');
    const mobileBtn = document.querySelector('.mobile-menu-btn');

    // Close sidebar when clicking outside on mobile
    if (window.innerWidth <= 768 &&
        !sidebar.contains(e.target) &&
        !mobileBtn.contains(e.target) &&
        sidebar.classList.contains('open')) {
        closeSidebar();
    }
});

// Keyboard navigation support
document.addEventListener('keydown', (e) => {
    const sidebar = document.getElementById('sidebar');

    // Close sidebar with Escape key
    if (e.key === 'Escape' && sidebar.classList.contains('open')) {
        closeSidebar();
    }

    // Trap focus within sidebar when open on mobile
    if (window.innerWidth <= 768 && sidebar.classList.contains('open')) {
        const focusableElements = sidebar.querySelectorAll(
            'input, button, a, [tabindex]:not([tabindex="-1"])'
        );
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        if (e.key === 'Tab') {
            if (e.shiftKey) {
                if (document.activeElement === firstElement) {
                    e.preventDefault();
                    lastElement.focus();
                }
            } else {
                if (document.activeElement === lastElement) {
                    e.preventDefault();
                    firstElement.focus();
                }
            }
        }
    }
});

// Handle window resize
window.addEventListener('resize', () => {
    const menuBtn = document.querySelector('.mobile-menu-btn');

    if (window.innerWidth > 768) {
        closeSidebar();
        // Ensure mobile menu button is hidden on desktop
        menuBtn.classList.remove('hidden');
    } else {
        // Ensure mobile menu button is visible on mobile (unless sidebar is open)
        const sidebar = document.getElementById('sidebar');
        if (!sidebar.classList.contains('open')) {
            menuBtn.classList.remove('hidden');
        }
    }
});

// Touch gesture support for mobile
let touchStartX = 0;
let touchStartY = 0;

document.addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
}, { passive: true });

document.addEventListener('touchend', (e) => {
    const touchEndX = e.changedTouches[0].clientX;
    const touchEndY = e.changedTouches[0].clientY;
    const diffX = touchEndX - touchStartX;
    const diffY = touchEndY - touchStartY;

    // Only handle horizontal swipes
    if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
        const sidebar = document.getElementById('sidebar');

        // Swipe right to open sidebar (from left edge)
        if (diffX > 0 && touchStartX < 50 && !sidebar.classList.contains('open')) {
            openSidebar();
        }
        // Swipe left to close sidebar
        else if (diffX < -50 && sidebar.classList.contains('open')) {
            closeSidebar();
        }
    }
}, { passive: true });
