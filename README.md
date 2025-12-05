# AOC

Baixe e abra o arquivo snake.asm no MARS.
Abra o Bitmap Display em Tools, clique em Connect to MIPS e defina:
Unit Width in Pixels para 8
Unit Height in Pixels para 8
Abra o Keyboard and Display MMIO Simulator em Tools e clique em Connect to MIPS.
Execute o programa para começar a jogar! Use WASD para mover. Observe que, na posição inicial, a cobra está indo para a direita, então você não pode se mover para a esquerda.

## Mecânicas do jogo ##
Entropia Progressiva (Risco): Ao consumir o alimento padrão (Vermelho), há 25% de chance de um obstáculo permanente (Cinza) ser gerado aleatoriamente no mapa, tornando o cenário progressivamente mais complexo e "sujo".

Power-up de Controle (Laranja): Reduz temporariamente a velocidade de atualização do game loop (efeito slow motion), permitindo manobras de precisão em cenários densos. A velocidade é restaurada gradualmente.

Power-up de Invencibilidade (Magenta): Altera o estado da cobra (cabeça branca), permitindo que ela atravesse e destrua obstáculos, paredes e o próprio corpo, servindo como uma ferramenta estratégica de limpeza do mapa.
