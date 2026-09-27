export interface TagComponent {
  tags: string[];
}

export function createTag(...tags: string[]): TagComponent {
  return { tags: tags };
}
