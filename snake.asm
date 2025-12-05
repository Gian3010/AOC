# Jogo Snake MIPS - Versão Linked Grid (Otimizada)
# Lógica: A direção do movimento fica salva nos bits superiores de cada pixel do corpo.

.data
    # Cores e Constantes
    bgcolor:        .word   0x00cefad0      # Verde claro
    wallcolor:      .word   0x00008631      # Verde escuro
    snakecolor:     .word   0x000000ff      # Azul
    foodcolor:      .word   0x00ff0000      # Vermelho
    
    # Direções (Bits superiores do pixel)
    # Mascara: 0xFF000000
    DIR_UP:         .word   0x01000000
    DIR_DOWN:       .word   0x02000000
    DIR_LEFT:       .word   0x03000000
    DIR_RIGHT:      .word   0x04000000
    
    # Textos
    msg_gameover:   .asciiz "Fim de Jogo! Pontos: "
    msg_retry:      .asciiz "\nJogar novamente? (1 = Sim, 0 = Nao)"

    # Display settings
    # Base Address no MARS geralmente é 0x10008000 ($gp)
    DISPLAY_BASE:   .word   0x10008000
    
.text
.globl main

main:
    # --- Inicialização ---
    li  $s0, 0              # Score
    li  $s3, 0              # Direção atual (0 = parado)
    
    # Limpa input anterior
    sw  $zero, 0xffff0004

    # 1. Desenhar o Mapa Completo
    jal draw_background
    jal draw_walls
    
    # 2. Inicializar Cobra
    # Começa no meio: (32 * 64) + 32 = offset aproximado
    # Endereço = Base + Offset
    lw  $t0, DISPLAY_BASE
    add $t0, $t0, 3964      # Posição central (ajuste manual)
    
    # Configura Cabeça ($s1) e Cauda ($s2)
    move $s1, $t0           # Cabeça
    move $s2, $t0           # Cauda começa no mesmo lugar da cabeça (tam 1 visualmente, mas vamos desenhar 3)
    
    # Desenha 3 segmentos iniciais
    lw  $t1, snakecolor
    lw  $t2, DIR_RIGHT      # Direção inicial implicita
    or  $t3, $t1, $t2       # Cor | Direção
    
    sw  $t3, 0($t0)         # Cabeça
    sw  $t3, -4($t0)        # Corpo 1
    sw  $t3, -8($t0)        # Corpo 2 (Cauda real)
    
    addi $s2, $s1, -8       # Ajusta ponteiro da cauda para o fim
    
    # Direção inicial do movimento
    lw  $s3, DIR_RIGHT 

    # 3. Gerar Comida
    jal spawn_food

# --- Loop Principal ---
game_loop:
    # A. Input Não-Bloqueante
    li  $t0, 0xffff0000     # Control register
    lw  $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, auto_move     # Se não tem tecla, continua andando
    
    # Se tem tecla, processa
    lw  $a0, 0xffff0004
    beq $a0, 119, try_up    # w
    beq $a0, 115, try_down  # s
    beq $a0, 97,  try_left  # a
    beq $a0, 100, try_right # d

    j auto_move

try_up:
    lw  $t1, DIR_DOWN
    beq $s3, $t1, auto_move # Não pode voltar
    lw  $s3, DIR_UP
    j   auto_move
try_down:
    lw  $t1, DIR_UP
    beq $s3, $t1, auto_move
    lw  $s3, DIR_DOWN
    j   auto_move
try_left:
    lw  $t1, DIR_RIGHT
    beq $s3, $t1, auto_move
    lw  $s3, DIR_LEFT
    j   auto_move
try_right:
    lw  $t1, DIR_LEFT
    beq $s3, $t1, auto_move
    lw  $s3, DIR_RIGHT

auto_move:
    # Delay (Velocidade do jogo)
    li  $v0, 32
    li  $a0, 60         # 60ms
    syscall

    # Se a direção for 0 (inicio), não move
    beqz $s3, game_loop

    # --- Lógica da Lista Encadeada ---
    # Passo 1: Marcar a direção atual no quadrado da cabeça ATUAL
    # Antes de mover $s1, precisamos salvar nele para onde ele vai
    lw  $t0, 0($s1)         # Lê cor atual da cabeça
    li  $t1, 0x00FFFFFF     # Máscara para manter só a cor
    and $t0, $t0, $t1
    or  $t0, $t0, $s3       # Adiciona a direção nos bits altos
    sw  $t0, 0($s1)         # Salva de volta na memória
    
    # Passo 2: Calcular nova posição da cabeça ($s1)
    lw  $t1, DIR_UP
    beq $s3, $t1, go_up
    lw  $t1, DIR_DOWN
    beq $s3, $t1, go_down
    lw  $t1, DIR_LEFT
    beq $s3, $t1, go_left
    lw  $t1, DIR_RIGHT
    beq $s3, $t1, go_right
    j   game_loop

