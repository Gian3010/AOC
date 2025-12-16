# Snake MIPS - Versão Refatorada com Tema "Retro Neon"
# Lógica idêntica, cores totalmente novas.

.data
    # --- VARIÁVEIS DE ESTADO ---
    var_pontos:      .word   0
    var_delay:       .word   60              # Delay inicial (ms)
    var_crescer:     .word   0               # Contador de crescimento
    var_imune:       .word   0               # Timer de invencibilidade

    # --- CONSTANTES DE CONFIGURAÇÃO ---
    MEM_VIDEO:       .word   0x10008000
    MASCARA_COR:     .word   0x00FFFFFF
    MASCARA_DIR:     .word   0xFF000000

    # --- NOVA PALETA DE CORES (TEMA NEON) ---
    # Formato: 0x00RRGGBB
    COR_FUNDO:       .word   0x00000000      # Preto (Fundo)
    COR_PAREDE:      .word   0x009900CC      # Roxo Neon (Paredes)
    COR_COBRA:       .word   0x0000FF00      # Verde Neon vibrante (Corpo)
    COR_BLOCO:       .word   0x00AAAAAA      # Cinza Claro (Obstáculo)
    COR_IMORTAL:     .word   0x00FFFF00      # Amarelo Ouro (Cabeça quando imune)
    
    # --- ITENS COLECIONÁVEIS ---
    ITEM_PONTO:      .word   0x00FF3333      # Vermelho Claro (Comida normal)
    ITEM_GELO:       .word   0x0000CCFF      # Azul Ciano (Gelo/Lentidão)
    ITEM_ESTRELA:    .word   0x00FFCC00      # Laranja Dourado (Invencibilidade)

    # --- VETORES DE DIREÇÃO ---
    VET_NORTE:       .word   0x01000000
    VET_SUL:         .word   0x02000000
    VET_OESTE:       .word   0x03000000
    VET_LESTE:       .word   0x04000000

    # --- MENSAGENS ---
    txt_perdeu:      .asciiz "Fim de Jogo (Tema Neon)! Pontos: "
    txt_replay:      .asciiz "\nJogar novamente? (1 = Sim, 0 = Nao)"

.text
.globl main

main:
    # 1. Configuração Inicial (Zerando registradores críticos)
    xor $s0, $s0, $s0           # $s0 = Pontuação (Zerar usando XOR)
    xor $s3, $s3, $s3           # $s3 = Direção atual (0 = parado)
    
    # Resetar variáveis de memória
    addi $t0, $zero, 60
    sw   $t0, var_delay
    sw   $zero, var_crescer
    sw   $zero, var_imune
    
    # Limpar buffer do teclado (MMIO)
    lui  $t9, 0xffff
    sw   $zero, 4($t9)

    # 2. Renderização do Cenário
    jal  pintar_fundo
    jal  construir_muros

    # 3. Spawnar Cobra (Posicionamento central)
    lw   $t0, MEM_VIDEO
    addi $t0, $t0, 3964         # Centro da tela
    
    move $s1, $t0               # $s1 = Ponteiro Cabeça
    move $s2, $t0               # $s2 = Ponteiro Rabo
    
    # Desenhar os 3 segmentos iniciais
    lw   $t1, COR_COBRA
    lw   $t2, VET_LESTE
    or   $t3, $t1, $t2          # Combina Cor + Direção
    
    sw   $t3, 0($t0)            # Cabeça
    sw   $t3, -4($t0)           # Corpo 1
    sw   $t3, -8($t0)           # Corpo 2
    
    addi $s2, $s1, -8           # Corrige ponteiro do rabo
    lw   $s3, VET_LESTE         # Define movimento inicial para direita

    # 4. Primeiro item
    jal  gerar_loot

