# AlexIra

Indicador de Ira Desatada para paladinos no World of Warcraft: Forever 1.60.1. Mostra o selo cujo Eco está armazenado, de um a três acúmulos, com o tempo restante. As asas douradas brilham ao chegar a três.

## Como usar

1. Coloque a pasta `AlexIra` em `_forever_/Interface/AddOns/` e reinicie o cliente para carregar a versão, as texturas e os sons.
2. Abra `/alex` ou selecione **AlexIra** no painel de complementos. O atalho `/alexira` também abre o menu.
3. Clique no selo que quer configurar. Cada selo tem três menus de som independentes, um por acúmulo. Escolha entre 30 opções de som, com efeitos do jogo e sons como **Pato de borracha**, **Buzina de palhaço** e **Boing**, ou ative **Sem som**. Use **Testar** na linha de um acúmulo para ouvir a escolha e ver aquele estado do indicador.
4. Marque **Mover indicador** para arrastá-lo. As escolhas e a posição são salvas por personagem.
5. Em **Estilo do indicador**, escolha **Asas Douradas**, **Simples**, **Relicário**, **Vitral Sagrado**, **Fênix Dourada** ou **Martelo da Aurora**. Ajuste **Opacidade do fundo** de **1** (mais transparente) a **10** (opaco). O fundo cinza começa em **6**. O menu mostra uma prévia silenciosa ao mudar a aparência fora de uma contagem ativa.
6. A barra **Ataque branco** pisca quando o jogo registra seu ataque de mão principal, mesmo sem um Eco ativo. Ela mostra a previsão do próximo ataque e ajusta o tempo quando a velocidade da arma muda. Para ocultá-la, desmarque **Mostrar timer de ataque branco** em `/alex`.
7. Para conferir as stacks, marque **Mostrar buff nativo** fora de combate em `/alex`. O ícone do Eco e a contagem desenhada pelo jogo aparecem no alto da tela quando o buff está ativo e o cliente oferece esse visor.

Por padrão, o alerta de proc do Choque Sagrado toca ao atingir três acúmulos. Os dois primeiros ficam em silêncio. O alerta reforçado combina o som nativo (SoundKit 23287) com um toque original mais audível. O menu também oferece o proc nativo sozinho. Os alertas usam o canal principal do WoW.

Os Ecos de Comando, Retidão, Sabedoria, Luz, Justiça e Fúria têm alertas independentes. O Eco fica visível até ser consumido ou expirar. Ao trocar o selo ativo, o contador continua mostrando o Eco que você armazenou.

O indicador prioriza o número do Eco no personagem. Se o cliente proteger o número mas permitir exibi-lo, o número do buff aparece no indicador. Quando nenhum número do buff estiver disponível, o indicador usa **Estimativa**. O som de 3 stacks toca assim que o buff confirma o terceiro acúmulo ou assim que a projeção chega a três quando o Lua não pode ler a contagem. Nesse caso, uma esquiva ou um erro pode fazer o som tocar cedo.

## Atualização 0.4.0

O AlexIra prioriza a aura do jogador e também procura o Eco na lista de buffs. O alerta de três acúmulos perdou a espera adicional da estimativa. **Fênix Dourada** e **Martelo da Aurora** adicionam dois indicadores ilustrados.

## Atualização 0.3.5

O timer de ataque branco usa o evento do próprio jogador. O piscar indica a tentativa do ataque, que ainda pode errar ou ser aparada. Compare esse sinal com a aura do Eco para investigar diferenças na contagem em grupo.

## Atualização 0.3.4

Em grupo, dungeon ou raide, a contagem usa os eventos dos seus ataques brancos e da sua aura do Eco. O resultado de dano do alvo vem sem o nome do atacante e foi retirado desse cálculo. Quando a aura estiver protegida, o indicador segue em **Estimativa**, inclusive se um ataque seu errar.

## Atualização 0.3.3

O contador projeta as stacks a partir dos próprios ataques brancos, inclusive quando o alvo morre ou muda antes da resposta. A contagem é ajustada se a aura atualizada ou um erro inequívoco do golpe chegar depois. Leituras repetidas de um Eco antigo deixam a estimativa em andamento. Uma esquiva ou um aparo de Golpe Sagrado ou Julgamento pode aparecer junto do ataque branco, então a confirmação mantém os dois eventos separados.

## Atualizações 0.3.0 e 0.3.1

O contador acompanha a aplicação e a renovação de cada Eco mesmo quando o número de stacks está protegido. A troca de selo preserva a contagem do Eco antigo até o consumo e inicia o novo Eco assim que ele aparece. O modo **Simples** mostra ícone, número e duração. O **Relicário** acende três pedras lado a lado, e o **Vitral Sagrado** acende três painéis de baixo para cima.

A versão 0.3.1 adiciona o comando curto `/alex` para abrir as configurações.

## Atualização 0.2.1

O contador lê a aura do Eco também no evento do golpe e processa acertos utilizáveis sem a espera adicional de 180 ms. Se o cliente ocultar a aura, a velocidade da estimativa depende dos eventos de combate que ele disponibiliza. O fundo cinza ganhou um controle de opacidade salvo por personagem.

## Atualização 0.2.0

Seis botões de selo deixam os três alertas de cada um acessíveis. A versão adiciona novas opções de som, efeitos originais e asas douradas ao indicador. As configurações da versão anterior são mantidas, com o reforço aplicado aos alertas que já usavam o proc.
