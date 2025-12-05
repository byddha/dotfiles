
/**
 * @param { string } summary
 * @returns { string }
 */
function findSuitableNerdFontIcon(summary = "") {
    const defaultIcon = '󰍡';  // notification icon
    if(summary.length === 0) return defaultIcon;

    const keywordsToIcons = {
        'reboot': '󰜉',
        'restart': '󰜉',
        'record': '󰑊',
        'battery': '󰁹',
        'power': '󰚥',
        'screenshot': '󰹑',
        'welcome': '󰠮',
        'time': '󰥔',
        'installed': '󰏓',
        'download': '󰏓',
        'configuration reloaded': '󰑓',
        'config': '󰒓',
        'unable': '󰋗',
        "couldn't": '󰋗',
        'error': '󰅚',
        'update': '󰚰',
        'control': '󰒓',
        'music': '󰝚',
        'audio': '󰝚',
        'install': '󰏔',
        'input': '󰌌',
        'keyboard': '󰌌',
        'file': '󰉋',
        'folder': '󰉋',
        'volume': '󰕾',
        'brightness': '󰃟',
        'network': '󰖩',
        'wifi': '󰖩',
        'bluetooth': '󰂯',
        'calendar': '󰃭',
        'email': '󰇮',
        'mail': '󰇮',
        'warning': '󰀪',
        'success': '󰄬',
        'complete': '󰄬',
        'startswith:file': '󰉋', // Declarative startsWith check
    };

    const lowerSummary = summary.toLowerCase();

    for (const [keyword, icon] of Object.entries(keywordsToIcons)) {
        if (keyword.startsWith('startswith:')) {
            const startsWithKeyword = keyword.replace('startswith:', '');
            if (lowerSummary.startsWith(startsWithKeyword)) {
                return icon;
            }
        } else if (lowerSummary.includes(keyword)) {
            return icon;
        }
    }

    return defaultIcon;
}

/**
 * @param { number | string | Date } timestamp
 * @returns { string }
 */
const getFriendlyNotifTimeString = (timestamp) => {
    if (!timestamp) return '';
    const messageTime = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - messageTime.getTime();

    // Less than 1 minute
    if (diffMs < 60000)
        return 'Now';

    // Same day - show relative time
    if (messageTime.toDateString() === now.toDateString()) {
        const diffMinutes = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);

        if (diffHours > 0) {
            return `${diffHours}h`;
        } else {
            return `${diffMinutes}m`;
        }
    }

    // Yesterday
    if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
        return 'Yesterday';

    // Older dates
    return Qt.formatDateTime(messageTime, "MMMM dd");
};