# --- LOOP PRINCIPAL DO JOGO ---
nucleo_jogo:
    # Verificação de Teclado (Polling)
    lui  $t0, 0xffff
    lw   $t1, 0($t0)            # Lê status
    andi $t1, $t1, 1
    beqz $t1, atualizar_fisica  # Se não tem tecla, pula
    
    lw   $a0, 4($t0)            # Lê tecla
    
    # Switch Case de Teclas
    addi $t8, $zero, 119        # 'w'
    beq  $a0, $t8, muda_norte
    addi $t8, $zero, 115        # 's'
    beq  $a0, $t8, muda_sul
    addi $t8, $zero, 97         # 'a'
    beq  $a0, $t8, muda_oeste
    addi $t8, $zero, 100        # 'd'
    beq  $a0, $t8, muda_leste
    j    atualizar_fisica

# Lógica de mudança de direção (evita volta 180 graus)
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
    # Controle de Tempo (Sleep)
    addi $v0, $zero, 32
    lw   $a0, var_delay
    syscall
    
    # Recuperação de velocidade (efeito Slow desaparecendo)
    lw   $t0, var_delay
    addi $t1, $zero, 60
    ble  $t0, $t1, checar_poder
    subi $t0, $t0, 1            # Reduz delay gradualmente
    sw   $t0, var_delay

checar_poder:
    lw   $t0, var_imune
    blez $t0, mover_agora
    subi $t0, $t0, 1            # Decrementa timer imortalidade
    sw   $t0, var_imune

mover_agora:
    # Se direção for 0, não move
    beq  $s3, $zero, nucleo_jogo

    # 1. Marcar o chão atual com a direção (para o rabo seguir depois)
    lw   $t0, ($s1)             # Lê pixel atual da cabeça
    lw   $t1, MASCARA_COR
    and  $t0, $t0, $t1          # Limpa bits de direção antigos
    or   $t0, $t0, $s3          # Insere nova direção
    sw   $t0, ($s1)

    # 2. Calcular endereço da nova cabeça
    lw   $t1, VET_NORTE
    beq  $s3, $t1, calc_norte
    lw   $t1, VET_SUL
    beq  $s3, $t1, calc_sul
    lw   $t1, VET_OESTE
    beq  $s3, $t1, calc_oeste
    # Default: Leste
    addi $s1, $s1, 4
    j    colisao

calc_norte: addi $s1, $s1, -256
            j    colisao
calc_sul:   addi $s1, $s1, 256
            j    colisao
calc_oeste: addi $s1, $s1, -4

colisao:
    # Verificar o que existe na nova posição
    lw   $t0, ($s1)             # Lê conteúdo do destino
    lw   $t9, MASCARA_COR
    and  $t0, $t0, $t9          # Isola a cor
    
    lw   $t2, COR_FUNDO
    beq  $t0, $t2, espaco_livre
    
    # Verificação de Itens
    lw   $t2, ITEM_PONTO
    beq  $t0, $t2, pegou_comida
    lw   $t2, ITEM_GELO
    beq  $t0, $t2, pegou_gelo
    lw   $t2, ITEM_ESTRELA
    beq  $t0, $t2, pegou_estrela

    # Se chegou aqui, bateu em parede ou obstáculo
    lw   $t8, var_imune
    bgtz $t8, espaco_livre      # Se imune, ignora colisão
    j    tela_gameover

# --- EFEITOS DE ITENS ---
pegou_comida:
    addi $s0, $s0, 10
    lw   $t0, var_crescer
    addi $t0, $t0, 1
    sw   $t0, var_crescer
    jal  chance_obstaculo       # Pode gerar pedra cinza
    jal  gerar_loot
    j    renderizar_cabeca

pegou_gelo:
    addi $s0, $s0, 5
    addi $t0, $zero, 150        # Define lentidão
    sw   $t0, var_delay
    jal  gerar_loot
    j    renderizar_cabeca

pegou_estrela:
    addi $s0, $s0, 50
    addi $t0, $zero, 150        # Define tempo imune
    sw   $t0, var_imune
    lw   $t1, var_crescer
    addi $t1, $t1, 2            # Cresce +2
    sw   $t1, var_crescer
    jal  gerar_loot
    j    renderizar_cabeca

