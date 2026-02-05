import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { generateText } from 'ai';
import { IAIService } from '../../domain/services/ai-service.interface';
import { SongMetadata } from '../../domain/value-objects/song-metadata.vo';
import { ITextSanitizer } from '../../shared/text-sanitizer';

export class GeminiAIService implements IAIService {
  private readonly google: ReturnType<typeof createGoogleGenerativeAI>;
  private readonly modelName: string;
  private readonly sanitizer: ITextSanitizer;

  constructor(apiKey: string, sanitizer: ITextSanitizer, modelName: string = 'gemini-2.5-flash') {
    this.google = createGoogleGenerativeAI({
      apiKey,
    });
    this.modelName = modelName;
    this.sanitizer = sanitizer;
  }

  public async getVibesForSong(
    song: SongMetadata,
  ): Promise<{ name: string; description: string }[]> {
    const prompt = this.constructPrompt(song);

    try {
      const { text } = await generateText({
        model: this.google(this.modelName),
        prompt: prompt,
      });

      return this.parseResponse(text);
    } catch (error) {
      console.error('Error calling Gemini API via AI SDK:', error);
      return [];
    }
  }

  private constructPrompt(song: SongMetadata): string {
    return `
        You are a music curator. Analyze this song:
        Title: "${this.sanitizer.sanitize(song.title)}"
        Artist: "${this.sanitizer.sanitize(song.artist)}"
        Album: "${this.sanitizer.sanitize(song.album || 'Unknown')}"
        Genre: "${this.sanitizer.sanitize(song.genre || 'Unknown')}"

        Task: Return strictly a valid JSON array of objects with 'name' (tag) and 'description' (max 10 words explaining the vibe).
        Example Output: [{"name": "Chill", "description": "Low tempo, relaxed atmosphere"}, {"name": "Summer", "description": "Upbeat and sunny vibes"}, {"name": "Road Trip", "description": "Perfect for long drives and open roads"}]
        
        IMPORTANT: Return ONLY the JSON array. Do not include markdown formatting like  \`\`\`json or \`\`\`. 
      `;
  }

  public async analyzeUserSentiment(prompt: string): Promise<string[]> {
    const systemPrompt = `
        You are a Music Curator and Translator.
        Task: Analyze the user's music request (which can be in any language) and translate it into a list of 5 to 8 standard English music keywords and mood tags.
        Include synonyms and related concepts to broaden the search (e.g., if the user wants "Sad music", include ["Sad", "Melancholy", "Acoustic", "Somber"]).
        
        Input Prompt: "${this.sanitizer.sanitize(prompt)}"

        Rules:
        1. Always output strictly in English.
        2. Return strictly a valid JSON array of strings.
        3. Do not include markdown formatting or explanations.
        
        Example Output: ["Coding", "Focus", "Electronic", "Ambient", "Lofi"]
    `;

    try {
      const { text } = await generateText({
        model: this.google(this.modelName),
        prompt: systemPrompt,
      });

      return this.parseSentimentResponse(text);
    } catch (error) {
      console.error('Error in analyzeUserSentiment:', error);
      // Fallback: basic tokenization
      return this.sanitizer
        .sanitize(prompt)
        .split(/\s+/)
        .filter((word) => word.length > 2);
    }
  }

  private parseSentimentResponse(text: string): string[] {
    try {
      const cleanedText = text
        .replace(/```json/g, '')
        .replace(/```/g, '')
        .trim();
      const tags = JSON.parse(cleanedText);
      if (Array.isArray(tags)) {
        return tags.map((t) => this.sanitizer.sanitize(String(t))).filter((t) => t.length > 0);
      }
      return [];
    } catch {
      return [];
    }
  }

  private parseResponse(text: string): { name: string; description: string }[] {
    try {
      const cleanedText = text
        .replace(/```json/g, '')
        .replace(/```/g, '')
        .trim();
      const vibes = JSON.parse(cleanedText);

      if (!Array.isArray(vibes)) {
        console.warn('Gemini response was not an array:', cleanedText);
        return [];
      }

      interface RawVibe {
        name: string;
        description?: string;
      }

      return (vibes as RawVibe[])
        .filter((v) => v.name && typeof v.name === 'string')
        .map((v) => ({
          name: this.sanitizer.sanitize(v.name).toLowerCase(),
          description: v.description ? this.sanitizer.sanitize(v.description) : '',
        }));
    } catch (error) {
      console.warn('Failed to parse Gemini response:', text, error);
      return [];
    }
  }
}
