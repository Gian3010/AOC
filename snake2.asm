# Snake MIPS - Versão "Chaos" (Mais itens, nova cor)
# Controles: W, A, S, D (Movimento), R (Reiniciar se morrer)

.data
    # --- CORES (Formato 0x00RRGGBB) ---
    COLOR_BG:       .word   0x00cefad0      # Verde Claro (Fundo)
    COLOR_WALL:     .word   0x00008631      # Verde Escuro (Parede fixa)
    COLOR_OBSTACLE: .word   0x00505050      # Cinza Escuro (Obstáculo que nasce)
    COLOR_SNAKE:    .word   0x000000ff      # Azul (Corpo)
    COLOR_HEAD_INV: .word   0x00ffffff      # Branco (Cabeça Invencível)
    
    # --- ITENS ---
    COLOR_FOOD:     .word   0x00ff0000      # Vermelho (Normal)
    COLOR_SLOW:     .word   0x00FF7F00      # Laranja (Lentidão - Antigo Ciano)
    COLOR_STAR:     .word   0x00ff00ff      # Magenta (Invencibilidade)

    # --- DIREÇÕES (Bits Superiores) ---
    DIR_UP:         .word   0x01000000
    DIR_DOWN:       .word   0x02000000
    DIR_LEFT:       .word   0x03000000
    DIR_RIGHT:      .word   0x04000000
    MASK_DIR:       .word   0xFF000000
    MASK_COLOR:     .word   0x00FFFFFF

    # --- ESTADO DO JOGO ---
    score:          .word   0
    sleep_time:     .word   60              # Tempo padrão (ms)
    growth_pending: .word   0               # Quantos blocos faltam crescer
    invincible_timer:.word  0               # Frames de invencibilidade

    # --- CONFIG ---
    DISPLAY_BASE:   .word   0x10008000
    
    # Textos
    msg_gameover:   .asciiz "Fim de Jogo! Pontos: "
    msg_retry:      .asciiz "\nJogar novamente? (1 = Sim, 0 = Nao)"

.text
.globl main

main:
    # --- Inicialização ---
    li  $s0, 0              # Score zerado
    li  $s3, 0              # Direção parada
    li  $t0, 60
    sw  $t0, sleep_time
    sw  $zero, growth_pending
    sw  $zero, invincible_timer
    
    sw  $zero, 0xffff0004   # Limpa buffer teclado

    # 1. Desenhar Mapa
    jal draw_background
    jal draw_walls
    
    # 2. Inicializar Cobra (Centro)
    lw  $t0, DISPLAY_BASE
    add $t0, $t0, 3964      # Offset centro
    move $s1, $t0           # Cabeça
    move $s2, $t0           # Cauda
    
    # Corpo inicial
    lw  $t1, COLOR_SNAKE
    lw  $t2, DIR_RIGHT
    or  $t3, $t1, $t2
    
    sw  $t3, 0($t0)         # Head
    sw  $t3, -4($t0)        # Body 1
    sw  $t3, -8($t0)        # Body 2
    
    addi $s2, $s1, -8       # Ajusta cauda
    lw  $s3, DIR_RIGHT      # Define direção inicial

    # 3. Gerar Primeira Comida
    jal spawn_item_logic

# --- GAME LOOP ---
game_loop:
    # A. Input Não-Bloqueante
    li  $t0, 0xffff0000
    lw  $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, logic_step
    
    lw  $a0, 0xffff0004
    beq $a0, 119, try_up    # w
    beq $a0, 115, try_down  # s
    beq $a0, 97,  try_left  # a
    beq $a0, 100, try_right # d
    j   logic_step

try_up:
    lw $t1, DIR_DOWN
    beq $s3, $t1, logic_step
    lw $s3, DIR_UP
    j logic_step
try_down:
    lw $t1, DIR_UP
    beq $s3, $t1, logic_step
    lw $s3, DIR_DOWN
    j logic_step
try_left:
    lw $t1, DIR_RIGHT
    beq $s3, $t1, logic_step
    lw $s3, DIR_LEFT
    j logic_step
try_right:
    lw $t1, DIR_LEFT
    beq $s3, $t1, logic_step
    lw $s3, DIR_RIGHT

