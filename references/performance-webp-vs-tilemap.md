# Comparativo de Desempenho: Mapas Estáticos WebP vs TileMapLayer no Godot 4

Ao projetar um jogo 2D top-down no Godot 4, a escolha entre usar um `TileMapLayer` clássico ou uma imagem estática única (Sprite2D com textura WebP) tem impactos profundos na arquitetura, no fluxo de trabalho e no desempenho do jogo [1] [2]. Este documento detalha as diferenças técnicas entre as duas abordagens, cobrindo uso de memória (VRAM), chamadas de desenho (draw calls), processamento de física e cenários de uso ideais.

## 1. Uso de Memória de Vídeo (VRAM) e Compressão

A diferença mais significativa entre as duas abordagens reside na forma como a memória de vídeo (VRAM) é alocada e gerenciada pela GPU.

### TileMapLayer
Em um TileMap, o Godot carrega apenas a textura do *tileset* (ex: uma imagem de 512×512 pixels) para a VRAM. Independentemente do tamanho do mapa — seja ele 100×100 ou 10.000×10.000 tiles — o consumo de VRAM permanece o mesmo, correspondendo apenas ao tamanho do tileset [3]. Isso torna o TileMap extremamente eficiente em memória, sendo ideal para jogos de mundo aberto gigantescos ou dispositivos com pouca memória de vídeo.

### Sprite2D com WebP
Quando se utiliza uma imagem estática como mapa (ex: uma ilustração rica de 3840×2160 pixels), a imagem inteira precisa ser carregada na VRAM. É importante notar que, embora formatos como PNG e WebP reduzam o tamanho do arquivo no disco (armazenamento), as GPUs não conseguem ler esses formatos comprimidos diretamente [4]. Para que a GPU possa desenhar a textura na tela, o Godot precisa descompactar a imagem em VRAM, transformando-a em dados brutos de pixels (RGBA).

Um mapa de 3840×2160 pixels em RGBA de 32 bits consumirá aproximadamente 33 MB de VRAM (3840 × 2160 × 4 bytes). Embora isso seja perfeitamente aceitável para GPUs modernas de PC e até mesmo celulares intermediários, criar mapas de 16384×16384 pixels consumiria mais de 1 GB de VRAM apenas para o fundo [2]. O limite absoluto de textura suportado pelo Godot 4 e pela maioria das GPUs modernas é de 16384×16384 pixels, mas na prática, é recomendável manter texturas únicas abaixo de 8192×8192 para garantir compatibilidade ampla [2].

## 2. Draw Calls e Batching (Desempenho de Renderização)

*Draw calls* são comandos enviados pela CPU para a GPU instruindo-a a desenhar algo na tela. Reduzir draw calls é uma das otimizações mais críticas no desenvolvimento de jogos.

### TileMapLayer
No Godot 4, o `TileMapLayer` não desenha cada tile individualmente (o que causaria milhares de draw calls). Em vez disso, ele agrupa os tiles em "quadrantes" (Rendering Quadrants), cujo tamanho padrão é 16×16 tiles [1]. O Godot processa cada quadrante em *batching*, enviando múltiplos tiles para a GPU em uma única draw call. No entanto, se o mapa for excessivamente grande e o campo de visão da câmera cobrir dezenas de quadrantes simultaneamente, o número de draw calls aumentará proporcionalmente, o que pode causar gargalos na CPU [1] [5].

### Sprite2D com WebP
A renderização de um mapa estático é trivial para a engine. Como o mapa é um único nó `Sprite2D`, ele requer exatamente **uma draw call** para ser desenhado, independentemente da complexidade visual ou da quantidade de detalhes contidos na imagem. Do ponto de vista estrito de processamento de renderização, o mapa estático é mais rápido, pois elimina o overhead de cálculo de quadrantes e batching da CPU.

## 3. Desempenho de Física e Colisão

O processamento de colisões é onde a abordagem procedimental diverge drasticamente do sistema nativo.

### TileMapLayer
O TileMap integra-se profundamente ao motor de física (Box2D no Godot 4). Quando configurado, ele gera formas de colisão otimizadas fundindo tiles adjacentes em formas contínuas. A colisão é computada apenas para as áreas relevantes, e o editor oferece feedback visual imediato. É a abordagem mais robusta e testada.

### Sprite2D com Colisões Procedurais
Como a imagem estática não possui dados físicos intrínsecos, as colisões devem ser geradas via script (instanciando `StaticBody2D` com base em uma grade lógica, como abordado na skill).
Se um mapa de cidade tiver 1.000 prédios e o script instanciar 1.000 nós `StaticBody2D` separados no `_ready()`, isso aumentará o tempo de carregamento da cena e a quantidade de nós na memória RAM. O Godot lida bem com milhares de nós estáticos devido ao *broadphase* do motor de física, mas a sobrecarga de memória RAM (não VRAM) será maior do que a de um TileMap otimizado.

## 4. Otimização Visual: Mipmaps e Scale

Quando se usa mapas estáticos grandes, é comum que a câmera faça *zoom out* ou que a imagem seja renderizada em uma resolução menor que a original (ex: usar `scale = Vector2(0.5, 0.5)`).

Se uma textura grande for reduzida sem **Mipmaps**, a GPU tentará amostrar pixels de uma imagem gigante para caber em poucos pixels na tela, causando um efeito visual de cintilação e serrilhado conhecido como *aliasing*.
Ativar a geração de Mipmaps na importação do Godot faz com que o motor pré-calcule versões progressivamente menores da textura. Isso aumenta o consumo de VRAM em cerca de 33%, mas melhora drasticamente a qualidade visual e o desempenho de amostragem da GPU quando o mapa está com zoom out.

## 5. Resumo e Casos de Uso

A escolha entre as duas abordagens deve ser guiada pela direção de arte e pelo escopo do projeto:

| Característica | TileMapLayer | Sprite2D (WebP) + Colisão Procedural |
| :--- | :--- | :--- |
| **Tamanho máximo do mundo** | Praticamente infinito | Limitado pela VRAM (idealmente < 8192×8192 px) |
| **Uso de VRAM** | Muito baixo (apenas o tileset) | Alto (escala com a resolução da imagem) |
| **Draw Calls** | Baixo a médio (por quadrantes) | Mínimo (1 draw call) |
| **Colisões** | Automáticas e otimizadas | Requer script, maior uso de RAM para nós |
| **Fluxo de Trabalho** | Requer criação de tiles repetíveis | Permite pintura digital livre, ilustrações ricas |
| **Melhor Caso de Uso** | Metroidvanias, RPGs clássicos, mundos gerados proceduralmente | Mapas pré-renderizados, cenários ilustrados à mão, cidades densas não-repetitivas (ex: GameDeli) |

## References

[1] Godot Engine. "TileMapLayer — Godot Engine (stable) documentation in English". https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html
[2] Godot Forum. "Any guidelines on how much memory I should use for textures?". https://forum.godotengine.org/t/any-guidelines-on-how-much-memory-i-should-use-for-textures/111749
[3] Reddit. "TileMap Performance : r/godot". https://www.reddit.com/r/godot/comments/189pxa2/tilemap_performance/
[4] Godot Forum. "Why is a 50kb .png spritesheet using over 18 MiB of video RAM?". https://forum.godotengine.org/t/why-is-a-50kb-png-spritesheet-using-over-18-mib-of-video-ram/6887
[5] GitHub. "Godot 4 tilemap - the bigger the map the lower the fps #72458". https://github.com/godotengine/godot/issues/72458
