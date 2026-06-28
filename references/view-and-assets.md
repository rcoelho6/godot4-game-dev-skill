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

---

## Mapa Estático vs TileMap

Escolha a abordagem de mapa antes de começar:

| Abordagem | Quando usar | Vantagem | Desvantagem |
|---|---|---|---|
| **TileMap** | Mapas gerados por tiles repetíveis | Colisão automática, fácil de editar | Requer tileset organizado |
| **Sprite2D estático** | Mapa desenhado como imagem única (PNG/WebP) | Visual rico, sem restrição de grade | Colisões precisam ser geradas por script |

### Usando Sprite2D como mapa estático

Quando o mapa é uma imagem única (ex: foto aérea de cidade, mapa desenhado):

```gdscript
# world.gd
extends Node2D

const MAP_IMAGE_WIDTH:  int = 3840   # largura real da imagem em px
const MAP_IMAGE_HEIGHT: int = 2160   # altura real da imagem em px
const RENDER_SCALE: float = 0.5      # renderizar em 50% do tamanho original

@onready var map_sprite: Sprite2D = %MapSprite

func _ready() -> void:
    # Centralizar o sprite: por padrão Sprite2D tem origem no centro
    map_sprite.position = Vector2(
        MAP_IMAGE_WIDTH  * RENDER_SCALE / 2.0,
        MAP_IMAGE_HEIGHT * RENDER_SCALE / 2.0
    )
    map_sprite.scale = Vector2(RENDER_SCALE, RENDER_SCALE)
```

> **Por que centralizar?** O `Sprite2D` tem sua origem no centro da imagem. Se a posição for `Vector2(0, 0)`, metade do mapa ficará fora da tela (em coordenadas negativas). Posicionando em `(w/2, h/2)`, o canto superior esquerdo do mapa fica exatamente na origem do mundo.

### Limites da câmera com mapa estático

```gdscript
func _ready() -> void:
    var rendered_w := MAP_IMAGE_WIDTH  * RENDER_SCALE
    var rendered_h := MAP_IMAGE_HEIGHT * RENDER_SCALE
    var cam: Camera2D = %Camera2D
    cam.limit_left   = 0
    cam.limit_top    = 0
    cam.limit_right  = int(rendered_w)
    cam.limit_bottom = int(rendered_h)
```

---

## Fórmula de Escala do Player em Relação ao Mapa

Quando o mapa é uma imagem real (ex: foto de cidade), a escala do personagem deve ser proporcional ao tamanho visual de uma rua ou calçada na imagem.

```
escala = (largura_rua_px * fator_ocupacao) / frame_width_do_sprite
```

- **`largura_rua_px`:** largura de uma rua no mapa renderizado (em pixels na tela), medida no editor Godot com a régua ou pelo inspetor.
- **`fator_ocupacao`:** quanto da largura da rua o personagem deve ocupar. Use `0.5` a `0.7` para personagens a pé; `0.8` a `1.0` para veículos.
- **`frame_width_do_sprite`:** largura de um frame do spritesheet do personagem em pixels.

**Exemplo real (projeto GameDeli):**
- Rua renderizada: ~130 px de largura
- Fator: 0.6 (personagem ocupa 60% da rua)
- Frame do sprite: 3276 px
- `escala = (130 * 0.6) / 3276 ≈ 0.024`

Aplique no script ou no inspetor:
```gdscript
$Visual.scale = Vector2(0.024, 0.024)
```

> Ajuste `fator_ocupacao` visualmente até o personagem parecer natural no contexto do mapa.

---

## Mapas HD com WebP

O Godot 4 suporta WebP nativamente. Para mapas grandes (acima de 2048×2048 px), WebP oferece compressão significativamente melhor que PNG sem perda visual perceptível.

### Configuração de importação para mapas HD

No painel **Import** do Godot ao selecionar o arquivo do mapa:

| Propriedade | Valor para mapa HD |
|---|---|
| Compress > Mode | `Lossless` (WebP sem perda) ou `Lossy` (aceita leve perda) |
| Filter | `Linear` |
| Mipmaps | **Ativado** |
| Repeat | `Disabled` |

> **Por que Mipmaps?** Quando a câmera está afastada (zoom out), o Godot usa versões menores pré-calculadas da textura (mipmaps), evitando aliasing e melhorando a performance de renderização.

### Usando `scale` para renderizar em resolução menor

Um mapa de 3840×2160 px pode ser renderizado em 1920×1080 px usando `scale = Vector2(0.5, 0.5)` no `Sprite2D`. Isso mantém o arquivo original em alta resolução (para zoom futuro ou telas maiores) sem sobrecarregar a GPU com a textura completa em cada frame.

---

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

### Arte HD (tile base 32×32 ou mapa real)

| Elemento | Tamanho | Zoom sugerido |
|---|---|---|
| Tile de mapa | 32×32 px | 1× ou 1.5× |
| Personagem | 32×32 ou 48×48 px | 1× |
| Veículo pequeno | 48×48 px | 1× |
| Veículo grande | 64×96 px | 1× |
| Objeto/item | 32×32 px | 1× |
| UI / ícone | 32×32 px mínimo | 1× |

---

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

### Veículo top-down (rotação por frames)

```
Linha 0: 8 ou 16 frames de rotação (0° a 360°)
```

Ou use um único sprite e rotacione via `rotation` no script.

---

## Importação de Assets

| Tipo de asset | Filter | Mipmaps | Formato |
|---|---|---|---|
| Pixel art (sprites, tiles) | `Nearest` | Desativado | PNG |
| Arte HD (sprites, tiles) | `Linear` | Ativado | PNG ou WebP |
| Mapa estático grande | `Linear` | **Ativado** | **WebP recomendado** |

---

## Organização de Pastas de Assets

```
/assets/
  /sprites/
    /characters/   → player.png, enemy_01.png
    /vehicles/     → car_01.png, truck_01.png
    /objects/      → barrel.png, crate.png, coin.png
    /ui/           → heart.png, button_bg.png
  /maps/           → city_map.webp, level_01.webp
  /tilesets/
    /world/        → tileset_city.png, tileset_grass.png
  /audio/
    /sfx/          → footstep.wav, explosion.wav
    /music/        → theme_01.ogg
  /fonts/
    → main_font.ttf
```

---

## Configuração do TileSet

1. Crie um recurso `TileSet` (`.tres`)
2. Adicione a textura do tileset
3. Defina o tamanho do tile (ex: 32×32)
4. Configure as **Physics Layers** do tileset para colisão de parede/chão
5. Pinte as formas de colisão nos tiles que devem bloquear passagem

Ver `references/map-assembly.md` para uso no TileMapLayer.
Ver `references/collision-procedural.md` para colisões em mapas estáticos.
