# Snake MIPS - Versão Final "Hell Mode Fixed"
# Correção Principal: Teleporte vertical no Hard Mode arrumado.
# (Truque: Paredes da borda e do centro usam códigos de cor diferentes para a lógica funcionar).

.data
    # --- VARIÁVEIS DE ESTADO ---
    var_pontos:      .word   0
    var_delay:       .word   60              # Delay inicial
    var_crescer:     .word   0
    var_imune:       .word   0
    var_modo:        .word   1               # 0 = Hard, 1 = Normal

    # --- CONSTANTES DE CONFIGURAÇÃO ---
    MEM_VIDEO:       .word   0x10008000
    MASCARA_COR:     .word   0x00FFFFFF
    MASCARA_DIR:     .word   0xFF000000

    # --- CORES ---
    COR_FUNDO:       .word   0x00000000      # Preto
    COR_PAREDE:      .word   0x009900CC      # Roxo Neon (Bordas Normal Mode)
    
    # TRUQUE VISUAL: Cores diferentes para lógica, mas visualmente vermelhas
    COR_INFERNO:     .word   0x00FF0000      # Vermelho Puro (Paredes do Meio - Atravessa)
    COR_INFERNO_BRD: .word   0x00FF0001      # Vermelho + 1 bit Azul (Bordas Hard - Teleporta)
    
    COR_COBRA:       .word   0x0000FF00      # Verde Neon
    COR_BLOCO:       .word   0x00AAAAAA      # Cinza Claro
    COR_IMORTAL:     .word   0x00FFFF00      # Amarelo Ouro
    
    # --- ITENS ---
    ITEM_PONTO:      .word   0x00FF3333      # Vermelho Claro (Maçã Normal)
    ITEM_PONTO_HARD: .word   0x00FF0099      # Rosa Neon (Maçã Hard Mode)
    ITEM_GELO:       .word   0x0000CCFF      # Azul Ciano
    ITEM_ESTRELA:    .word   0x00FFCC00      # Laranja Dourado

    # --- DIREÇÕES ---
    VET_NORTE:       .word   0x01000000
    VET_SUL:         .word   0x02000000
    VET_OESTE:       .word   0x03000000
    VET_LESTE:       .word   0x04000000

    # --- MENSAGENS ---
    txt_modo:        .asciiz "Ativar MODO INFERNO (Hard)?\n(Paredes vermelhas, Maça rosa + Obstaculos)"
    txt_perdeu:      .asciiz "Fim de Jogo! Pontuacao Final: "
    txt_replay:      .asciiz "\nJogar novamente? (1 = Sim, 0 = Nao)"

.text
.globl main

main:
    # 1. MENU DE SELEÇÃO
    li   $v0, 50
    la   $a0, txt_modo
    syscall
    
    # Se cancelou (2) ou não (1), define como Normal. Se (0), Hard.
    li   $t0, 0
    beq  $a0, $t0, set_hard
    li   $a0, 1          # Normal
    j    salva_modo
set_hard:
    li   $a0, 0          # Hard
salva_modo:
    sw   $a0, var_modo

    # 2. Configuração Inicial
    xor $s0, $s0, $s0           # Zerar Pontos
    xor $s3, $s3, $s3           # Zerar Direção
    
    addi $t0, $zero, 60         # Resetar Delay
    sw   $t0, var_delay
    sw   $zero, var_crescer
    sw   $zero, var_imune
    
    # Limpeza Crítica de Buffer
    lui  $t9, 0xffff
    sw   $zero, 4($t9)

    # 3. Renderização
    jal  pintar_fundo
    jal  construir_muros

    # 4. Spawnar Cobra
    lw   $t0, MEM_VIDEO
    addi $t0, $t0, 3964
    
    move $s1, $t0               # Cabeça
    move $s2, $t0               # Rabo
    
    # Segmentos
    lw   $t1, COR_COBRA
    lw   $t2, VET_LESTE
    or   $t3, $t1, $t2
    
    sw   $t3, 0($t0)
    sw   $t3, -4($t0)
    sw   $t3, -8($t0)
    
    addi $s2, $s1, -8
    lw   $s3, VET_LESTE

    # 5. Primeiro Loot
    jal  gerar_loot

