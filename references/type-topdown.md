# Tipo de Jogo: Top-Down (Câmera Cenital)

## Configurações obrigatórias no Project Settings

- `Physics > 2D > Default Gravity` = **0** (sem gravidade)
- `Display > Window > Size` = **1280×720**
- `Display > Window > Stretch > Mode` = **canvas_items**
- `Display > Window > Stretch > Aspect` = **keep**
- `Display > Window > Handheld > Orientation` = **landscape** (para mobile)

## Câmera

Adicione `Camera2D` como filho direto do player. Configurações no inspetor:

| Propriedade | Valor |
|---|---|
| Position Smoothing > Enabled | `true` |
| Position Smoothing > Speed | `5.0` |
| Limit > Left / Top / Right / Bottom | limites do mapa em pixels |
| Zoom | `Vector2(2, 2)` para pixel art pequena |

O zoom depende do tamanho dos tiles. Para tiles de 16×16 px, zoom `2×` ou `3×` é comum.

## Orientação do Mapa

No top-down, o eixo Y representa profundidade visual. Para objetos se sobreporem corretamente:

- Ative **Y Sort** no nó raiz do mapa (`Node2D > Y Sort Enabled = true`)
- Todos os objetos no mesmo nível de Y Sort devem ter o `position.y` como base de ordenação
- A origem do sprite deve estar na **base do objeto** (não no centro)

## Movimento 8 Direções

O personagem se move livremente em X e Y. Ver `references/physics.md` para o script completo.

## Assets recomendados para Top-Down

| Elemento | Tamanho | Observação |
|---|---|---|
| Tile chão/parede | 16×16 ou 32×32 px | Repetível, sem borda visível |
| Personagem | 32×32 ou 48×48 px | Spritesheet com animações por direção |
| Veículo | 48×64 ou 64×96 px | Spritesheet com rotação ou direções |
| Sombra | Mesmo tamanho do objeto | Sprite separado, renderizado abaixo |
| Objeto/item | 16×16 ou 32×32 px | Ícone simples |
