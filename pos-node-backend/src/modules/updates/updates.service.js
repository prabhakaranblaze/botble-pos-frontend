/**
 * Updates Service
 * Handles app version checking and update information
 *
 * For now, version info is hardcoded. Later can be moved to database.
 */

// Hardcoded version info - update these when releasing new versions
const CURRENT_VERSION = {
  version: '1.0.0',
  build_number: 1,
  release_date: '2026-01-08',
  download_url: 'https://pub-1664f164de65435e943bd597c050e247.r2.dev/releases/StampSmartPOS_Setup_1.0.0.exe',
  release_notes: [
    'Initial release',
    'Full POS functionality',
    'Offline support',
    'Session management',
    'Receipt printing',
  ],
  mandatory: false,
  min_supported_version: '1.0.0',
};

/**
 * Get the latest version information
 */
function getLatestVersion() {
  return {
    latest_version: CURRENT_VERSION.version,
    build_number: CURRENT_VERSION.build_number,
    release_date: CURRENT_VERSION.release_date,
    download_url: CURRENT_VERSION.download_url,
    release_notes: CURRENT_VERSION.release_notes,
    mandatory: CURRENT_VERSION.mandatory,
    min_supported_version: CURRENT_VERSION.min_supported_version,
    file_size: '45 MB', // Approximate size
  };
}

/**
 * Check if a version needs update
 * @param {string} currentVersion - The client's current version (e.g., "1.0.0")
 * @returns {object} Update check result
 */
function checkForUpdate(currentVersion) {
  const latest = getLatestVersion();
  const needsUpdate = compareVersions(currentVersion, latest.latest_version) < 0;
  const isBelowMinimum = compareVersions(currentVersion, latest.min_supported_version) < 0;

  return {
    current_version: currentVersion,
    latest_version: latest.latest_version,
    update_available: needsUpdate,
    mandatory: isBelowMinimum || latest.mandatory,
    download_url: needsUpdate ? latest.download_url : null,
    release_notes: needsUpdate ? latest.release_notes : [],
    release_date: latest.release_date,
    file_size: latest.file_size,
  };
}

/**
 * Compare two semantic versions
 * @returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2
 */
function compareVersions(v1, v2) {
  const parts1 = v1.split('.').map(Number);
  const parts2 = v2.split('.').map(Number);

  for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
    const p1 = parts1[i] || 0;
    const p2 = parts2[i] || 0;

    if (p1 < p2) return -1;
    if (p1 > p2) return 1;
  }

  return 0;
}

module.exports = {
  getLatestVersion,
  checkForUpdate,
  compareVersions,
};
