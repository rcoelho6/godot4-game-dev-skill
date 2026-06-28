# Input Mobile no Godot 4

## Joystick Virtual com TouchScreenButton

A abordagem mais simples é usar o nó `TouchScreenButton` para botões e um joystick virtual customizado.

### Opção 1: Input Actions unificado (recomendado)

Configure as mesmas `InputActions` para teclado e touch. O código do player não muda.

No `project.godot`, adicione ações como `move_left`, `move_right`, `move_up`, `move_down`.

Use `TouchScreenButton` na UI para emitir essas ações via `action` property.

### Opção 2: Joystick Virtual com script

```gdscript
# virtual_joystick.gd — filho de um Control na CanvasLayer
extends Control

signal direction_changed(direction: Vector2)

var touch_index: int = -1
var joystick_center: Vector2
var max_radius: float = 60.0

@onready var knob: Control = $Knob

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and touch_index == -1:
            if get_global_rect().has_point(event.position):
                touch_index = event.index
                joystick_center = event.position
        elif not event.pressed and event.index == touch_index:
            touch_index = -1
            knob.position = Vector2.ZERO
            direction_changed.emit(Vector2.ZERO)

    elif event is InputEventScreenDrag and event.index == touch_index:
        var offset := event.position - joystick_center
        var clamped := offset.limit_length(max_radius)
        knob.position = clamped
        direction_changed.emit(clamped / max_radius)
```

No player, conecte o sinal:
```gdscript
func _on_virtual_joystick_direction_changed(dir: Vector2) -> void:
    _touch_direction = dir
```

### Opção 3: Plugin da Asset Library

Buscar "Virtual Joystick" na Godot Asset Library — existem plugins prontos e testados.

## Dicas de UX Mobile

- Botões de ação: mínimo 80×80 px (área de toque)
- Joystick: posicionar no canto inferior esquerdo, ação no direito
- Usar `CanvasLayer` com `layer = 10` para UI ficar sempre acima do jogo
- Testar com `Project > Run on Device` via USB (Android) para validar toque real
- Ativar `Display > Window > Handheld > Orientation` = `landscape` para jogos top-down

## Detecção de plataforma

```gdscript
func _ready() -> void:
    if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
        $VirtualJoystick.visible = true
    else:
        $VirtualJoystick.visible = false
```