# --- LOOP PRINCIPAL ---
nucleo_jogo:
    # Input
    lui  $t0, 0xffff
    lw   $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, atualizar_fisica
    
    lw   $a0, 4($t0)
    
    # WASD
    addi $t8, $zero, 119
    beq  $a0, $t8, muda_norte
    addi $t8, $zero, 115
    beq  $a0, $t8, muda_sul
    addi $t8, $zero, 97
    beq  $a0, $t8, muda_oeste
    addi $t8, $zero, 100
    beq  $a0, $t8, muda_leste
    j    atualizar_fisica

muda_norte:
    lw   $t9, VET_SUL
    beq  $s3, $t9, atualizar_fisica
    lw   $s3, VET_NORTE
    j    atualizar_fisica
muda_sul:
    lw   $t9, VET_NORTE
    beq  $s3, $t9, atualizar_fisica
    lw   $s3, VET_SUL
    j    atualizar_fisica
muda_oeste:
    lw   $t9, VET_LESTE
    beq  $s3, $t9, atualizar_fisica
    lw   $s3, VET_OESTE
    j    atualizar_fisica
muda_leste:
    lw   $t9, VET_OESTE
    beq  $s3, $t9, atualizar_fisica
    lw   $s3, VET_LESTE

atualizar_fisica:
    # Delay
    addi $v0, $zero, 32
    lw   $a0, var_delay
    syscall
    
    # Recuperação de Velocidade
    lw   $t0, var_delay
    addi $t1, $zero, 60
    ble  $t0, $t1, checar_poder
    subi $t0, $t0, 1
    sw   $t0, var_delay

checar_poder:
    lw   $t0, var_imune
    blez $t0, mover_agora
    subi $t0, $t0, 1
    sw   $t0, var_imune

mover_agora:
    beq  $s3, $zero, nucleo_jogo

    # 1. Salva direção
    lw   $t0, ($s1)
    lw   $t1, MASCARA_COR
    and  $t0, $t0, $t1
    or   $t0, $t0, $s3
    sw   $t0, ($s1)

    # 2. Calcula posição
    lw   $t1, VET_NORTE
    beq  $s3, $t1, calc_norte
    lw   $t1, VET_SUL
    beq  $s3, $t1, calc_sul
    lw   $t1, VET_OESTE
    beq  $s3, $t1, calc_oeste
    # Leste
    addi $s1, $s1, 4
    j    colisao

calc_norte: addi $s1, $s1, -256
            j    colisao
calc_sul:   addi $s1, $s1, 256
            j    colisao
calc_oeste: addi $s1, $s1, -4

colisao:
    # Check conteúdo
    lw   $t0, ($s1)
    lw   $t9, MASCARA_COR
    and  $t0, $t0, $t9
    
    lw   $t2, COR_FUNDO
    beq  $t0, $t2, espaco_livre
    
    # Itens (Verifica as duas cores de maçã)
    lw   $t2, ITEM_PONTO
    beq  $t0, $t2, pegou_comida
    lw   $t2, ITEM_PONTO_HARD
    beq  $t0, $t2, pegou_comida
    
    lw   $t2, ITEM_GELO
    beq  $t0, $t2, pegou_gelo
    lw   $t2, ITEM_ESTRELA
    beq  $t0, $t2, pegou_estrela

    # --- SISTEMA DE COLISÃO E TELEPORTE ---
    
    # 1. Borda Normal (Roxo) -> Teleporta
    lw   $t2, COR_PAREDE
    beq  $t0, $t2, bateu_borda
    
    # 2. Borda Inferno (Vermelho Borda) -> Teleporta
    lw   $t2, COR_INFERNO_BRD
    beq  $t0, $t2, bateu_borda
    
    # 3. Parede Inferno (Vermelho Centro) -> Atravessa
    lw   $t2, COR_INFERNO
    beq  $t0, $t2, bateu_inferno
    
    # 4. Obstáculo (Cinza) -> Quebra
    lw   $t2, COR_BLOCO
    beq  $t0, $t2, bateu_bloco

    # Morte padrão (ex: bater no próprio corpo)
    lw   $t8, var_imune
    bgtz $t8, espaco_livre
    j    tela_gameover_safe

