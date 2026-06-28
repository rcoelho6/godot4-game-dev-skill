# Tutorial Completo: Criando um Jogo Top-Down com a Skill godot4-game-dev

Este tutorial abrangente ensina como utilizar a skill `godot4-game-dev` para construir um jogo 2D top-down no Godot Engine 4. Ele cobre desde a configuração do projeto e assets até a implementação de física desacoplada para jogadores, veículos e inimigos, além do sistema de colisão e montagem de mapas.

## 1. Configuração do Projeto e Viewport

O primeiro passo é preparar o Godot para lidar corretamente com a escala e a renderização multiplataforma.

1. **Criação:** Crie um novo projeto no Godot 4 e selecione o **Renderer Mobile**. Ele oferece o melhor desempenho para Android e iOS, além de rodar perfeitamente no PC.
2. **Gravidade Zero:** Acesse **Project > Project Settings > Physics > 2D > Default Gravity** e defina como `0`. Jogos top-down não possuem gravidade vertical nativa.
3. **Resolução e Escala:** Em **Display > Window**, defina o tamanho base para `1280x720`. Altere o **Stretch Mode** para `canvas_items` e o **Aspect** para `keep`. Isso garante que o jogo preencha telas de celulares ou monitores ultrawide sem distorcer a arte.

## 2. Preparando o Mapa e Assets

A skill suporta duas abordagens para montagem de mapa: **TileMap** ou **Mapa Estático (Imagem Única)**.

### Usando um Mapa Estático HD (WebP)
Para jogos como o GameDeli, onde o mapa é uma imagem rica desenhada à mão:
- Use o formato **WebP** para mapas grandes (ex: 3840x2160 px) devido à sua excelente compressão.
- Na importação, ative **Mipmaps** e defina o **Filter** como `Linear`.
- Na cena do mundo, use um `Sprite2D`. Como a origem do Sprite2D é no centro, posicione-o em `Vector2(w/2, h/2)` para que o canto superior esquerdo alinhe com a origem do mundo.
- Use a propriedade `scale` para renderizar o mapa em uma resolução menor (ex: `scale = Vector2(0.5, 0.5)`).

### Calculando a Escala do Jogador
Para que o personagem pareça natural em um mapa real, use a fórmula:
```
escala = (largura_rua_px * fator_ocupacao) / frame_width_do_sprite
```
Por exemplo, se a rua renderizada tem 130px de largura, o personagem deve ocupar 60% dela (`fator_ocupacao = 0.6`), e o frame do sprite tem 3276px:
`escala = (130 * 0.6) / 3276 = 0.024`.

## 3. Sistema de Colisão por Tipos de Superfície

Em vez de uma colisão genérica de "mundo", jogos complexos precisam distinguir superfícies (prédios, água, calçada).

1. Acesse **Project Settings > Layer Names > 2D Physics**.
2. Nomeie as camadas por tipo de superfície:
   - Layer 1: `sidewalk` (chão livre)
   - Layer 2: `player` (corpo do jogador)
   - Layer 3: `building` (bloqueia e causa dano leve)
   - Layer 4: `park` (livre, efeito visual)
   - Layer 5: `water` (bloqueia e causa game over)
   - Layer 6: `pickup` (itens)
   - Layer 7: `trigger` (zonas de evento)

A `collision_mask` do jogador deve ser configurada para detectar apenas o que o afeta: `LAYER_BUILDING | LAYER_WATER | LAYER_PICKUP | LAYER_TRIGGER`. Ele não precisa detectar a calçada ou o parque.

## 4. Colisões Procedurais e Dano por Metadata

Quando o mapa é uma imagem estática, não temos o TileMap para gerar colisões automáticas. A skill resolve isso via **Geração Procedural**.

1. Crie uma matriz (Array) em GDScript que representa a grade lógica do mapa (ex: 0=livre, 1=prédio, 3=água).
2. No `_ready()` do mundo, o script lê essa matriz e instancia nós `StaticBody2D` invisíveis sobre a imagem do mapa.
3. Cada `StaticBody2D` recebe um **Metadata** identificando seu tipo: `body.set_meta("collision_type", "building")`.

No script do jogador, após o `move_and_slide()`, lemos o metadata do objeto colidido para aplicar o efeito correto:

```gdscript
for i in get_slide_collision_count():
    var col := get_slide_collision(i)
    var collider := col.get_collider()
    if collider.has_meta("collision_type"):
        match collider.get_meta("collision_type"):
            "building": take_damage(5)
            "water": GameManager.trigger_game_over()
```

## 5. Implementando Física Desacoplada

A arquitetura da skill dita que cada entidade se move de forma independente, usando `CharacterBody2D`, sem referências diretas a outros nós.

- **O Jogador:** Lê o input do teclado ou de um joystick virtual (mobile) e se move em 8 direções. Ele não acessa a UI diretamente; ele emite o sinal `health_changed` e a UI se atualiza.
- **O Veículo:** Simula a direção de um carro arcade. Ele lê o input vertical para aceleração/frenagem e o horizontal para esterçamento (que só ocorre se o veículo estiver em movimento).
- **O Inimigo (Pathfinding):** Usa o `NavigationAgent2D`. Ele encontra o jogador dinamicamente usando `get_tree().get_nodes_in_group("player")` e calcula a rota desviando de paredes.

## 6. Exportação Multiplataforma

A skill foi desenhada para garantir que o mesmo código rode no PC e em celulares.

- O uso do GDScript (evitando C#) garante que a exportação para Android e iOS funcione sem as limitações experimentais atuais do Godot 4.
- A injeção de dependência do joystick virtual (onde a UI mobile emite sinais de direção que o script do jogador aceita como fallback do teclado) elimina a necessidade de alterar o código principal.
- Siga o guia de exportação (`export-guide.md`) da skill para gerar os arquivos `.apk` (Android) ou o projeto do Xcode (iOS).

Com esta arquitetura orientada a eventos, colisões procedurais tipadas por metadata e física desacoplada, seu projeto Godot 4 está pronto para escalar de forma limpa e profissional.
