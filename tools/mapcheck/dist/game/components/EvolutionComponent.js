"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EvolutionComponent = void 0;
class EvolutionComponent {
    constructor() {
        this.evolutionLevel = 0;
        this.unlockedForms = [0];
        this.evolutionBranch = 0;
    }
    getType() { return "evolution"; }
    serialize() {
        const result = {};
        result["evolutionLevel"] = this.evolutionLevel;
        result["unlockedForms"] = this.unlockedForms;
        result["evolutionBranch"] = this.evolutionBranch;
        return result;
    }
    deserialize(data) {
        this.evolutionLevel = data["evolutionLevel"];
        this.unlockedForms = data["unlockedForms"];
        this.evolutionBranch = data["evolutionBranch"];
    }
}
exports.EvolutionComponent = EvolutionComponent;
