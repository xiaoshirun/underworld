export type AIType = 'wander' | 'chase' | 'patrol' | 'boss';

export interface AIComponent {
  type: AIType;
  speed: number;
  detectRange: number;
  targetEntity: number;
  stateTimer: number;
  patrolPoints: number[];
  patrolIndex: number;
  data: number[];
}

export function createAI(type: AIType, speed: number, detectRange: number): AIComponent {
  return { type: type, speed: speed, detectRange: detectRange, targetEntity: -1, stateTimer: 0, patrolPoints: [], patrolIndex: 0, data: [] };
}
