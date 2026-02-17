import { VibeTag } from '../entities/vibe-tag';

export function deduplicateTags(tags: VibeTag[]): VibeTag[] {
  return Array.from(new Map(tags.map((tag) => [tag.name, tag])).values());
}

export function deduplicateByName<T extends { name: string }>(items: T[]): T[] {
  return Array.from(new Map(items.map((item) => [item.name, item])).values());
}
