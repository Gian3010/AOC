# AOC

Baixe e abra o arquivo snake.asm no MARS.
Abra o Bitmap Display em Tools, clique em Connect to MIPS e defina:
Unit Width in Pixels para 8
Unit Height in Pixels para 8
<img width="408" height="231" alt="image" src="https://github.com/user-attachments/assets/e5e6359e-3bf9-429d-901f-0bf73cf439d5" />

Abra o Keyboard and Display MMIO Simulator em Tools e clique em Connect to MIPS.
Clique no espaço branco de baixo para usar o teclado.
<img width="877" height="775" alt="image" src="https://github.com/user-attachments/assets/bfa43e34-dd17-42bf-9802-b1bf40e16333" />

Execute o programa para começar a jogar! Use WASD para mover. Observe que, na posição inicial, a cobra está indo para a direita, então você não pode se mover para a esquerda.

## Mecânicas do jogo ##
Entropia Progressiva (Risco): Ao consumir o alimento padrão (Vermelho) 🍎, há 25% de chance de um obstáculo permanente (Cinza) ser gerado aleatoriamente no mapa, tornando o cenário progressivamente mais complexo e "sujo".

Power-up de Controle (Laranja): Reduz temporariamente a velocidade de atualização do game loop (efeito slow motion), permitindo manobras de precisão em cenários densos. A velocidade é restaurada gradualmente.

Power-up de Invencibilidade (Magenta): Altera o estado da cobra (cabeça branca), permitindo que ela atravesse e destrua obstáculos, paredes e o próprio corpo, servindo como uma ferramenta estratégica de limpeza do mapa.

## A Lógica da pontuação ##

🍎 Comida Normal (Vermelho): +10 Pontos

É a pontuação base. O jogador ganha pontos moderados, mas "paga" o preço aumentando o risco (cria obstáculos e aumenta o corpo).

🍊 Power-up de Lentidão (Laranja): +5 Pontos

Por que vale menos? Porque é um item de ajuda. Ele facilita o jogo deixando tudo em câmera lenta. O "pagamento" aqui é ganhar menos pontos em troca de sobrevivência.

🌟 Power-up de Estrela (Magenta): +50 Pontos

Por que vale tanto? É o "Jackpot". Além de ser rara (15% de chance), ela incentiva o jogador a limpar o mapa agressivamente. É a recompensa máxima.