bateu_bloco:
    lw   $t8, var_imune
    bgtz $t8, espaco_livre
    j    tela_gameover_safe

bateu_inferno:
    # Paredes do Meio: Se imune, atravessa (passa por cima)
    lw   $t8, var_imune
    bgtz $t8, espaco_livre
    j    tela_gameover_safe

bateu_borda:
    # Bordas Extremas: Se imune, TELEPORTA
    lw   $t8, var_imune
    blez $t8, tela_gameover_safe
    
    # Lógica de Wrap-Around
    lw   $t9, VET_NORTE
    beq  $s3, $t9, tp_baixo
    lw   $t9, VET_SUL
    beq  $s3, $t9, tp_cima
    lw   $t9, VET_OESTE
    beq  $s3, $t9, tp_direita
    # Leste -> Esquerda
    addi $s1, $s1, -248
    j    espaco_livre

tp_baixo:
    addi $s1, $s1, 7680     # Pula pro fundo
    j    espaco_livre
tp_cima:
    addi $s1, $s1, -7680    # Pula pro topo
    j    espaco_livre
tp_direita:
    addi $s1, $s1, 248      # Pula pra direita
    j    espaco_livre

# --- EFEITOS ---
pegou_comida:
    addi $s0, $s0, 10
    lw   $t0, var_crescer
    addi $t0, $t0, 1
    sw   $t0, var_crescer
    
    # Spawn de blocos
    jal  chance_obstaculo       # Bloco 1 (Sempre)
    lw   $t9, var_modo
    bnez $t9, fim_spawn         # Se Normal, pula o segundo
    jal  chance_obstaculo       # Bloco 2 (Hard)

fim_spawn:
    jal  gerar_loot
    j    renderizar_cabeca

pegou_gelo:
    addi $s0, $s0, 5
    addi $t0, $zero, 150        # Slow Motion
    sw   $t0, var_delay
    jal  gerar_loot
    j    renderizar_cabeca

pegou_estrela:
    addi $s0, $s0, 50
    addi $t0, $zero, 50         # Imunidade (Curta: 50 frames)
    sw   $t0, var_imune
    lw   $t1, var_crescer
    addi $t1, $t1, 2
    sw   $t1, var_crescer
    jal  gerar_loot
    j    renderizar_cabeca

espaco_livre:
    lw   $t0, var_crescer
    bgtz $t0, processar_crescimento
    
    # Apaga rabo
    lw   $t5, ($s2)
    lw   $t6, MASCARA_DIR
    and  $t5, $t5, $t6
    
    lw   $t7, COR_FUNDO
    sw   $t7, ($s2)
    
    # Move rabo
    lw   $t8, VET_NORTE
    beq  $t5, $t8, rabo_norte
    lw   $t8, VET_SUL
    beq  $t5, $t8, rabo_sul
    lw   $t8, VET_OESTE
    beq  $t5, $t8, rabo_oeste
    addi $s2, $s2, 4
    j    renderizar_cabeca

rabo_norte: addi $s2, $s2, -256
            j    renderizar_cabeca
rabo_sul:   addi $s2, $s2, 256
            j    renderizar_cabeca
rabo_oeste: addi $s2, $s2, -4
            j    renderizar_cabeca

processar_crescimento:
    subi $t0, $t0, 1
    sw   $t0, var_crescer

renderizar_cabeca:
    lw   $t9, var_imune
    blez $t9, cor_normal
    lw   $t0, COR_IMORTAL
    j    pintar_final
cor_normal:
    lw   $t0, COR_COBRA
pintar_final:
    sw   $t0, ($s1)
    j    nucleo_jogo

# --- GERADORES ---
gerar_loot:
    li   $v0, 42
    move $a0, $zero
    li   $a1, 100
    syscall
    
    # RNG: 15% Gelo, 5% Estrela
    slti $t0, $a0, 15
    bnez $t0, item_tipo_gelo
    slti $t0, $a0, 20
    bnez $t0, item_tipo_estrela
    
    # Se for comida, verifica o modo
    lw   $t9, var_modo
    beqz $t9, maca_rosa      # Se Hard (0), rosa

    # Normal -> Vermelha
    lw   $a2, ITEM_PONTO
    j    posicionar_item

