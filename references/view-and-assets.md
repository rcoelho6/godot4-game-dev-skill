# View e Assets — Godot 4

## Resolução e Viewport

A resolução base define o "canvas" interno do jogo. O Godot escala automaticamente para qualquer tela.

| Configuração | Valor recomendado |
|---|---|
| Viewport Width | 1280 |
| Viewport Height | 720 |
| Stretch Mode | `canvas_items` |
| Stretch Aspect | `keep` |

`canvas_items` escala cada elemento individualmente, mantendo pixel art nítida. `keep` preserva a proporção 16:9 com barras pretas nas bordas se necessário.

## Tamanho de Sprites

Escolha **um tamanho de tile base** e mantenha tudo múltiplo dele.

### Pixel art (tile base 16×16)

| Elemento | Tamanho | Zoom sugerido |
|---|---|---|
| Tile de mapa | 16×16 px | 2× ou 3× |
| Personagem | 16×16 ou 32×32 px | 2× ou 3× |
| Veículo pequeno | 32×32 px | 2× |
| Veículo grande | 32×48 px | 2× |
| Objeto/item | 16×16 px | 2× |
| UI / ícone | 16×16 px | 2× |

### Arte HD (tile base 32×32)

| Elemento | Tamanho | Zoom sugerido |
|---|---|---|
| Tile de mapa | 32×32 px | 1× ou 1.5× |
| Personagem | 32×32 ou 48×48 px | 1× |
| Veículo pequeno | 48×48 px | 1× |
| Veículo grande | 64×96 px | 1× |
| Objeto/item | 32×32 px | 1× |
| UI / ícone | 32×32 px mínimo | 1× |

## Spritesheets

Organize animações em spritesheets horizontais. Cada linha = uma animação.

### Personagem top-down (exemplo 32×32, 4 direções)

```
Linha 0: idle_down   (4 frames)
Linha 1: idle_up     (4 frames)
Linha 2: idle_side   (4 frames) ← espelhar para esquerda/direita
Linha 3: walk_down   (4 frames)
Linha 4: walk_up     (4 frames)
Linha 5: walk_side   (4 frames)
```

No Godot, use `AnimatedSprite2D` com `SpriteFrames` ou `Sprite2D` + `AnimationPlayer`.

### Veículo top-down (exemplo 48×48, rotação por frames)

```
Linha 0: 8 ou 16 frames de rotação (0° a 360°)
```

Ou use um único sprite e rotacione via `rotation` no script.

## Importação de Assets

Ao importar PNGs no Godot:
- **Pixel art:** no painel Import, defina `Filter` = `Nearest` e desative `Mipmaps`
- **Arte HD:** `Filter` = `Linear`, `Mipmaps` = ativado

## Organização de Pastas de Assets

```
/assets/
  /sprites/
    /characters/   → player.png, enemy_01.png
    /vehicles/     → car_01.png, truck_01.png
    /objects/      → barrel.png, crate.png, coin.png
    /ui/           → heart.png, button_bg.png
  /tilesets/
    /world/        → tileset_city.png, tileset_grass.png
  /audio/
    /sfx/          → footstep.wav, explosion.wav
    /music/        → theme_01.ogg
  /fonts/
    → main_font.ttf
```

## Configuração do TileSet

1. Crie um recurso `TileSet` (`.tres`)
2. Adicione a textura do tileset
3. Defina o tamanho do tile (ex: 32×32)
4. Configure as **Physics Layers** do tileset para colisão de parede/chão
5. Pinte as formas de colisão nos tiles que devem bloquear passagem

Ver `references/map-assembly.md` para uso no TileMapLayer.