logic_step:
    # --- Sleep Dinâmico (Velocidade) ---
    li  $v0, 32
    lw  $a0, sleep_time
    syscall
    
    # Recuperação da velocidade (se estiver lento, acelera um pouco)
    lw  $t0, sleep_time
    bgt $t0, 60, normalize_speed
    j   check_invincible
normalize_speed:
    subi $t0, $t0, 1        # Diminui o delay (acelera)
    sw  $t0, sleep_time

check_invincible:
    lw  $t0, invincible_timer
    blez $t0, move_logic
    subi $t0, $t0, 1        # Conta o tempo do power-up
    sw  $t0, invincible_timer

move_logic:
    beqz $s3, game_loop     # Se parado, espera

    # 1. Salvar direção atual no "chão" (cabeça atual)
    lw  $t0, 0($s1)
    lw  $t1, MASK_COLOR
    and $t0, $t0, $t1       # Preserva cor
    or  $t0, $t0, $s3       # Grava direção
    sw  $t0, 0($s1)
    
    # 2. Calcular Nova Posição ($s1)
    lw  $t1, DIR_UP
    beq $s3, $t1, go_up
    lw  $t1, DIR_DOWN
    beq $s3, $t1, go_down
    lw  $t1, DIR_LEFT
    beq $s3, $t1, go_left
    lw  $t1, DIR_RIGHT
    beq $s3, $t1, go_right

go_up:    addi $s1, $s1, -256
          j detect_collision
go_down:  addi $s1, $s1, 256
          j detect_collision
go_left:  addi $s1, $s1, -4
          j detect_collision
go_right: addi $s1, $s1, 4

detect_collision:
    # O que tem na frente?
    lw  $t0, 0($s1)
    lw  $t1, MASK_COLOR
    and $t0, $t0, $t1       # $t0 = Cor do objeto
    
    lw  $t2, COLOR_BG
    beq $t0, $t2, empty_space
    
    lw  $t2, COLOR_FOOD
    beq $t0, $t2, eat_food
    
    lw  $t2, COLOR_SLOW
    beq $t0, $t2, eat_slow
    
    lw  $t2, COLOR_STAR
    beq $t0, $t2, eat_star

    # Se não é item nem fundo, é colisão perigosa (Parede/Obstáculo)
    lw  $t9, invincible_timer
    bgtz $t9, empty_space   # Se invencível, ignora a morte (atravessa/destroi)
    
    j   game_over

# --- Efeitos dos Itens ---
eat_food:
    addi $s0, $s0, 10       # Pontos
    lw   $t0, growth_pending
    addi $t0, $t0, 1        # Cresce 1
    sw   $t0, growth_pending
    jal  spawn_obstacle_chance
    jal  spawn_item_logic
    j    draw_new_head

eat_slow: # Item Laranja
    addi $s0, $s0, 5
    li   $t0, 150           # Fica MUITO lento (150ms)
    sw   $t0, sleep_time
    jal  spawn_item_logic
    j    draw_new_head

eat_star: # Item Magenta (Invencibilidade)
    addi $s0, $s0, 50       # Bonus grande de pontos
    li   $t0, 150           # Duração maior da invencibilidade
    sw   $t0, invincible_timer
    lw   $t0, growth_pending
    addi $t0, $t0, 2        # Cresce 2
    sw   $t0, growth_pending
    jal  spawn_item_logic
    j    draw_new_head

empty_space:
    # Move a cauda (a menos que precise crescer)
    lw   $t0, growth_pending
    bgtz $t0, grow_step
    
    # Apaga rabo
    lw   $t0, 0($s2)        # Lê cauda velha
    lw   $t1, MASK_DIR
    and  $t0, $t0, $t1      # Extrai direção salva lá
    
    lw   $t2, COLOR_BG
    sw   $t2, 0($s2)        # Pinta de verde (apaga)
    
    # Move ponteiro $s2
    lw   $t1, DIR_UP
    beq  $t0, $t1, t_up
    lw   $t1, DIR_DOWN
    beq  $t0, $t1, t_down
    lw   $t1, DIR_LEFT
    beq  $t0, $t1, t_left
    lw   $t1, DIR_RIGHT
    beq  $t0, $t1, t_right
    j    draw_new_head      # Segurança

