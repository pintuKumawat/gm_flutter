/// Utility class for cleaning and formatting raw HTML strings returned by APIs
/// into clean, readable, well-spaced plain text for Flutter UI widgets.
class HtmlUtils {
  HtmlUtils._();

  /// Clean HTML tags, convert block-level tags into line breaks, decode HTML entities,
  /// and normalize whitespaces. Returns an empty string if input is null or blank.
  static String cleanHtmlToPlainText(String? raw) {
    if (raw == null) return '';
    var text = raw.trim();
    if (text.isEmpty) return '';

    // If it's literally the string "null", "undefined", or similar placeholder
    final lower = text.toLowerCase();
    if (lower == 'null' ||
        lower == 'undefined' ||
        lower == 'none' ||
        lower == 'n/a' ||
        lower == '<p></p>' ||
        lower == '<p>&nbsp;</p>') {
      return '';
    }

    // 1. Convert block closings and line breaks to newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</(p|div|tr|h[1-6])>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</(ul|ol|table)>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<hr\s*/?>', caseSensitive: false), '\n');

    // 2. Strip all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 3. Named HTML entity decoding
    const entityMap = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'",
      '&#34;': '"',
      '&lt;': '<',
      '&gt;': '>',
      '&bull;': '•',
      '&ndash;': '–',
      '&mdash;': '—',
      '&hellip;': '…',
      '&trade;': '™',
      '&reg;': '®',
      '&copy;': '©',
      '&rsquo;': "'",
      '&lsquo;': "'",
      '&rdquo;': '"',
      '&ldquo;': '"',
      '&tilde;': '~',
      '&times;': '×',
      '&divide;': '÷',
      '&deg;': '°',
      '&plusmn;': '±',
      '&micro;': 'µ',
      '&middot;': '·',
      '&frac14;': '¼',
      '&frac12;': '½',
      '&frac34;': '¾',
      '&euro;': '€',
      '&pound;': '£',
      '&yen;': '¥',
      '&cent;': '¢',
      '&inr;': '₹',
      '&#8377;': '₹',
    };

    entityMap.forEach((entity, replacement) {
      text = text.replaceAll(entity, replacement);
    });

    // 4. Numeric decimal entity decoding (e.g. &#160; or &#8211;)
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        final code = int.parse(match[1]!);
        return String.fromCharCode(code);
      } catch (_) {
        return '';
      }
    });

    // 5. Numeric hex entity decoding (e.g. &#xA0; or &#x2013;)
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      try {
        final code = int.parse(match[1]!, radix: 16);
        return String.fromCharCode(code);
      } catch (_) {
        return '';
      }
    });

    // 6. Strip zero-width & non-printable control characters
    text = text.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\uFFFD]'), '');

    // 7. Format lines and remove redundant spaces/newlines
    final lines = text.split('\n');
    final cleanLines = <String>[];
    bool lastWasEmpty = false;

    for (final rawLine in lines) {
      // Collapse multiple spaces/tabs within line
      final line = rawLine.replaceAll(RegExp(r'[ \t\u00A0]+'), ' ').trim();
      if (line.isEmpty) {
        if (!lastWasEmpty && cleanLines.isNotEmpty) {
          cleanLines.add('');
          lastWasEmpty = true;
        }
      } else {
        cleanLines.add(line);
        lastWasEmpty = false;
      }
    }

    final result = cleanLines.join('\n').trim();
    if (result.toLowerCase() == 'null' || result.toLowerCase() == 'undefined') {
      return '';
    }
    return result;
  }
}
