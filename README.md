# AlexIra

Indicador de Ira Desatada para paladinos no World of Warcraft: Forever 1.60.1. Mostra o selo cujo Eco está armazenado, de um a três acúmulos, com o tempo restante. As asas douradas brilham ao chegar a três.

## Como usar

1. Coloque a pasta `AlexIra` em `_forever_/Interface/AddOns/` e reinicie o cliente para carregar a versão, as texturas e os sons.
2. Abra `/alex` ou selecione **AlexIra** no painel de complementos. O atalho `/alexira` também abre o menu.
3. Clique no selo que quer configurar. Cada selo tem três menus de som independentes, um por acúmulo. Escolha entre 30 opções de som, com efeitos do jogo e sons como **Pato de borracha**, **Buzina de palhaço** e **Boing**, ou ative **Sem som**. Use **Testar** na linha de um acúmulo para ouvir a escolha e ver aquele estado do indicador.
4. Marque **Mover indicador** para arrastá-lo. As escolhas e a posição são salvas por personagem.
5. Em **Estilo do indicador**, escolha um painel com texto ou um dos três estilos ilustrados descritos abaixo. Nos painéis, ajuste **Opacidade do fundo** de **1** (mais transparente) a **10** (opaco). Use os botões **Testar** para conferir a aparência de cada acúmulo.
6. A barra **Ataque branco** pisca quando o jogo registra seu ataque de mão principal, mesmo sem um Eco ativo. Ela mostra a previsão do próximo ataque e ajusta o tempo quando a velocidade da arma muda. No menu **Barra de ataque branco**, escolha **Acima** ou **Abaixo** do painel e a espessura **Grossa** ou **Fina**. Para ocultá-la, desmarque **Mostrar timer de ataque branco** em `/alex`.
7. **Buff nativo no indicador** vem ligado. O painel principal usa o mesmo visor do WoW que atualiza o ícone, as stacks e o tempo do Eco no jogador. Para ativar o ícone pequeno no alto da tela, marque **Mostrar buff separado** em `/alex`. As mudanças do visor nativo são aplicadas fora de combate.
8. **Som de 3 sem espera** escolhe se o som toca quando a estimativa chega a três ou aguarda a confirmação ou o fim da janela de verificação.
9. Em **Volume dos alertas**, ajuste de **0%** (mudo) a **100%**, em passos de 20%. O controle vale para todos os selos e para **Testar**, e fica salvo por personagem.

Por padrão, o alerta de proc do Choque Sagrado toca ao atingir três acúmulos. Os dois primeiros ficam em silêncio. O alerta reforçado combina o som nativo (SoundKit 23287) com um toque original mais audível. O menu também oferece o proc nativo sozinho. Os alertas usam o canal principal do WoW.

Os Ecos de Comando, Retidão, Sabedoria, Luz, Justiça e Fúria têm alertas independentes. O Eco fica visível até ser consumido ou expirar. Ao trocar o selo ativo, o contador continua mostrando o Eco que você armazenou.

O visor nativo mostra o Eco enquanto a aura estiver ativa, mesmo quando as stacks estão protegidas para o código do addon. Se o visor nativo estiver indisponível ou for desligado, o painel pode mostrar **Estimativa**. Os sons usam a leitura da aura quando disponível para o addon. Com **Som de 3 sem espera** ligado e a leitura protegida, uma esquiva ou um erro pode fazer o som tocar cedo.

## Atualização 0.5.0

Três estilos mostram as stacks só com arte e luz. Neles, o timer e o ícone separado ficam ocultos. Suas preferências desses dois visores são reaplicadas ao escolher um painel com texto.

- **Escudo Prismático** muda de cobre para azul e depois para dourado.
- **Farol Sagrado** começa tênue e ganha brilho e nitidez a cada stack.
- **Constelação do Juramento** acende uma estrela a cada stack.

Com **Buff nativo no indicador** ligado, o WoW controla as fases de luz a partir do Eco. Os alertas de som continuam configuráveis por selo e stack.

## Atualização 0.4.3

A barra de ataque branco aparece acima do indicador e está mais grossa. A posição e a espessura ficam salvas por personagem.

## Atualização 0.4.2

O AlexIra ganhou um controle próprio de volume em `/alex`. Os áudios incluídos no addon, como o reforço do proc, ficam mais altos em 100%. Os alertas continuam sujeitos ao volume principal do WoW.

## Atualização 0.4.1

Os seis estilos do indicador principal passam a usar a contagem nativa do buff, a mesma do ícone pequeno do AlexIra. O WoW atualiza o selo, as stacks e a duração pelo Eco do jogador.

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
