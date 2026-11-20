# AlexIra

Indicador de Ira Desatada para paladinos no World of Warcraft: Forever 1.60.1. Exibe o selo cujo Eco está armazenado, de um a três acúmulos, com barras coloridas e o tempo restante. A borda ganha a cor do selo ao chegar a três.

## Como usar

1. Coloque a pasta `AlexIra` em `_forever_/Interface/AddOns/` e reinicie o cliente se for a primeira instalação.
2. Abra `/alexira` ou selecione **AlexIra** no painel de complementos.
3. Escolha um selo e um som para cada acúmulo. Use **Testar** para ver o indicador e ouvir o som escolhido.
4. Marque **Mover indicador** para arrastá-lo. As escolhas e a posição são salvas por personagem.

Por padrão, o alerta de proc do Choque Sagrado toca ao atingir três acúmulos. Os dois primeiros ficam em silêncio. O addon usa o som nativo de alerta de proc da interface (SoundKit 23287).

Os Ecos de Comando, Retidão, Sabedoria, Luz, Justiça e Fúria têm alertas independentes. O Eco fica visível até ser consumido ou expirar. Ao trocar o selo ativo, o contador continua mostrando o Eco que você armazenou.

Se o cliente ocultar a contagem da aura em combate, o indicador exibe **Estimativa** quando conseguir associar o ataque corpo a corpo a um acerto físico no alvo. Nessa situação, golpes extras, múltiplos atacantes e eventos indisponíveis podem afetar a contagem e o momento do alerta.