espaco_livre:
    # Lógica do Rabo: Só move se não tiver que crescer
    lw   $t0, var_crescer
    bgtz $t0, processar_crescimento
    
    # Apagar o último bloco (rabo)
    lw   $t5, ($s2)             # Lê o pixel do rabo atual
    lw   $t6, MASCARA_DIR
    and  $t5, $t5, $t6          # Extrai a direção salva
    
    lw   $t7, COR_FUNDO
    sw   $t7, ($s2)             # Pinta com a cor do fundo (apaga)
    
    # Atualiza ponteiro do rabo baseado na direção lida
    lw   $t8, VET_NORTE
    beq  $t5, $t8, rabo_norte
    lw   $t8, VET_SUL
    beq  $t5, $t8, rabo_sul
    lw   $t8, VET_OESTE
    beq  $t5, $t8, rabo_oeste
    # Rabo leste
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
    # Pula a etapa de mover o rabo, efetivamente aumentando a cobra

renderizar_cabeca:
    # Escolhe a cor da cabeça
    lw   $t9, var_imune
    blez $t9, cor_normal
    lw   $t0, COR_IMORTAL       # Amarelo se imune
    j    pintar_final
cor_normal:
    lw   $t0, COR_COBRA         # Verde neon normal
pintar_final:
    sw   $t0, ($s1)
    j    nucleo_jogo

# --- ROTINAS DE GERAÇÃO (RNG) ---
gerar_loot:
    # $a0 = Semente random (0-99)
    li   $v0, 42
    move $a0, $zero
    li   $a1, 100
    syscall
    
    # 0..14: Gelo, 15..29: Estrela, 30+: Comida
    slti $t0, $a0, 15
    bnez $t0, item_tipo_gelo
    slti $t0, $a0, 30
    bnez $t0, item_tipo_estrela
    
    lw   $a2, ITEM_PONTO
    j    posicionar_item

item_tipo_gelo:
    lw   $a2, ITEM_GELO
    j    posicionar_item

item_tipo_estrela:
    lw   $a2, ITEM_ESTRELA

posicionar_item:
    # Tenta achar posição vazia
    li   $v0, 42
    li   $a0, 0
    li   $a1, 2048
    syscall
    
    sll  $a0, $a0, 2            # Multiplica por 4 (offset bytes)
    lw   $t0, MEM_VIDEO
    add  $t0, $t0, $a0
    
    lw   $t1, ($t0)
    lw   $t2, COR_FUNDO
    bne  $t1, $t2, posicionar_item # Loop se ocupado
    
    sw   $a2, ($t0)
    jr   $ra

chance_obstaculo:
    # Chance 1 em 4
    li   $v0, 42
    li   $a0, 0
    li   $a1, 4
    syscall
    bnez $a0, fim_obst          # Se não for 0, sai
    
    # Gera obstaculo
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

# --- DESENHO INICIAL ---
pintar_fundo:
    lw   $t0, MEM_VIDEO
    lw   $t1, COR_FUNDO
    addi $t2, $zero, 2048       # Contador pixels
loop_fundo:
    sw   $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, -1
    bnez $t2, loop_fundo
    jr   $ra

construir_muros:
    lw   $t0, MEM_VIDEO
    lw   $t1, COR_PAREDE
    
    # Paredes Horizontais (Superior e Inferior)
    move $t3, $t0
    addi $t5, $zero, 64         # Largura
loop_horiz:
    sw   $t1, 0($t3)            # Linha superior
    sw   $t1, 7936($t3)         # Linha inferior (offset fixo)
    addi $t3, $t3, 4
    addi $t5, $t5, -1
    bnez $t5, loop_horiz
    
    # Paredes Verticais
    lw   $t3, MEM_VIDEO
    addi $t5, $zero, 32         # Altura
loop_vert:
    sw   $t1, 0($t3)            # Esquerda
    sw   $t1, 252($t3)          # Direita
    addi $t3, $t3, 256          # Próxima linha
    addi $t5, $t5, -1
    bnez $t5, loop_vert
    
    jr   $ra

# --- FIM DE JOGO ---
tela_gameover:
    li   $v0, 56
    la   $a0, txt_perdeu
    move $a1, $s0
    syscall
    
    li   $v0, 50
    la   $a0, txt_replay
    syscall
    
    beqz $a0, main              # Se sim, reinicia
    
    li   $v0, 10                # Exit
    syscall
