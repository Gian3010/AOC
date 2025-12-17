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

Mudamos a cor padrão do jogo Snake para dar um tom maior de futurismo quase como algo no estilo cyberpunk, utilizando um fundo preto com bordas roxas e cores claras(como o verde e as cores dos power-ups)

Entropia Progressiva (Risco): Ao consumir o alimento padrão (Vermelho) 🍎, há 25% de chance de um obstáculo permanente (Cinza) ser gerado aleatoriamente no mapa, tornando o cenário progressivamente mais complexo e "sujo".
Comida Normal (Vermelho): +10 Pontos
É a pontuação base. O jogador ganha pontos moderados, mas "paga" o preço aumentando o risco (cria obstáculos e aumenta o corpo)

<img width="638" height="322" alt="image" src="https://github.com/user-attachments/assets/3f8d5622-6499-45cd-8881-805d12645451" />



Power-up de Controle (Azul): Reduz temporariamente a velocidade de atualização do game loop (efeito slow motion), permitindo manobras de precisão em cenários densos. A velocidade é restaurada gradualmente.
Power-up de Lentidão (Azul): +5 Pontos
Por que vale menos? Porque é um item de ajuda. Ele facilita o jogo deixando tudo em câmera lenta. O "pagamento" aqui é ganhar menos pontos em troca de sobrevivência.


<img width="641" height="317" alt="image" src="https://github.com/user-attachments/assets/7fb2a242-a2aa-4eab-ac21-c1b4a8468813" />


Power-up de Invencibilidade (Amarelo): Altera o estado da cobra (cabeça branca), permitindo que ela atravesse e destrua obstáculos, paredes e o próprio corpo, servindo como uma ferramenta estratégica de limpeza do mapa.
Power-up de Estrela (Amarelo): +50 Pontos
Por que vale tanto? É o "Jackpot". Além de ser rara (15% de chance), ela incentiva o jogador a limpar o mapa agressivamente. É a recompensa máxima.

<img width="640" height="313" alt="image" src="https://github.com/user-attachments/assets/6514c393-00b1-4607-8fd6-824eb94addcf" />


Caso você acabe comendo seu próprio corpo enquanto estiver no efeito do power-up magenta, a parte será desconectada de seu corpo e funcionara como mais um obstáculo

<img width="755" height="483" alt="image" src="https://github.com/user-attachments/assets/8fa3112a-fcb7-4bef-91aa-ba2f68f83fe6" />


## Modo Hard ##
Ou também conhecido como modo inferno, pela cor de suas paredes e seu nível de dificuldade. 
Nesse modo temos 2 paredes na área central para dar um grau de desafio maior aos jogadores.

<img width="638" height="326" alt="image" src="https://github.com/user-attachments/assets/c0fe317d-0227-4bcf-91c3-e9958e3ba59c" />


Além disso ao comer uma maçã (Agora da cor rosa para nao confundir com a cor da parede), serão gerados 2 obstáculos cinzas ao invés de 1 como é no modo normal.

<img width="645" height="325" alt="image" src="https://github.com/user-attachments/assets/5660fc5a-156c-44a4-b36a-c959741aebfd" />


