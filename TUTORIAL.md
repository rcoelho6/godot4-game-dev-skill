# Tutorial Completo: Criando um Jogo Top-Down com a Skill godot4-game-dev

Este tutorial abrangente ensina como utilizar a skill `godot4-game-dev` para construir um jogo 2D top-down no Godot Engine 4. Ele cobre desde a configuração do projeto e assets até a implementação de física desacoplada para jogadores, veículos e inimigos, além do sistema de colisão e montagem de mapas.

## 1. Configuração do Projeto e Viewport

O primeiro passo é preparar o Godot para lidar corretamente com a escala e a renderização multiplataforma.

1. **Criação:** Crie um novo projeto no Godot 4 e selecione o **Renderer Mobile**. Ele oferece o melhor desempenho para Android e iOS, além de rodar perfeitamente no PC.
2. **Gravidade Zero:** Acesse **Project > Project Settings > Physics > 2D > Default Gravity** e defina como `0`. Jogos top-down não possuem gravidade vertical nativa.
3. **Resolução e Escala:** Em **Display > Window**, defina o tamanho base para `1280x720`. Altere o **Stretch Mode** para `canvas_items` e o **Aspect** para `keep`. Isso garante que o jogo preencha telas de celulares ou monitores ultrawide sem distorcer a pixel art.
4. **Estrutura de Pastas:** Organize seu projeto exatamente assim:
   - `/assets/` (sprites, áudio, fontes)
   - `/scenes/` (dividido em `/world`, `/player`, `/enemies`, `/vehicles`, `/objects`)
   - `/scripts/` e `/autoloads/`

## 2. Preparando Assets e Sprites

Para um jogo top-down, a orientação visual e a consistência de tamanho são fundamentais.

- **Tamanhos Base:** Escolha um padrão. Para pixel art clássica, use tiles de mapa de `16x16 px` e personagens de `16x16` ou `32x32 px`. Configure o zoom da câmera do jogador (ex: `Vector2(2, 2)`) para aproximar a visão.
- **Importação:** Ao importar pixel art, vá na aba **Import** do Godot, defina **Filter** como `Nearest` e desative **Mipmaps** para evitar que os gráficos fiquem embaçados.
- **Origem do Sprite:** Para que a ilusão de profundidade (Y-Sort) funcione, a origem (ponto 0,0) do sprite do personagem, árvore ou veículo deve estar **na base (nos pés)** do objeto, e não no centro.

## 3. Sistema de Colisão por Bitmasks

A skill utiliza um sistema de colisão altamente otimizado usando *Layers* e *Masks*.

1. Acesse **Project Settings > Layer Names > 2D Physics**.
2. Nomeie as camadas conforme o padrão da skill:
   - Layer 1: `world` (paredes, chão)
   - Layer 2: `player` (corpo do jogador)
   - Layer 3: `enemy` (inimigos)
   - Layer 4: `vehicle` (veículos)
   - Layer 5: `projectile` (tiros)
   - Layer 6: `pickup` (itens)
   - Layer 7: `trigger` (zonas de evento)

Ao criar um objeto, você define o que ele **é** (Layer) e com o que ele **colide** (Mask). Por exemplo, o projétil do jogador é da Layer 5, mas sua Mask está marcada apenas para as Layers 1 (world) e 3 (enemy). Isso impede que o tiro bata em itens coletáveis, economizando processamento de física.

## 4. Implementando Física Desacoplada

A arquitetura da skill dita que cada entidade se move de forma independente, usando `CharacterBody2D`, sem referências diretas a outros nós.

### O Jogador (Player)
O jogador utiliza o template `player_topdown.gd`. Ele se move em 8 direções lendo o input do teclado ou de um joystick virtual na tela de toque.

- O script define `collision_layer = LAYER_PLAYER` e `collision_mask = LAYER_WORLD | LAYER_ENEMY | LAYER_VEHICLE | LAYER_TRIGGER` via código.
- Após o `move_and_slide()`, ele verifica colisões. Se bater em um inimigo, recebe dano. Se bater em um objeto solto (`RigidBody2D`), aplica um impulso para empurrá-lo de forma realista.

### O Veículo
O template `vehicle_topdown.gd` simula a direção de um carro arcade usando `CharacterBody2D` (não `VehicleBody2D`).

- Ele lê o input vertical para aceleração/frenagem e o input horizontal para esterçamento.
- O esterçamento (`rotation += steer * steer_speed * delta * sign(_speed)`) só ocorre se o veículo estiver em movimento.
- A velocidade é calculada movendo o vetor `Vector2.UP` rotacionado pela rotação atual do carro.

### O Inimigo (Pathfinding)
Inimigos inteligentes usam o template `enemy_topdown.gd` integrado ao `NavigationAgent2D`.

- O inimigo não busca o jogador por um caminho de cena (como `$"../Player"`). Ele usa `get_tree().get_nodes_in_group("player")` para encontrar o alvo dinamicamente.
- Ele calcula a distância. Se o jogador estiver longe, ele fica parado. Se estiver no alcance de perseguição, ele passa a posição do jogador para o `NavigationAgent2D`, que calcula a rota desviando de paredes e retorna o próximo passo (`get_next_path_position()`).

## 5. Montagem do Mapa (World)

O mapa é a cena que une todos os elementos.

1. **Y-Sort:** O nó raiz do mundo deve ser um `Node2D` com a propriedade **Y Sort Enabled** ativada. Isso faz com que objetos mais abaixo na tela sejam desenhados por cima dos objetos mais acima, criando a ilusão de 3D.
2. **TileMapLayers:** Use múltiplos nós `TileMapLayer`. Um para o chão (sem colisão), um para as paredes (com colisão configurada na Physics Layer do TileSet) e um para detalhes por cima de tudo.
3. **Organização:** Crie nós `Node2D` vazios chamados `Objects` e `Enemies` para organizar as instâncias.
4. **Navegação:** Adicione um `NavigationRegion2D`, desenhe a área caminhável e clique em **Bake NavigationPolygon**. É isso que os inimigos usarão para o pathfinding.
5. **Limites:** O script do mapa define os limites da câmera do jogador (`camera.limit_right`, `camera.limit_bottom`) para impedir que a visão saia para fora do mapa.

## 6. Exportação Multiplataforma

A skill foi desenhada para garantir que o mesmo código rode no PC e em celulares.

- O uso do GDScript (evitando C#) garante que a exportação para Android e iOS funcione sem as limitações experimentais atuais do Godot 4.
- A injeção de dependência do joystick virtual (onde a UI mobile emite sinais de direção que o script do jogador aceita como fallback do teclado) elimina a necessidade de alterar o código principal.
- Siga o guia de exportação (`export-guide.md`) da skill para gerar os arquivos `.apk` (Android) ou o projeto do Xcode (iOS).

Com esta arquitetura orientada a eventos, colisões baseadas em máscaras de bits e física desacoplada, seu projeto Godot 4 está pronto para escalar de forma limpa e profissional.
