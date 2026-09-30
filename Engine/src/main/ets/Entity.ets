import { Component } from './Component';

let nextEntityId: number = 0;

export class Entity {
  readonly id: number;
  tag: string;
  private components: Map<string, Component> = new Map();
  active: boolean = true;

  constructor(tag: string = "") {
    this.id = nextEntityId++;
    this.tag = tag;
  }

  addComponent<T extends Component>(component: T): T {
    this.components.set(component.getType(), component);
    return component;
  }

  getComponent<T extends Component>(type: string): T | null {
    return (this.components.get(type) as T) ?? null;
  }

  hasComponent(type: string): boolean {
    return this.components.has(type);
  }

  removeComponent(type: string): void {
    this.components.delete(type);
  }

  getAllComponents(): Component[] {
    return Array.from(this.components.values());
  }
}