go_up:
    addi $s1, $s1, -256     # -1 linha (64 squares * 4 bytes)
    j check_collision
go_down:
    addi $s1, $s1, 256
    j check_collision
go_left:
    addi $s1, $s1, -4
    j check_collision
go_right:
    addi $s1, $s1, 4

check_collision:
    # Lê o que tem na nova posição da cabeça
    lw  $t0, 0($s1)
    li  $t1, 0x00FFFFFF     # Isola cor
    and $t0, $t0, $t1
    
    lw  $t2, foodcolor
    beq $t0, $t2, eat_food
    
    lw  $t2, bgcolor
    bne $t0, $t2, game_over # Se não for fundo nem comida, bateu!

    # Se estiver livre (bgcolor), movemos a cauda
    # Apaga a cauda velha e move $s2 para a próxima
    
    # 1. Ler direção salva na cauda atual
    lw  $t0, 0($s2)         # Lê pixel da cauda
    li  $t1, 0xFF000000     # Máscara dos bits de direção
    and $t0, $t0, $t1       # $t0 agora tem a direção
    
    # 2. Apagar visualmente a cauda
    lw  $t2, bgcolor
    sw  $t2, 0($s2)
    
    # 3. Mover $s2 baseado na direção lida
    lw  $t1, DIR_UP
    beq $t0, $t1, tail_up
    lw  $t1, DIR_DOWN
    beq $t0, $t1, tail_down
    lw  $t1, DIR_LEFT
    beq $t0, $t1, tail_left
    lw  $t1, DIR_RIGHT
    beq $t0, $t1, tail_right
    # Se não tiver direção, algo deu errado (ou inicialização), mas segue
    j   draw_new_head

tail_up:
    addi $s2, $s2, -256
    j draw_new_head
tail_down:
    addi $s2, $s2, 256
    j draw_new_head
tail_left:
    addi $s2, $s2, -4
    j draw_new_head
tail_right:
    addi $s2, $s2, 4
    j draw_new_head

eat_food:
    # Aumenta score
    addi $s0, $s0, 1
    # Gera nova comida
    jal spawn_food
    # NÃO movemos a cauda neste turno (cobra cresce)
    j draw_new_head

draw_new_head:
    # Pinta a nova cabeça
    lw  $t0, snakecolor
    sw  $t0, 0($s1)
    
    j game_loop

# --- Funções Auxiliares ---

spawn_food:
    # Tenta achar um lugar aleatório
retry_spawn:
    li  $v0, 42
    li  $a0, 0
    li  $a1, 2048       # Total de quadrados
    syscall             # $a0 = índice aleatório
    
    sll $a0, $a0, 2     # * 4 bytes
    lw  $t0, DISPLAY_BASE
    add $t0, $t0, $a0   # Endereço real
    
    lw  $t1, 0($t0)     # Lê cor
    lw  $t2, bgcolor
    bne $t1, $t2, retry_spawn # Se não for fundo, tenta de novo
    
    lw  $t1, foodcolor
    sw  $t1, 0($t0)
    jr  $ra

draw_background:
    lw  $t0, DISPLAY_BASE
    lw  $t1, bgcolor
    li  $t2, 2048       # Total pixels (64 * 32)
bg_loop:
    sw  $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    bnez $t2, bg_loop
    jr  $ra

draw_walls:
    lw  $t0, DISPLAY_BASE
    lw  $t1, wallcolor
    li  $t2, 64         # Largura da linha
    
    # Parede Cima
    move $t3, $t0
    li   $t4, 64
w_top:
    sw   $t1, 0($t3)
    addi $t3, $t3, 4
    addi $t4, $t4, -1
    bnez $t4, w_top
    
    # Parede Baixo (Começa em Base + (31 * 256))
    lw   $t3, DISPLAY_BASE
    addi $t3, $t3, 7936 # Última linha
    li   $t4, 64
w_bot:
    sw   $t1, 0($t3)
    addi $t3, $t3, 4
    addi $t4, $t4, -1
    bnez $t4, w_bot
    
    # Laterais
    lw   $t3, DISPLAY_BASE
    li   $t4, 32         # Altura
w_sides:
    sw   $t1, 0($t3)     # Esquerda
    sw   $t1, 252($t3)   # Direita (Offset 63 * 4)
    addi $t3, $t3, 256   # Próxima linha
    addi $t4, $t4, -1
    bnez $t4, w_sides
    
    jr $ra

game_over:
    li  $v0, 56         # Dialog com mensagem
    la  $a0, msg_gameover
    move $a1, $s0       # Score
    syscall
    
    # Reiniciar?
    li  $v0, 50
    la  $a0, msg_retry
    syscall
    beqz $a0, main      # Se sim, volta pro main
    
    li  $v0, 10         # Sair
    syscall