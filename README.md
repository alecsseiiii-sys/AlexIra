# AlexIra

Indicador de Ira Desatada para paladinos no World of Warcraft: Forever 1.60.1. Mostra o selo cujo Eco está armazenado, de um a três acúmulos, com o tempo restante. As asas douradas brilham ao chegar a três.

## Como usar

1. Coloque a pasta `AlexIra` em `_forever_/Interface/AddOns/` e reinicie o cliente para carregar a versão, as texturas e os sons.
2. Abra `/alex` ou selecione **AlexIra** no painel de complementos. O atalho `/alexira` também abre o menu.
3. Clique no selo que quer configurar. Cada selo tem três menus de som independentes, um por acúmulo. Escolha entre 30 opções de som, com efeitos do jogo e sons como **Pato de borracha**, **Buzina de palhaço** e **Boing**, ou ative **Sem som**. Use **Testar** na linha de um acúmulo para ouvir a escolha e ver aquele estado do indicador.
4. Marque **Mover indicador** para arrastá-lo. As escolhas e a posição são salvas por personagem.
5. Em **Estilo do indicador**, escolha **Asas Douradas**, **Simples**, **Relicário** ou **Vitral Sagrado**. Ajuste **Opacidade do fundo** de **1** (mais transparente) a **10** (opaco). O fundo cinza começa em **6**. O menu mostra uma prévia silenciosa ao mudar a aparência fora de uma contagem ativa.

Por padrão, o alerta de proc do Choque Sagrado toca ao atingir três acúmulos. Os dois primeiros ficam em silêncio. O alerta reforçado combina o som nativo (SoundKit 23287) com um toque original mais audível. O menu também oferece o proc nativo sozinho. Os alertas usam o canal principal do WoW.

Os Ecos de Comando, Retidão, Sabedoria, Luz, Justiça e Fúria têm alertas independentes. O Eco fica visível até ser consumido ou expirar. Ao trocar o selo ativo, o contador continua mostrando o Eco que você armazenou.

O indicador usa o número nativo do Eco quando o jogo permite exibi-lo. Se os dados da aura estiverem protegidos, as marcações e os alertas podem ser estimados a partir de atualizações do Eco e de acertos físicos. Golpes extras, múltiplos atacantes ou a falta desses eventos podem afetar a estimativa.

## Atualização 0.3.2

O número e as barras usam a aura nativa do WoW quando disponível. Se o AlexIra ainda não tiver identificado o selo, a leitura nativa pode aparecer como **Ira Desatada**. Os sons continuam seguindo os dados de combate que o addon consegue ler. O rastreamento também continua aguardando o acerto físico quando uma esquiva, um aparo ou um erro de Golpe Sagrado ou Julgamento chega junto do ataque branco.

## Atualizações 0.3.0 e 0.3.1

O contador acompanha a aplicação e a renovação de cada Eco mesmo quando o número de stacks está protegido. A troca de selo preserva a contagem do Eco antigo até o consumo e inicia o novo Eco assim que ele aparece. O modo **Simples** mostra ícone, número e duração. O **Relicário** acende três pedras lado a lado, e o **Vitral Sagrado** acende três painéis de baixo para cima.

A versão 0.3.1 adiciona o comando curto `/alex` para abrir as configurações.

## Atualização 0.2.1

O contador lê a aura do Eco também no evento do golpe e processa acertos utilizáveis sem a espera adicional de 180 ms. Se o cliente ocultar a aura, a velocidade da estimativa depende dos eventos de combate que ele disponibiliza. O fundo cinza ganhou um controle de opacidade salvo por personagem.

## Atualização 0.2.0

Seis botões de selo deixam os três alertas de cada um acessíveis. A versão adiciona novas opções de som, efeitos originais e asas douradas ao indicador. As configurações da versão anterior são mantidas, com o reforço aplicado aos alertas que já usavam o proc.
