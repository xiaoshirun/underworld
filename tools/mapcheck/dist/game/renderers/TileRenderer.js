"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TileRenderer = void 0;
const GameConstants_1 = require("../GameConstants");
class TileRenderer {
    render(world, ctx, cameraX, cameraY, screenW, screenH, settings, frameCount) {
        const offX = -cameraX;
        const offY = -cameraY;
        this.renderBackground(ctx, offX, offY, world, cameraX, cameraY, screenW, screenH, frameCount);
        this.renderWorld(ctx, offX, offY, world, cameraX, cameraY, screenW, screenH, frameCount);
    }
    getTile(chunks, worldX, worldY) {
        const tx = Math.floor(worldX / GameConstants_1.TILE_SIZE);
        const ty = Math.floor(worldY / GameConstants_1.TILE_SIZE);
        const cx = Math.floor(tx / GameConstants_1.CHUNK_SIZE);
        const cy = Math.floor(ty / GameConstants_1.CHUNK_SIZE);
        const key = cx + ',' + cy;
        const chunk = chunks.get(key);
        if (chunk === undefined)
            return GameConstants_1.TileType.WALL;
        const lx = tx - cx * GameConstants_1.CHUNK_SIZE;
        const ly = ty - cy * GameConstants_1.CHUNK_SIZE;
        return chunk.tiles[ly][lx];
    }
    renderBackground(c, offX, offY, world, cameraX, cameraY, screenW, screenH, frameCount) {
        const w = screenW;
        const h = screenH;
        const depth = Math.min(1.0, Math.max(0, cameraY / (GameConstants_1.TILE_SIZE * 30)));
        const camWorldX = cameraX + screenW / 2;
        const camWorldY = cameraY + screenH / 2;
        const worldGen = world.worldGen;
        const viewBiome = worldGen.getBiome(camWorldX, camWorldY);
        let topC;
        let midC;
        let botC;
        let farSilhouetteC;
        let midSilhouetteC;
        switch (viewBiome) {
            case GameConstants_1.BiomeType.CRYSTAL:
                topC = '#0a1025';
                midC = '#060d1a';
                botC = '#030812';
                farSilhouetteC = '#0c1530';
                midSilhouetteC = '#081020';
                break;
            case GameConstants_1.BiomeType.MUSHROOM:
                topC = '#150a1e';
                midC = '#100718';
                botC = '#0a0410';
                farSilhouetteC = '#1a0e28';
                midSilhouetteC = '#120a1c';
                break;
            case GameConstants_1.BiomeType.WATER:
                topC = '#061520';
                midC = '#041018';
                botC = '#020a10';
                farSilhouetteC = '#081a28';
                midSilhouetteC = '#051220';
                break;
            case GameConstants_1.BiomeType.LAVA:
                topC = '#1a0a05';
                midC = '#120703';
                botC = '#0a0402';
                farSilhouetteC = '#200e08';
                midSilhouetteC = '#180a05';
                break;
            case GameConstants_1.BiomeType.SHADOW:
                topC = '#0d0520';
                midC = '#080315';
                botC = '#04020a';
                farSilhouetteC = '#0d0520';
                midSilhouetteC = '#0a0318';
                break;
            default:
                if (depth < 0.3) {
                    topC = '#0c0c1e';
                    midC = '#080814';
                    botC = '#050510';
                }
                else if (depth < 0.7) {
                    topC = '#0a0818';
                    midC = '#06050f';
                    botC = '#03030a';
                }
                else {
                    topC = '#0d0520';
                    midC = '#080315';
                    botC = '#04020a';
                }
                farSilhouetteC = depth > 0.5 ? '#0d0520' : '#0e0e1c';
                midSilhouetteC = depth > 0.5 ? '#0a0318' : '#0a0a16';
                break;
        }
        const grad = c.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0, topC);
        grad.addColorStop(0.5, midC);
        grad.addColorStop(1, botC);
        c.fillStyle = grad;
        c.fillRect(0, 0, w, h);
        const farOffX = cameraX * 0.1;
        const farOffY = cameraY * 0.1;
        c.fillStyle = farSilhouetteC;
        c.globalAlpha = 0.6;
        const farStep = 80;
        const farStart = Math.floor(farOffX / farStep) * farStep;
        for (let fx = farStart - farStep; fx < farStart + w + farStep * 2; fx += farStep) {
            const sx = fx - farOffX;
            const hash = Math.abs(Math.floor(fx / farStep) * 2654435761) % 100;
            const stalH = 30 + (hash % 50);
            const stalW = 25 + (hash % 35);
            const ceilY = -(farOffY * 0.3) + (hash % 20);
            c.beginPath();
            c.moveTo(sx, ceilY);
            c.lineTo(sx + stalW / 2, ceilY + stalH);
            c.lineTo(sx + stalW, ceilY);
            c.fill();
            const floorY = h - (farOffY * 0.2) - (hash % 15);
            const stgH = 20 + (hash % 35);
            c.beginPath();
            c.moveTo(sx + 10, floorY);
            c.lineTo(sx + 10 + stalW / 2 - 5, floorY - stgH);
            c.lineTo(sx + 10 + stalW - 10, floorY);
            c.fill();
        }
        c.globalAlpha = 1.0;
        const midOffX = cameraX * 0.3;
        const midOffY = cameraY * 0.3;
        c.fillStyle = midSilhouetteC;
        c.globalAlpha = 0.4;
        const midStep = 50;
        const midStart = Math.floor(midOffX / midStep) * midStep;
        for (let mx = midStart - midStep; mx < midStart + w + midStep * 2; mx += midStep) {
            const sx = mx - midOffX;
            const hash = Math.abs(Math.floor(mx / midStep) * 48271) % 100;
            if (hash < 40) {
                const mStalH = 15 + (hash % 25);
                const ceilY = -(midOffY * 0.4) + (hash % 30);
                c.beginPath();
                c.moveTo(sx, ceilY);
                c.lineTo(sx + 8, ceilY + mStalH);
                c.lineTo(sx + 16, ceilY);
                c.fill();
            }
            if (hash > 60) {
                const mStgH = 10 + (hash % 20);
                const floorY = h - (midOffY * 0.3) - (hash % 20);
                c.beginPath();
                c.moveTo(sx + 5, floorY);
                c.lineTo(sx + 12, floorY - mStgH);
                c.lineTo(sx + 19, floorY);
                c.fill();
            }
        }
        c.globalAlpha = 1.0;
    }
    renderWorld(c, offX, offY, world, cameraX, cameraY, screenW, screenH, frameCount) {
        const chunks = world.chunks;
        const startTX = Math.floor(cameraX / GameConstants_1.TILE_SIZE) - 1;
        const startTY = Math.floor(cameraY / GameConstants_1.TILE_SIZE) - 1;
        const endTX = Math.ceil((cameraX + screenW) / GameConstants_1.TILE_SIZE) + 1;
        const endTY = Math.ceil((cameraY + screenH) / GameConstants_1.TILE_SIZE) + 1;
        const camWorldX = cameraX + screenW / 2;
        const camWorldY = cameraY + screenH / 2;
        const worldGen = world.worldGen;
        const viewBiome = worldGen.getBiome(camWorldX, camWorldY);
        const isShadow = viewBiome === GameConstants_1.BiomeType.SHADOW;
        const floorColor = isShadow ? GameConstants_1.COLOR_SHADOW_FLOOR : GameConstants_1.COLOR_FLOOR;
        const floorVarColor = isShadow ? '#0a0a16' : GameConstants_1.COLOR_FLOOR_VAR;
        const wallColor = isShadow ? GameConstants_1.COLOR_SHADOW_WALL : GameConstants_1.COLOR_WALL;
        for (let ty = startTY; ty <= endTY; ty++) {
            for (let tx = startTX; tx <= endTX; tx++) {
                const screenX = tx * GameConstants_1.TILE_SIZE + offX;
                const screenY = ty * GameConstants_1.TILE_SIZE + offY;
                const tile = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, ty * GameConstants_1.TILE_SIZE);
                if (tile === GameConstants_1.TileType.WALL) {
                    this.renderStaticWall(c, screenX, screenY, tx, ty, wallColor, isShadow, chunks);
                }
                else if (tile === GameConstants_1.TileType.FLOOR) {
                    this.renderStaticFloor(c, screenX, screenY, tx, ty, floorColor, floorVarColor, isShadow, chunks);
                }
                else if (tile === GameConstants_1.TileType.BROKEN_WALL) {
                    this.renderStaticBrokenWall(c, screenX, screenY);
                }
                else if (tile === GameConstants_1.TileType.PLANT) {
                    this.renderStaticPlant(c, screenX, screenY, floorColor);
                }
                else if (tile === GameConstants_1.TileType.GLOW_STONE) {
                    c.fillStyle = isShadow ? GameConstants_1.COLOR_SHADOW_FLOOR : GameConstants_1.COLOR_FLOOR;
                    c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
                    const glowR = 20 + Math.sin(frameCount * 0.05 + tx) * 4;
                    c.globalAlpha = 0.15;
                    c.fillStyle = isShadow ? '#7c3aed' : GameConstants_1.COLOR_GLOW;
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2, screenY + GameConstants_1.TILE_SIZE / 2, glowR, 0, Math.PI * 2);
                    c.fill();
                    c.globalAlpha = 1.0;
                    c.fillStyle = isShadow ? '#8b5cf6' : GameConstants_1.COLOR_GLOW_STONE;
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2, screenY + GameConstants_1.TILE_SIZE / 2, 5, 0, Math.PI * 2);
                    c.fill();
                    c.fillStyle = isShadow ? '#c4b5fd' : '#fff8dc';
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2 - 1, screenY + GameConstants_1.TILE_SIZE / 2 - 1, 2, 0, Math.PI * 2);
                    c.fill();
                }
                else if (tile === GameConstants_1.TileType.WATER) {
                    const waveOff = Math.sin(frameCount * 0.03 + tx * 0.5) * 2;
                    const waveOff2 = Math.sin(frameCount * 0.05 + tx * 0.8) * 1.5;
                    c.globalAlpha = 0.75;
                    c.fillStyle = GameConstants_1.COLOR_WATER;
                    c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
                    c.globalAlpha = 1.0;
                    c.fillStyle = '#0a1a3a';
                    c.globalAlpha = 0.25;
                    c.fillRect(screenX, screenY + GameConstants_1.TILE_SIZE - 8, GameConstants_1.TILE_SIZE, 8);
                    c.globalAlpha = 1.0;
                    const aboveWater = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, (ty - 1) * GameConstants_1.TILE_SIZE);
                    if (aboveWater !== GameConstants_1.TileType.WATER) {
                        c.fillStyle = GameConstants_1.COLOR_WATER_LIGHT;
                        c.globalAlpha = 0.6;
                        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, 2);
                        c.globalAlpha = 0.3;
                        c.fillRect(screenX, screenY + 2, GameConstants_1.TILE_SIZE, 1);
                        c.globalAlpha = 1.0;
                    }
                    c.fillStyle = GameConstants_1.COLOR_WATER_LIGHT;
                    c.globalAlpha = 0.3;
                    c.fillRect(screenX + 4, screenY + 8 + waveOff, 24, 3);
                    c.fillRect(screenX + 8, screenY + 20 - waveOff, 16, 2);
                    c.globalAlpha = 0.15;
                    c.fillRect(screenX + 2 + waveOff2, screenY + 14, 10, 2);
                    c.fillRect(screenX + 18 - waveOff2, screenY + 26, 8, 2);
                    c.globalAlpha = 1.0;
                    const bubbleHash = ((tx * 61 + ty * 113) % 23);
                    if (bubbleHash < 3) {
                        const bubbleY = (frameCount * 0.3 + bubbleHash * 11) % GameConstants_1.TILE_SIZE;
                        const bubbleX = 6 + bubbleHash * 9;
                        c.fillStyle = '#ffffff';
                        c.globalAlpha = 0.25;
                        c.fillRect(screenX + bubbleX, screenY + GameConstants_1.TILE_SIZE - bubbleY, 2, 2);
                        c.globalAlpha = 0.12;
                        c.fillRect(screenX + bubbleX + 5, screenY + GameConstants_1.TILE_SIZE - bubbleY + 4, 1, 1);
                        c.globalAlpha = 1.0;
                    }
                }
                else if (tile === GameConstants_1.TileType.CRYSTAL) {
                    c.fillStyle = GameConstants_1.COLOR_FLOOR;
                    c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
                    const glow = 12 + Math.sin(frameCount * 0.04 + tx + ty) * 4;
                    c.globalAlpha = 0.2;
                    c.fillStyle = GameConstants_1.COLOR_CRYSTAL_GLOW;
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2, screenY + GameConstants_1.TILE_SIZE / 2, glow, 0, Math.PI * 2);
                    c.fill();
                    c.globalAlpha = 1.0;
                    c.fillStyle = GameConstants_1.COLOR_CRYSTAL;
                    c.beginPath();
                    c.moveTo(screenX + GameConstants_1.TILE_SIZE / 2, screenY + 6);
                    c.lineTo(screenX + GameConstants_1.TILE_SIZE / 2 + 6, screenY + GameConstants_1.TILE_SIZE / 2);
                    c.lineTo(screenX + GameConstants_1.TILE_SIZE / 2, screenY + GameConstants_1.TILE_SIZE - 6);
                    c.lineTo(screenX + GameConstants_1.TILE_SIZE / 2 - 6, screenY + GameConstants_1.TILE_SIZE / 2);
                    c.closePath();
                    c.fill();
                    c.fillStyle = '#e0ffff';
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2 - 1, screenY + GameConstants_1.TILE_SIZE / 2 - 2, 2, 0, Math.PI * 2);
                    c.fill();
                }
                else if (tile === GameConstants_1.TileType.MUSHROOM) {
                    c.fillStyle = GameConstants_1.COLOR_FLOOR;
                    c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
                    c.globalAlpha = 0.15;
                    c.fillStyle = GameConstants_1.COLOR_MUSHROOM_GLOW;
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2, screenY + GameConstants_1.TILE_SIZE / 2, 14, 0, Math.PI * 2);
                    c.fill();
                    c.globalAlpha = 1.0;
                    c.fillStyle = GameConstants_1.COLOR_MUSHROOM_STEM;
                    c.fillRect(screenX + 13, screenY + 16, 6, 12);
                    c.fillStyle = GameConstants_1.COLOR_MUSHROOM_CAP;
                    c.beginPath();
                    c.arc(screenX + GameConstants_1.TILE_SIZE / 2, screenY + 14, 9, Math.PI, 0);
                    c.fill();
                    c.fillStyle = '#ffffff';
                    c.beginPath();
                    c.arc(screenX + 13, screenY + 11, 2, 0, Math.PI * 2);
                    c.fill();
                    c.beginPath();
                    c.arc(screenX + 19, screenY + 9, 1.5, 0, Math.PI * 2);
                    c.fill();
                }
                else if (tile === GameConstants_1.TileType.LAVA) {
                    const lavaOff = Math.sin(frameCount * 0.05 + tx * 0.7) * 3;
                    const lavaOff2 = Math.sin(frameCount * 0.08 + tx * 1.2) * 2;
                    c.fillStyle = GameConstants_1.COLOR_LAVA;
                    c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
                    c.fillStyle = '#cd4a00';
                    c.globalAlpha = 0.4;
                    c.fillRect(screenX + 6, screenY + 10 + lavaOff2, 18, 6);
                    c.globalAlpha = 1.0;
                    c.fillStyle = GameConstants_1.COLOR_LAVA_LIGHT;
                    c.globalAlpha = 0.6;
                    c.fillRect(screenX + 4, screenY + 6 + lavaOff, 20, 4);
                    c.fillRect(screenX + 10, screenY + 18 - lavaOff, 14, 3);
                    c.globalAlpha = 1.0;
                    const crustHash = ((tx * 43 + ty * 89) % 11);
                    if (crustHash < 3) {
                        c.fillStyle = '#3a0a00';
                        c.globalAlpha = 0.5;
                        c.fillRect(screenX + 2 + crustHash * 8, screenY + 4 + crustHash * 3, 6, 3);
                        c.fillRect(screenX + 14 - crustHash * 2, screenY + 22 - crustHash * 4, 5, 2);
                        c.globalAlpha = 1.0;
                    }
                    const aboveLava = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, (ty - 1) * GameConstants_1.TILE_SIZE);
                    if (aboveLava !== GameConstants_1.TileType.LAVA) {
                        c.fillStyle = '#ff6600';
                        c.globalAlpha = 0.5 + Math.sin(frameCount * 0.06 + tx) * 0.15;
                        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, 2);
                        c.fillStyle = '#ffaa00';
                        c.globalAlpha = 0.25;
                        c.fillRect(screenX, screenY + 2, GameConstants_1.TILE_SIZE, 1);
                        c.globalAlpha = 1.0;
                    }
                    const emberHash = ((tx * 71 + ty * 127) % 19);
                    if (emberHash < 2) {
                        const emberY = (frameCount * 0.5 + emberHash * 7) % GameConstants_1.TILE_SIZE;
                        c.fillStyle = '#ffcc00';
                        c.globalAlpha = 0.4;
                        c.fillRect(screenX + 8 + emberHash * 10, screenY + GameConstants_1.TILE_SIZE - emberY, 1, 1);
                        c.globalAlpha = 1.0;
                    }
                }
            }
        }
    }
    renderStaticWall(c, screenX, screenY, tx, ty, wallColor, isShadow, chunks) {
        c.fillStyle = wallColor;
        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
        const brickH = 8;
        const brickW = 16;
        const row = ty % 2;
        c.fillStyle = isShadow ? '#2d1050' : GameConstants_1.COLOR_WALL_EDGE;
        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, 1);
        c.fillRect(screenX, screenY + brickH, GameConstants_1.TILE_SIZE, 1);
        c.fillRect(screenX, screenY + brickH * 2, GameConstants_1.TILE_SIZE, 1);
        c.fillRect(screenX, screenY + brickH * 3, GameConstants_1.TILE_SIZE, 1);
        const vOff = row === 0 ? 0 : brickW / 2;
        c.fillRect(screenX + vOff, screenY, 1, brickH);
        c.fillRect(screenX + vOff + brickW, screenY, 1, brickH);
        c.fillRect(screenX + vOff + brickW / 2, screenY + brickH, 1, brickH);
        c.fillRect(screenX + vOff + brickW * 1.5, screenY + brickH, 1, brickH);
        c.fillRect(screenX + vOff, screenY + brickH * 2, 1, brickH);
        c.fillRect(screenX + vOff + brickW, screenY + brickH * 2, 1, brickH);
        c.fillRect(screenX + vOff + brickW / 2, screenY + brickH * 3, 1, brickH);
        const hash = ((tx * 31 + ty * 17) % 7);
        if (hash === 0) {
            c.fillStyle = '#1f1f35';
            c.fillRect(screenX + 4, screenY + 3, 3, 2);
        }
        else if (hash === 1) {
            c.fillStyle = '#1f1f35';
            c.fillRect(screenX + 20, screenY + 18, 4, 2);
        }
        else if (hash === 3) {
            c.fillStyle = '#22223a';
            c.fillRect(screenX + 10, screenY + 12, 2, 3);
        }
        const oreHash = ((tx * 73 + ty * 137) % 47);
        if (oreHash < 3) {
            c.fillStyle = '#8b4513';
            c.fillRect(screenX + 6, screenY + 8, 4, 3);
            c.fillRect(screenX + 9, screenY + 10, 3, 4);
            c.fillStyle = '#cd7f32';
            c.fillRect(screenX + 7, screenY + 9, 2, 2);
            c.fillRect(screenX + 10, screenY + 11, 2, 2);
        }
        else if (oreHash === 3) {
            c.fillStyle = '#4a5568';
            c.fillRect(screenX + 18, screenY + 4, 5, 3);
            c.fillRect(screenX + 20, screenY + 6, 3, 4);
            c.fillStyle = '#718096';
            c.fillRect(screenX + 19, screenY + 5, 3, 2);
        }
        else if (oreHash === 4) {
            c.fillStyle = '#a0aec0';
            c.fillRect(screenX + 4, screenY + 20, 3, 3);
            c.fillRect(screenX + 6, screenY + 22, 4, 2);
            c.fillStyle = '#e2e8f0';
            c.fillRect(screenX + 5, screenY + 21, 2, 2);
        }
        else if (oreHash === 5) {
            c.fillStyle = '#b7791f';
            c.fillRect(screenX + 14, screenY + 14, 4, 3);
            c.fillRect(screenX + 16, screenY + 16, 3, 4);
            c.fillStyle = '#ecc94b';
            c.fillRect(screenX + 15, screenY + 15, 2, 2);
        }
        const belowTile = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, (ty + 1) * GameConstants_1.TILE_SIZE);
        if (belowTile === GameConstants_1.TileType.FLOOR || belowTile === GameConstants_1.TileType.BROKEN_WALL) {
            c.fillStyle = isShadow ? '#4a1a6a' : '#2d6b3a';
            c.fillRect(screenX, screenY + GameConstants_1.TILE_SIZE - 3, GameConstants_1.TILE_SIZE, 3);
            c.fillStyle = isShadow ? '#6b2a9a' : '#3d8a4e';
            c.fillRect(screenX + 2, screenY + GameConstants_1.TILE_SIZE - 5, 2, 3);
            c.fillRect(screenX + 8, screenY + GameConstants_1.TILE_SIZE - 4, 1, 2);
            c.fillRect(screenX + 14, screenY + GameConstants_1.TILE_SIZE - 6, 2, 4);
            c.fillRect(screenX + 22, screenY + GameConstants_1.TILE_SIZE - 4, 1, 2);
            c.fillRect(screenX + 28, screenY + GameConstants_1.TILE_SIZE - 5, 2, 3);
        }
        const belowWall = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, (ty + 1) * GameConstants_1.TILE_SIZE);
        if (belowWall !== GameConstants_1.TileType.WALL && belowWall !== GameConstants_1.TileType.FLOOR) {
            const vineHash = ((tx * 41 + ty * 67) % 11);
            if (vineHash < 3) {
                const vineLen = 6 + (vineHash * 4);
                c.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
                c.fillRect(screenX + 4 + vineHash * 3, screenY + GameConstants_1.TILE_SIZE, 1, vineLen);
                c.fillRect(screenX + 5 + vineHash * 3, screenY + GameConstants_1.TILE_SIZE + vineLen - 2, 1, 3);
                c.fillStyle = isShadow ? '#5a2a8a' : '#2d6b3a';
                c.fillRect(screenX + 3 + vineHash * 3, screenY + GameConstants_1.TILE_SIZE + vineLen, 3, 2);
            }
            else if (vineHash < 5) {
                c.fillStyle = isShadow ? '#3a1a5a' : '#1a4a2a';
                c.fillRect(screenX + 8, screenY + GameConstants_1.TILE_SIZE, 1, 4);
                c.fillRect(screenX + 18, screenY + GameConstants_1.TILE_SIZE, 1, 6);
                c.fillRect(screenX + 26, screenY + GameConstants_1.TILE_SIZE, 1, 3);
            }
        }
    }
    renderStaticFloor(c, screenX, screenY, tx, ty, floorColor, floorVarColor, isShadow, chunks) {
        const variant = ((tx * 7 + ty * 13) % 5);
        c.fillStyle = variant === 0 ? floorColor : variant === 1 ? floorVarColor : variant === 2 ? '#14142a' : variant === 3 ? '#10101e' : floorColor;
        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
        const hash = ((tx * 23 + ty * 11) % 8);
        if (hash === 0) {
            c.fillStyle = '#1e1e38';
            c.fillRect(screenX + 4, screenY + 8, 4, 3);
            c.fillRect(screenX + 18, screenY + 20, 3, 2);
        }
        else if (hash === 1) {
            c.fillStyle = '#0e0e1a';
            c.fillRect(screenX + 12, screenY + 4, 2, 2);
            c.fillRect(screenX + 24, screenY + 16, 3, 2);
            c.fillRect(screenX + 6, screenY + 24, 2, 2);
        }
        else if (hash === 2) {
            c.fillStyle = '#1a1a30';
            c.fillRect(screenX + 8, screenY + 14, 5, 3);
        }
        else if (hash === 4) {
            c.fillStyle = '#0c0c18';
            c.fillRect(screenX + 20, screenY + 6, 2, 3);
            c.fillRect(screenX + 2, screenY + 22, 3, 2);
        }
        c.fillStyle = '#0a0a14';
        c.globalAlpha = 0.12;
        c.fillRect(screenX, screenY + GameConstants_1.TILE_SIZE - 1, GameConstants_1.TILE_SIZE, 1);
        c.fillRect(screenX + GameConstants_1.TILE_SIZE - 1, screenY, 1, GameConstants_1.TILE_SIZE);
        c.globalAlpha = 1.0;
        const aboveTile = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, (ty - 1) * GameConstants_1.TILE_SIZE);
        if (aboveTile === GameConstants_1.TileType.WALL) {
            c.fillStyle = isShadow ? '#1a0a2e' : '#1a1a28';
            c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, 3);
        }
        if (aboveTile !== GameConstants_1.TileType.WALL && aboveTile !== GameConstants_1.TileType.FLOOR) {
            const stHash = ((tx * 53 + ty * 97) % 13);
            if (stHash < 2) {
                c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
                c.fillRect(screenX + 12, screenY, 8, 2);
                c.fillRect(screenX + 14, screenY + 2, 4, 4);
                c.fillRect(screenX + 15, screenY + 6, 2, 4);
                c.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
                c.fillRect(screenX + 13, screenY, 2, 3);
            }
            else if (stHash < 5) {
                c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
                c.fillRect(screenX + 6 + stHash * 4, screenY, 3, 2);
                c.fillRect(screenX + 7 + stHash * 4, screenY + 2, 1, 3 + stHash);
            }
        }
        const belowFloor = this.getTile(chunks, tx * GameConstants_1.TILE_SIZE, (ty + 1) * GameConstants_1.TILE_SIZE);
        if (belowFloor !== GameConstants_1.TileType.FLOOR && belowFloor !== GameConstants_1.TileType.WALL) {
            const smHash = ((tx * 37 + ty * 79) % 17);
            if (smHash < 2) {
                c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
                c.fillRect(screenX + 10, screenY + GameConstants_1.TILE_SIZE - 2, 12, 2);
                c.fillRect(screenX + 12, screenY + GameConstants_1.TILE_SIZE - 6, 8, 4);
                c.fillRect(screenX + 14, screenY + GameConstants_1.TILE_SIZE - 9, 4, 3);
                c.fillStyle = isShadow ? '#3a2a5a' : '#3a3a50';
                c.fillRect(screenX + 15, screenY + GameConstants_1.TILE_SIZE - 8, 2, 2);
            }
            else if (smHash < 5) {
                c.fillStyle = isShadow ? '#2a1a4a' : '#2a2a3e';
                c.fillRect(screenX + 4 + smHash * 5, screenY + GameConstants_1.TILE_SIZE - 2, 3, 2);
                c.fillRect(screenX + 5 + smHash * 5, screenY + GameConstants_1.TILE_SIZE - 4 - smHash, 1, 2 + smHash);
            }
        }
    }
    renderStaticBrokenWall(c, screenX, screenY) {
        c.fillStyle = '#2a2a3e';
        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
        c.fillStyle = '#3a3a50';
        c.fillRect(screenX + 2, screenY + 2, 8, 6);
        c.fillRect(screenX + 16, screenY + 10, 10, 7);
        c.fillRect(screenX + 6, screenY + 20, 7, 8);
        c.fillStyle = '#4a4a60';
        c.fillRect(screenX + 4, screenY + 4, 4, 3);
        c.fillRect(screenX + 18, screenY + 12, 5, 3);
        c.fillStyle = '#1a1a2e';
        c.fillRect(screenX + 12, screenY + 2, 1, 8);
        c.fillRect(screenX + 14, screenY + 6, 1, 6);
        c.fillRect(screenX + 26, screenY + 18, 1, 10);
    }
    renderStaticPlant(c, screenX, screenY, floorColor) {
        c.fillStyle = floorColor;
        c.fillRect(screenX, screenY, GameConstants_1.TILE_SIZE, GameConstants_1.TILE_SIZE);
        c.fillStyle = GameConstants_1.COLOR_PLANT;
        c.fillRect(screenX + 14, screenY + 16, 4, 12);
        c.fillStyle = GameConstants_1.COLOR_PLANT_LIGHT;
        c.beginPath();
        c.arc(screenX + 16, screenY + 14, 6, 0, Math.PI * 2);
        c.fill();
        c.fillStyle = GameConstants_1.COLOR_PLANT;
        c.beginPath();
        c.arc(screenX + 12, screenY + 18, 4, 0, Math.PI * 2);
        c.fill();
    }
}
exports.TileRenderer = TileRenderer;