maca_rosa:
    lw   $a2, ITEM_PONTO_HARD
    j    posicionar_item

item_tipo_gelo:
    lw   $a2, ITEM_GELO
    j    posicionar_item
item_tipo_estrela:
    lw   $a2, ITEM_ESTRELA

posicionar_item:
    li   $v0, 42
    li   $a0, 0
    li   $a1, 2048
    syscall
    sll  $a0, $a0, 2
    lw   $t0, MEM_VIDEO
    add  $t0, $t0, $a0
    lw   $t1, ($t0)
    lw   $t2, COR_FUNDO
    bne  $t1, $t2, posicionar_item
    sw   $a2, ($t0)
    jr   $ra

chance_obstaculo:
    li   $v0, 42
    li   $a0, 0
    li   $a1, 2048
    syscall
    sll  $a0, $a0, 2
    
    lw   $t0, MEM_VIDEO
    add  $t0, $t0, $a0
    lw   $t1, ($t0)
    lw   $t2, COR_FUNDO
    bne  $t1, $t2, fim_obst
    
    lw   $t3, COR_BLOCO
    sw   $t3, ($t0)
fim_obst:
    jr   $ra

# --- CENÁRIO ---
pintar_fundo:
    lw   $t0, MEM_VIDEO
    lw   $t1, COR_FUNDO
    addi $t2, $zero, 2048
loop_fundo:
    sw   $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    bnez $t2, loop_fundo
    jr   $ra

construir_muros:
    lw   $t0, MEM_VIDEO
    
    # SELEÇÃO DE COR DA BORDA
    lw   $t9, var_modo
    beqz $t9, borda_hard     # Se 0 (Hard), usa cor especial de borda
    
    lw   $t1, COR_PAREDE     # Normal: Roxo
    j    desenhar_bordas
borda_hard:
    lw   $t1, COR_INFERNO_BRD # Hard: Vermelho Especial (Teleporta)
    
desenhar_bordas:
    move $t3, $t0
    addi $t5, $zero, 64
loop_horiz:
    sw   $t1, 0($t3)
    sw   $t1, 7936($t3)
    addi $t3, $t3, 4
    addi $t5, $t5, -1
    bnez $t5, loop_horiz
    
    lw   $t3, MEM_VIDEO
    addi $t5, $zero, 32
loop_vert:
    sw   $t1, 0($t3)
    sw   $t1, 252($t3)
    addi $t3, $t3, 256
    addi $t5, $t5, -1
    bnez $t5, loop_vert
    
    # PAREDES DO MEIO (APENAS HARD)
    lw   $t9, var_modo
    bnez $t9, fim_muros
    
    lw   $t1, COR_INFERNO    # Vermelho Puro (Atravessa)
    
    # Centro Superior
    lw   $t3, MEM_VIDEO
    addi $t3, $t3, 2560
    addi $t3, $t3, 40
    addi $t5, $zero, 44
hard_1:
    sw   $t1, 0($t3)
    addi $t3, $t3, 4
    addi $t5, $t5, -1
    bnez $t5, hard_1

    # Centro Inferior
    lw   $t3, MEM_VIDEO
    addi $t3, $t3, 5632
    addi $t3, $t3, 40
    addi $t5, $zero, 44
hard_2:
    sw   $t1, 0($t3)
    addi $t3, $t3, 4
    addi $t5, $t5, -1
    bnez $t5, hard_2

fim_muros:
    jr   $ra

# --- GAME OVER SAFE ---
tela_gameover_safe:
    # 0. Stop Total
    xor  $s3, $s3, $s3
    lui  $t9, 0xffff
    sw   $zero, 4($t9)

    # 1. Limpa tela
    jal  pintar_fundo
    
    # 2. Delay Aumentado (1.5 segundos)
    li   $v0, 32
    li   $a0, 1500
    syscall

    # 3. Exibe Pop-up
    li   $v0, 56
    la   $a0, txt_perdeu
    move $a1, $s0
    syscall
    
    li   $v0, 50
    la   $a0, txt_replay
    syscall
    
    beqz $a0, main
    
    li   $v0, 10
    syscall
