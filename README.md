# AlexIra

Indicador de Ira Desatada para paladinos no World of Warcraft: Forever 1.60.1. Mostra o selo cujo Eco está armazenado, de um a três acúmulos, com o tempo restante. As asas douradas brilham ao chegar a três.

## Como usar

1. Coloque a pasta `AlexIra` em `_forever_/Interface/AddOns/` e reinicie o cliente para carregar a versão, as texturas e os sons.
2. Abra `/alexira` ou selecione **AlexIra** no painel de complementos.
3. Clique no selo que quer configurar. Cada selo tem três menus de som independentes, um por acúmulo. Escolha entre 30 opções de som, com efeitos do jogo e sons como **Pato de borracha**, **Buzina de palhaço** e **Boing**, ou ative **Sem som**. Use **Testar** na linha de um acúmulo para ouvir a escolha e ver aquele estado do indicador.
4. Marque **Mover indicador** para arrastá-lo. As escolhas e a posição são salvas por personagem.
5. Ajuste **Opacidade do fundo** de **1** (mais transparente) a **10** (opaco). O fundo cinza começa em **6**. O indicador mostra uma prévia silenciosa ao ajustar o controle fora de uma contagem ativa.

Por padrão, o alerta de proc do Choque Sagrado toca ao atingir três acúmulos. Os dois primeiros ficam em silêncio. O alerta reforçado combina o som nativo (SoundKit 23287) com um toque original mais audível. O menu também oferece o proc nativo sozinho. Os alertas usam o canal principal do WoW.

Os Ecos de Comando, Retidão, Sabedoria, Luz, Justiça e Fúria têm alertas independentes. O Eco fica visível até ser consumido ou expirar. Ao trocar o selo ativo, o contador continua mostrando o Eco que você armazenou.

Se o cliente ocultar a contagem da aura em combate, o indicador exibe **Estimativa** quando conseguir associar o ataque corpo a corpo a um acerto físico no alvo. Nessa situação, golpes extras, múltiplos atacantes e eventos indisponíveis podem afetar a contagem e o momento do alerta.

## Atualização 0.2.1

O contador lê a aura do Eco também no evento do golpe e processa acertos utilizáveis sem a espera adicional de 180 ms. Se o cliente ocultar a aura, a velocidade da estimativa depende dos eventos de combate que ele disponibiliza. O fundo cinza ganhou um controle de opacidade salvo por personagem.

## Atualização 0.2.0

Seis botões de selo deixam os três alertas de cada um acessíveis. A versão adiciona novas opções de som, efeitos originais e asas douradas ao indicador. As configurações da versão anterior são mantidas, com o reforço aplicado aos alertas que já usavam o proc.
