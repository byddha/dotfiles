pragma Singleton

import QtQuick
import Quickshell
import "../../Utils"

Singleton {
    id: root

    // Icon substitution table for common applications
    property var substitutions: ({
            "code-url-handler": "visual-studio-code",
            "Code": "visual-studio-code",
            "gnome-tweaks": "org.gnome.tweaks",
            "pavucontrol-qt": "pavucontrol",
            "wps": "wps-office2019-kprometheus",
            "wpsoffice": "wps-office2019-kprometheus",
            "footclient": "foot",
            "zen": "zen-browser",
            "kitty": "kitty"
        })

    // Regex-based substitutions for pattern matching
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    /**
     * Check if an icon exists in the current theme
     * @param iconName - Icon name to check
     * @returns true if icon exists, false otherwise
     */
    function iconExists(iconName) {
        if (!iconName || iconName.length == 0)
            return false;
        return (Quickshell.iconPath(iconName, true).length > 0) && !iconName.includes("image-missing");
    }

    /**
     * Try to find non-symbolic icon variant
     * @param iconName - Base icon name
     * @returns Best icon name (prefers non-symbolic)
     */
    function preferNonSymbolic(iconName) {
        // If it's already symbolic, try without -symbolic suffix
        if (iconName.endsWith("-symbolic")) {
            const nonSymbolic = iconName.replace(/-symbolic$/, "");
            if (iconExists(nonSymbolic)) {
                return nonSymbolic;
            }
        }

        // Try common non-symbolic variants
        const variants = [iconName                    // Original
            , iconName + "-color"         // Some themes use -color suffix
            , iconName + "-app"            // Some themes use -app suffix
            ,];

        for (let i = 0; i < variants.length; i++) {
            if (iconExists(variants[i])) {
                return variants[i];
            }
        }

        return iconName; // Return original if no variants found
    }

    /**
     * Extract app name from reverse domain notation
     * Example: "org.gnome.Terminal" → "Terminal"
     */
    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0];
    }

    /**
     * Convert string to kebab-case
     * Example: "My App" → "my-app"
     */
    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    /**
     * Convert underscores to kebab-case
     * Example: "my_app" → "my-app"
     */
    function getUnderscoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    /**
     * Guess icon name for a window class
     *
     * Uses multiple fallback strategies:
     * 1. Desktop entry lookup
     * 2. Substitution tables
     * 3. Regex substitutions
     * 4. Icon existence checks with name transformations
     * 5. Heuristic desktop entry lookup
     *
     * @param str - Window class name
     * @returns Icon name (or fallback "application-x-executable")
     */
    function guessIcon(str) {
        Logger.debug(`Guessing icon for class: "${str}"`);
        if (!str || str.length == 0)
            return "image-missing";

        var result = "";

        // 1. Desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) {
            result = entry.icon;
            return preferNonSymbolic(result);
        }

        // 2. Normal substitutions
        if (substitutions[str]) {
            result = substitutions[str];
            return preferNonSymbolic(result);
        }
        if (substitutions[str.toLowerCase()]) {
            result = substitutions[str.toLowerCase()];
            return preferNonSymbolic(result);
        }

        // 3. Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(substitution.regex, substitution.replace);
            if (replacedName != str) {
                return preferNonSymbolic(replacedName);
            }
        }

        // 4. Icon exists -> return as is
        if (iconExists(str))
            return preferNonSymbolic(str);

        // 5. Simple name transformations
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased))
            return preferNonSymbolic(lowercased);

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName))
            return preferNonSymbolic(reverseDomainNameAppName);

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName))
            return preferNonSymbolic(lowercasedDomainNameAppName);

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess))
            return preferNonSymbolic(kebabNormalizedGuess);

        const underscoreToKebabGuess = getUnderscoreToKebabAppName(str);
        if (iconExists(underscoreToKebabGuess))
            return preferNonSymbolic(underscoreToKebabGuess);

        // 6. Heuristic desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry)
            return preferNonSymbolic(heuristicEntry.icon);

        // 7. Give up - return fallback
        return "application-x-executable";
    }
}
