export interface ITextSanitizer {
  sanitize(text: string): string;
}

export class TextSanitizer implements ITextSanitizer {
  /**
   * Sanitizes input text for use in prompts.
   * Removes potentially harmful characters and escapes quotes.
   * @param text The input string to sanitize.
   * @returns The sanitized string.
   */
  public sanitize(text: string): string {
    if (!text) return '';

    // 1. Trim whitespace
    let sanitized = text.trim();

    // 2. Strip HTML tags to prevent XSS
    sanitized = sanitized.replace(/<[^>]*>?/gm, '');

    // 3. Escape backslashes first to prevent unintended escaping
    sanitized = sanitized.replace(/\\/g, '\\\\');

    // 4. Escape double quotes to prevent breaking out of prompt strings
    sanitized = sanitized.replace(/"/g, '\\"');

    // 5. Normalize whitespace (replace newlines/tabs with single space to keep prompt clean)
    sanitized = sanitized.replace(/\s+/g, ' ');

    return sanitized;
  }
}
