# Arquitetura Técnica da Skill godot4-game-dev

Este documento explica tecnicamente como cada funcionalidade da skill foi desenhada e o raciocínio por trás das escolhas arquiteturais para projetos no Godot 4.

## 1. Arquitetura Desacoplada e Orientada a Eventos

A principal diretriz técnica da skill é o **desacoplamento total entre entidades**. Em um jogo, é comum que o jogador, os inimigos, a interface de usuário (UI) e o mundo precisem interagir. No entanto, referências diretas (ex: `get_parent().get_node("UI/HealthBar")`) criam código frágil que quebra se a árvore de cenas mudar.

**Como funciona na skill:**
- **Signals (Eventos):** O jogador emite um sinal `health_changed` quando sofre dano. Ele não sabe quem está ouvindo. A UI se conecta a esse sinal e atualiza a barra de vida. Isso permite que a UI seja removida ou alterada sem quebrar o código do jogador.
- **Grupos:** Para interações espaciais (como um inimigo procurando o jogador), usamos `get_tree().get_nodes_in_group("player")`. Isso permite encontrar a referência dinamicamente em tempo de execução, independentemente de onde o jogador foi instanciado na árvore.

## 2. Sistema de Física e Movimento

O Godot 4 possui três nós principais para física 2D. A skill prescreve o uso específico de cada um para evitar comportamentos imprevisíveis:

- **CharacterBody2D (Player, Inimigos, Veículos):** É um corpo cinemático. Ele só se move via código (usando `move_and_slide()`). Isso dá controle total sobre a aceleração, frenagem e esterçamento. No caso de veículos, a física é simulada manualmente (calculando vetor de direção baseado em rotação e aplicando atrito) em vez de depender da simulação de veículos nativa do motor, garantindo uma sensação arcade mais responsiva.
- **RigidBody2D (Objetos soltos):** Controlado inteiramente pelo motor de física do Godot (Box2D). A skill usa a função `apply_central_impulse()` a partir do `CharacterBody2D` para transferir força de forma realista quando o jogador empurra um barril, por exemplo.
- **Area2D (Triggers e Pickups):** Não possui colisão física (não bloqueia movimento). Usado apenas para computar interseções espaciais via sinais `body_entered` e `body_exited`.

## 3. Gerenciamento de Colisões e Superfícies Tipadas

A skill implementa um sistema de colisão baseado em **Bitmasks** (máscaras de bits). 

- **Layers (Camadas):** Representam a "identidade" do objeto (ex: `player`, `building`, `water`).
- **Masks (Máscaras):** Representam "com quem" o objeto interage.

**Otimização de Broadphase:**
Se um projétil do jogador colidir com tudo, ele vai explodir ao bater em um item coletável. Ao configurar a *Mask* do projétil para interagir apenas com `world` e `enemy`, o motor de física do Godot ignora colisões com `pickup` na fase de *broadphase* (antes mesmo de calcular a geometria exata). Isso é extremamente performático.

**Dano por Metadata vs Herança:**
Em vez de criar classes distintas como `class Building extends StaticBody2D` e `class Water extends StaticBody2D`, a skill prefere a composição de dados via **Metadata** (`set_meta("collision_type", "building")`). Isso permite que colisões sejam geradas proceduralmente de forma rápida e genérica, enquanto o script do jogador resolve a consequência do impacto usando um simples `match` na string do metadata.

## 3.5. Colisões Procedurais em Mapas Estáticos

Quando um jogo opta por usar uma imagem estática gigante (WebP) como mapa em vez de um TileMap (como no projeto GameDeli), perde-se a geração automática de colisões. 

A skill resolve isso de forma performática através de um script de pré-processamento. Uma grade lógica (matriz de inteiros) é lida no `_ready()` do mundo, e nós `StaticBody2D` são instanciados apenas nas células que requerem colisão. Isso mantém a árvore de cenas leve no editor e delega a construção física para o tempo de execução.

## 4. Pathfinding com NavigationAgent2D

Para a movimentação inteligente de inimigos, a skill utiliza o sistema de navegação nativo do Godot 4 (`NavigationServer2D`).

1. O mapa possui uma `NavigationRegion2D` com um polígono "baked" (pré-calculado) que define as áreas caminháveis.
2. O inimigo possui um `NavigationAgent2D`.
3. O script do inimigo passa a posição do jogador para o agente (`nav_agent.target_position = _target.global_position`).
4. O agente calcula o caminho mais curto desviando de obstáculos e retorna o próximo ponto (`get_next_path_position()`).
5. O inimigo calcula a direção até esse próximo ponto e se move.

Isso separa a lógica de busca de caminho (feita de forma assíncrona e otimizada pelo motor em C++) da lógica de movimento (feita em GDScript).

## 5. Renderização e Y-Sort (Profundidade em 2D)

Em jogos Top-Down, não há um eixo Z real para profundidade. Para criar a ilusão de que um personagem está "atrás" ou "na frente" de uma árvore, a skill utiliza o recurso **Y-Sort**.

Quando ativado no nó pai (ex: `World`), o motor renderiza os nós filhos com base no valor de sua posição Y na tela. Objetos com Y menor (mais ao topo da tela) são desenhados primeiro. Objetos com Y maior (mais abaixo) são desenhados depois, sobrepondo os primeiros. Para que isso funcione corretamente, a origem do sprite (o ponto 0,0) deve estar sempre na base (pés) do personagem, e não no centro.

## 6. Viewport e Escala Multiplataforma

A configuração de `Stretch Mode = canvas_items` e `Aspect = keep` garante que a proporção do jogo seja mantida independentemente do dispositivo (monitor ultrawide, celular em pé, tablet deitado). 

A skill recomenda a resolução base de `1280x720` (720p). Se o jogo for aberto em uma tela 1080p, o Godot não aumentará o campo de visão (o que daria vantagem a jogadores com monitores maiores); em vez disso, ele escalará os pixels para preencher a tela, adicionando barras pretas caso a proporção não seja exatamente 16:9.

**Mapas HD e WebP:**
Para jogos que usam imagens estáticas como mapa, a skill prescreve o formato **WebP** com compressão *Lossless* ou *Lossy* e a ativação de **Mipmaps**. O uso da propriedade `scale` no `Sprite2D` permite renderizar um mapa gigante em uma resolução menor de visualização, garantindo que o zoom out funcione sem serrilhados (aliasing) e reduzindo a carga de amostragem de textura na GPU.

## 7. Controles Mobile e Joystick Virtual

A implementação de mobile input na skill não altera o código de movimento do jogador. Ela utiliza um padrão de injeção de dependência via sinais.

O jogador possui um método `_get_input_direction()`. Por padrão, ele lê o teclado/gamepad via `Input.get_vector()`. Se a tela for de toque, um joystick virtual desenhado na UI (CanvasLayer) calcula o vetor de arraste do dedo do usuário e emite esse vetor via signal. O jogador recebe esse vetor e o armazena em `_touch_direction`, utilizando-o como fallback. Isso permite exportar o mesmo código para PC e Android sem nenhuma instrução `#ifdef` ou verificações de sistema operacional dentro do loop de física.