t_up:   addi $s2, $s2, -256
        j draw_new_head
t_down: addi $s2, $s2, 256
        j draw_new_head
t_left: addi $s2, $s2, -4
        j draw_new_head
t_right:addi $s2, $s2, 4
        j draw_new_head

grow_step:
    subi $t0, $t0, 1
    sw   $t0, growth_pending
    # Não apaga o rabo -> cobra aumenta

draw_new_head:
    # Se invencível, cabeça fica BRANCA
    lw   $t9, invincible_timer
    bgtz $t9, paint_white
    lw   $t0, COLOR_SNAKE
    j    do_paint
paint_white:
    lw   $t0, COLOR_HEAD_INV
do_paint:
    sw   $t0, 0($s1)
    j    game_loop

# --- Spawners e Lógica Aleatória ---

spawn_item_logic:
    # Sorteia item (0 a 99)
    li   $v0, 42
    li   $a0, 0
    li   $a1, 100
    syscall
    
    # Probabilidades NOVAS:
    # 0 a 14 (15%) -> Laranja (Slow)
    # 15 a 29 (15%) -> Estrela (Invincible)
    # 30 a 99 (70%) -> Vermelho (Food)
    
    blt  $a0, 15, spawn_slow
    blt  $a0, 30, spawn_star
    j    spawn_food_real

spawn_food_real:
    lw   $a2, COLOR_FOOD
    j    spawn_any
spawn_slow:
    lw   $a2, COLOR_SLOW
    j    spawn_any
spawn_star:
    lw   $a2, COLOR_STAR
    j    spawn_any

spawn_any:
    # Encontra lugar livre
    li   $v0, 42
    li   $a0, 0
    li   $a1, 2048
    syscall
    sll  $a0, $a0, 2
    lw   $t0, DISPLAY_BASE
    add  $t0, $t0, $a0
    lw   $t1, 0($t0)
    lw   $t2, COLOR_BG
    bne  $t1, $t2, spawn_any # Tenta de novo se não for BG
    sw   $a2, 0($t0)
    jr   $ra

spawn_obstacle_chance:
    # 25% de chance de obstáculo ao comer
    li   $v0, 42
    li   $a0, 0
    li   $a1, 4
    syscall
    bnez $a0, no_obst
    
    # Gera obstáculo cinza
    li   $v0, 42
    li   $a0, 0
    li   $a1, 2048
    syscall
    sll  $a0, $a0, 2
    lw   $t0, DISPLAY_BASE
    add  $t0, $t0, $a0
    lw   $t1, 0($t0)
    lw   $t2, COLOR_BG
    bne  $t1, $t2, no_obst 
    lw   $t3, COLOR_OBSTACLE
    sw   $t3, 0($t0)
no_obst:
    jr   $ra

# --- Desenho de Fundo e Paredes ---
draw_background:
    lw   $t0, DISPLAY_BASE
    lw   $t1, COLOR_BG
    li   $t2, 2048
bg_l:
    sw   $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    bnez $t2, bg_l
    jr   $ra

draw_walls:
    lw   $t0, DISPLAY_BASE
    lw   $t1, COLOR_WALL
    # Cima / Baixo
    move $t3, $t0
    li   $t4, 64
w_top: sw $t1, 0($t3)
       addi $t3, $t3, 4
       addi $t4, $t4, -1
       bnez $t4, w_top
       
    lw   $t3, DISPLAY_BASE
    addi $t3, $t3, 7936
    li   $t4, 64
w_bot: sw $t1, 0($t3)
       addi $t3, $t3, 4
       addi $t4, $t4, -1
       bnez $t4, w_bot
       
    # Laterais
    lw   $t3, DISPLAY_BASE
    li   $t4, 32
w_side: sw $t1, 0($t3)
        sw $t1, 252($t3)
        addi $t3, $t3, 256
        addi $t4, $t4, -1
        bnez $t4, w_side
    jr $ra

game_over:
    li   $v0, 56
    la   $a0, msg_gameover
    move $a1, $s0
    syscall
    li   $v0, 50
    la   $a0, msg_retry
    syscall
    beqz $a0, main
    li   $v0, 10
    syscall
