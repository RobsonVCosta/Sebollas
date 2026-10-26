# Sebollas

Jogo para MSX2 em Assembly Z80. A aventura começa a pé, com uma pescaria e o confronto com o garoto da garapa, e continua de Fusca até o bar e o confronto com o homem do queijo. Depois da vitória, Argon, Gordinho (Leto) e Robson correm para pegar o ônibus para Nova Iguaçu.

## Jogar

Carregue [Sebollas.rom](Sebollas.rom), cartucho **ASCII8 de 512 KiB**, em um MSX2 ou superior. O [WebMSX](https://webmsx.org/) detecta o mapper automaticamente; se houver uma escolha antiga salva, selecione ASCII8.

```sh
openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -romtype ASCII8
```

| Comando | Ação |
| --- | --- |
| Setas | Movem o trio ou o Fusca dentro da área transitável. |
| Cima/Baixo na abertura | Seleciona Play ou Continue. |
| Espaço/Enter na abertura | Confirma a opção selecionada. |
| Espaço nas duas primeiras fases | Lança canas para cima, inclusive durante os percursos. 12 acertos neutralizam o garoto da garapa; cada burro precisa de três acertos. |
| Espaço nas fases de carro | Buzina; afasta as vacas comuns e atinge o chefe final. |
| Espaço/Enter em GAME OVER ou nos créditos | Retorna à abertura. Solte antes de iniciar novamente. |

Continue aparece abaixo de Play depois de começar uma partida. Ele reinicia a fase atual com cinco vidas e a pontuação do início dessa fase, sem repetir a introdução da história. A opção fica disponível enquanto a ROM está ligada. Play começa uma nova aventura.

Após o Play, uma introdução conta a história de 1991, com a mesma fonte e escrita letra a letra dos créditos. Cada caractere produz um breve estalo de máquina de escrever. O texto completo permanece cinco segundos antes do cartão “Indo pescar”.

Há **cinco corações vermelhos**, juntos no canto superior direito. O jogo começa com cinco vidas. As vidas restantes são mantidas entre as fases, no desafio das canas e na luta final. Uma batida retira uma vida e concede dois segundos de invulnerabilidade. Encostar na borda da estrada não tira vida. GAME OVER aparece no centro do gameplay.

As telas de nome duram dois segundos e são seguidas pela imagem da etapa por cinco segundos. Não há consumo nem obstáculos durante as imagens. Todos os gameplays, inclusive os encontros, esperam pelo primeiro movimento nas setas ou no joystick. Espaço sozinho não inicia o percurso.

## As quatro etapas

| Etapa | Personagem e objetivo |
| --- | --- |
| **Indo pescar** | O trio da referência sai de uma casa sem o nome Vavá. Segue por uma estrada sinuosa com pontes, desvia dos burros e recupera a barra FOME nos decks PESCA. O garoto da garapa entra pelo topo e acompanha o scroll até o ponto de encontro. A etapa termina ao encostar nele; ele não ataca e não aparece um título sobre o encontro. A pista é mais larga nesta etapa. |
| **Garapa??** | Continua a pé. No encontro, o garoto pergunta **“Vocês tomam garapa?”**. Use espaço para lançar canas para cima: 12 acertos neutralizam o garoto, que pisca antes do bônus. Cada burro exige três acertos de cana e vale 100 pontos ao ser eliminado. Há um projétil do jogador por vez; segurar espaço repete os lançamentos. As canas lançadas pelo garoto tiram uma vida ao atingir o trio e respeitam a invulnerabilidade após uma batida; não são itens de coleta. Há no máximo um burro na batalha; ele não atira bolinhas durante esse confronto. O deck continua disponível durante a luta. |
| **Fase 2** | Usa o Fusca, gasolina e postos. A estrada é sinuosa, com pontes, e termina em um **bar** centralizado, com a pista afunilando até sua entrada, sem passagem pelas laterais. A tela de nome mostra **“Vovó!!!”**. Há uma pausa de chegada e bônus. Não há luta nessa etapa. |
| **Fase final** | Mantém a estrada estreita, mais vacas e o homem do queijo. Ele lança queijos quadrados; desvie e acerte 12 buzinadas. Depois pisca e foge. |

Nas etapas a pé não há buzina. Um burro atravessa a estrada por vez. Quando o grupo chega perto, ele inicia uma perseguição que continua até ser eliminado ou a etapa terminar. Os acertos de cana são acumulados individualmente por burro e reiniciam quando nasce outro. O trio é mais ágil que o perseguidor. Durante a luta, um único burro atravessa e persegue na horizontal, a um pixel por tick, o dobro da velocidade da pescaria.

Nas etapas de carro as vacas ficam paradas até ouvir a buzina. Na fase final podem aparecer três simultaneamente, e uma em cada quatro ignora a buzina, deixando uma passagem pela direita.

As barras FOME e GAS têm as laterais fechadas, sem letras E/F. Vão de 0 a 100 e gastam uma unidade a cada 12 ticks, cerca de 24 segundos por barra. Encoste nos decks ou postos para recuperar a barra automaticamente. Os dois pontos da estrada pausam o scroll durante a recuperação. Nos encontros há outro ponto no canto inferior direito, sem pausar o combate. A barra vazia encerra a partida; abaixo de 21 unidades há alerta visual e sonoro.

As etapas a pé não mostram contador de canas. **QUEIJOS** aparece nas fases de carro, alinhado à direita. O queijo redondo tem uma borda clara, lateral amarela e furos escuros; seus dois tons e o fundo transparente se mantêm nas fases. Os queijos ficam parados em pontos alternados das laterais da estrada; só descem junto com o cenário, sem rolar, perseguir o carro ou se mover durante o abastecimento. A tela do bônus diz **“Fase concluída”**, sem numeração. As coletas viram bônus ao fim da etapa: o contador diminui, o placar sobe 100 pontos por item e toca um som. O encontro pacífico da pescaria segue diretamente para a Fase 1.

A paisagem usa árvores de copa maior, arbustos, flores, pequenas plantações e vegetação nas margens do rio. A estrada tem pedras cinzentas maiores espalhadas, substituindo as antigas marcas pretas.

## Som e encerramento

A música de estrada é a redução para dois canais da partitura fornecida em `resources/sultans-sheet-reference.png`: 14 compassos de *Sultans of Swing*, em 4/4 a 148 BPM, formando um loop de 22,70 segundos. O canal C toca a nota superior da mão direita e o canal A toca a linha de baixo da mão esquerda, reduzindo as oitavas a uma nota. Pausas, ligaduras, tercinas e a pequena nota de ornamento estão transcritas em `resources/sultans-score.json`. `make music` converte as posições em batidas para eventos PSG. Os efeitos continuam tendo prioridade e os encontros com inimigos mantêm a música dramática.

Depois da derrota do homem do queijo, o bônus final inicia *Going Home Wild Theme*, da partitura fornecida em `resources/going-home-sheet-reference.pdf`. O arranjo dos 87 compassos usa os três canais do PSG: A para o baixo, B para a voz interna e C para a melodia. A redução está em `resources/going-home-score.json`, a 112 BPM (40% mais rápida que os 80 BPM da partitura), com pausas, ligaduras e tercinas; acordes de piano são reduzidos a notas individuais e ornamentos a suas notas principais. Os compassos curtos de transição mantêm sua duração escrita; as fermatas usam a duração da nota. A música dura aproximadamente 2min58s, toca uma única vez e continua sem reiniciar nas duas imagens finais, na cena do ônibus e nos créditos. Os sons de contagem do bônus ocupam temporariamente seus canais, enquanto as outras vozes e o andamento continuam. `make music` também gera esse arranjo, armazenado no banco ASCII8 6.

A buzina foi ajustada a `resources/horn-reference.ogg`: corpo perto de 338 Hz, brilho metálico perto de 3,1 kHz, pequenas variações de altura e entrada/saída suaves. Mantém o “bi” de 120 ms, a pausa de 80 ms e o “biiii” de 640 ms. [Ouvir a saída real do PSG](previews/buzina-msx.ogg), gravada com `tests/capture_horn.tcl`.

Após a vitória final e o bônus, `ending-1-reference` e `ending-2-reference` aparecem em sequência, cinco segundos cada, com música de fundo. Em seguida, o Fusca estaciona e os três amigos saem; após dois segundos, o ônibus passa pela esquerda e eles correm atrás dele. Então os créditos surgem letra a letra, a 25 caracteres por segundo:

> Essa foi a aventura de Argon, Gordinho (Leto) e Robson em sua jornada de Nova Iguaçu até Sebollas.
>
> Obrigado amigos, pelas boas memórias.
>
> By Robson Velloso

## Montagem e validação

Necessário: SjASMPlus. Python 3 e Pillow são usados para recriar os recursos e prévias; não são necessários para executar a ROM. Validação com SjASMPlus 1.21.0 e openMSX com C-BIOS MSX2.

```sh
make                  # monta a ROM e os símbolos
make assets           # recria sprites, mapas e imagens de 256 cores
make previews         # recria prévias estáticas
make test             # montagem e 20 testes Python
make test-emulator    # 412 rotinas Z80, música completa e campanha em 50/60 Hz
make captures         # capturas reais do V9938
```

O teste de campanha usa somente teclado, sem modificar vida, barra, posição ou resistência do chefe. Confere as quatro etapas, 12 acertos de cana no garoto da garapa, encontros pacíficos na pescaria e no bar, 12 acertos no chefe final, bônus, corrida atrás do ônibus, imagens finais e créditos. Também verifica as quatro introduções de 250 ticks, a área transitável e zero quadros com excesso de sprites. O teste do percurso isola fome e decks das batidas.

O teste opcional do WebMSX precisa de Node.js 18+, Chrome e `playwright-core`:

```sh
npm install --prefix /tmp/sebollas-webmsx-test playwright-core
NODE_PATH=/tmp/sebollas-webmsx-test/node_modules node tests/webmsx_smoke.cjs
```

Use `CHROME_PATH` se o navegador estiver fora de `/usr/bin/google-chrome`. O teste carrega a ROM sem dica de mapper em MSX2+ de 50 e 60 Hz, usa o teclado e pontos de verificação para capturar as quatro etapas, as perseguições, os decks, o combate com canas, o bar e a luta final. As capturas ficam em `previews/*-webmsx-MSX2P*.png`.

## Organização e limites do MSX2

| Arquivo | Uso |
| --- | --- |
| `Sebollas.asm` | Inicialização, loop, movimento, colisões, HUD e composição de sprites. |
| `walking.asm` | Trio, perseguições, encontro pacífico, combate com canas e chegada ao bar. |
| `campaign.asm`, `bonus.asm` | Transições, chefe final, bônus, ônibus e créditos. |
| `route.asm` | Mapas, limites transitáveis, FOME/GAS, decks e postos. |
| `ending_art.asm`, `title.asm` | Abertura e imagens antes das fases e dos créditos. |
| `music.asm`, `sfx.inc` | Música e efeitos no PSG. |
| `tools/build_assets.py`, `tools/build_ending.py` | Conversão determinística das referências para recursos nativos. |
| `resources/*-reference.png` | Imagens fornecidas para os sprites e cenas. |

A abertura usa SCREEN 5, 256×212 e 16 cores. O gameplay usa SCREEN 4, 256×192. As quatro introduções e as duas imagens finais usam SCREEN 8, 256×212 e 256 cores fixas GRB332.

O cartucho tem 64 bancos de 8 KiB. Os bancos 0/1 permanecem em 4000–7FFF para código e dados fixos. As janelas 8000–BFFF recebem recursos, imagens ou mapas. Os mapas 0–3 ocupam os bancos 48–51 e são copiados para RAM **D000–E5DF** antes de cada etapa: 5120 bytes de tiles, 160 centros da pista e 320 limites laterais. As variáveis e buffers de sprites usam C000–C6FF. A imagem da pescaria está no banco 56; as outras introduções nos bancos 24/32/40, e as imagens finais nos bancos 8/16.

Há 64 padrões de sprite de 16×16, exatamente 2048 bytes. O trio reutiliza os primeiros oito slots; o Fusca usa seis deles. O homem do queijo e o queijo lançado reutilizam os slots do garoto da garapa e da cana durante a luta final. Duas máscaras por quadrante, com combinação CC, preservam até três cores por linha. No percurso a pé há um burro de 32×32 ativo. Durante o confronto com o garoto da garapa, há no máximo um burro do mesmo tamanho; o garoto e as canas usam tiles de cenário para reservar os 32 slots ao trio e aos burros. O trio mantém a pose original fixa, sem animação dos pés, nos mesmos oito slots de VRAM. Sua colisão considera a parte inferior do corpo. O jogador pode descer até Y=160, junto à borda inferior. A pescaria avança um tile a cada 16 ticks; Garapa??, a cada 14 ticks (cerca de 14% mais rápido); de carro, a cada oito ticks. As fases de carro mantêm até 32 sprites e oito por linha. Os três corredores da cena do ônibus usam a referência lateral `resources/runners-reference.png`, com o fundo branco removido e dois quadros de passada. O glifo de interrogação é definido em `QuestionMarkGlyph`, em `string.asm`, e gerado no código ASCII 63 dos tiles.

A lógica é normalizada a 50 ticks por segundo; em vídeo de 60 Hz, um de cada seis VBlanks não avança a lógica. Testes de áudio verificam os registradores do PSG e as prioridades; não houve avaliação em hardware físico.

## Sprite do burro

O burro substitui os cachorros nas duas etapas a pé, com o mesmo tamanho de 32×32 e as mesmas regras de travessia e perseguição. O gameplay usa o trio original com os pés parados.

O sprite foi gerado com `imagegen` e convertido à paleta e aos padrões nativos do MSX2. A referência transparente está em `resources/donkey-reference.png`, a prévia convertida em `previews/donkey-0-8x.png` e o prompt em `resources/donkey-prompt.json`. As antigas ROMs nomeadas `Sebollas-cachorro-*.rom` são versões anteriores; a versão atual é `Sebollas.rom`.

O homem do queijo lança dois queijos simultâneos em trajetórias separadas. Cada um tem colisão e movimento próprios, respeitando o limite de oito sprites por linha.

Na estrada que leva ao desafio das canas, o último passo do scroll abre automaticamente a arena, em qualquer posição dos garotos na pista. Não é preciso subir até o topo.

“Indo pescar” tem 108 passos de scroll, cerca de 22% menos que o percurso anterior de 138. Os dois decks, as duas pontes, a casa inicial e o encontro com o garoto da garapa foram preservados.

As pedras usam a opção 2 aprovada, com quatro tamanhos de lascas irregulares. A introdução e os créditos mantêm a fonte de 8 pixels, com três pixels extras entre as linhas (passo de 11 pixels nas linhas consecutivas).

As sombras das pedras usam marrom escuro (RGB de 3 bits: 2, 1, 0), em vez de preto.

A prévia em [previews/sultans-msx.ogg](previews/sultans-msx.ogg) foi gravada do PSG da ROM no openMSX, com o roteiro `tests/capture_music.tcl`.

As canas usam composição de tiles para preservar o cenário fora do desenho, sem fundo opaco e sem exceder oito sprites por linha. O garoto pacífico da pescaria também usa tiles no mapa, permitindo que o burro continue perseguindo até o encontro sem ocultar personagens.

Nos percursos das duas etapas a pé, cada burro lança uma bolinha preta pela traseira, mirando a posição do jogador no momento do disparo. A trajetória segue nessa direção, inclusive na vertical e nas diagonais. Há um projétil por burro, com intervalo entre lançamentos. As bolinhas se movem independentemente do scroll, preservam o cenário ao redor e tiram uma vida ao acertar o trio, respeitando a invulnerabilidade.

O homem do queijo passa de dois para três queijos por lançamento quando restam três pontos de vida ou menos (dos 12 iniciais). Os três saem juntos, com o central um pouco à frente para preservar a visibilidade de todos os sprites.

O cartão da fase final mostra “O homem do queijo” abaixo de “FASE FINAL”.

Na chegada da fase final, o cenário continua rolando até a entrada do homem do queijo alcançar o carro, sem exigir que o jogador suba na tela. A batalha com o homem do queijo não tem vacas. O canal de baixo ganhou volume na estrada e no encerramento.

Na tela de PLAY, digitar **1914** revela a seleção horizontal **1 2 3 4 5 6 7**. Use esquerda/direita e confirme com Enter ou Espaço: **1** começo, **2** fase Garapa, **3** batalha com o garoto da garapa, **4** estrada até o bar, **5** fase final, **6** batalha com o homem do queijo, **7** encerramento. Cada atalho começa com cinco vidas e pontuação zerada.

O frame skip adaptativo monitora os VBlanks durante as fases e batalhas. Se uma atualização atrasar, o próximo tick pode omitir a cópia dos sprites e do HUD para a VRAM; podem ser pulados até três envios gráficos consecutivos, mas o quarto sempre é desenhado. O HUD pendente é enviado no próximo quadro desenhado. Controles, movimento, colisões, projéteis, scroll e música continuam sendo processados. A composição dos sprites permanece ativa em memória. Menus, mudanças de tela e cenas finais desenham normalmente, e a adaptação de 60 Hz para 50 ticks não é confundida com lentidão. Esse recurso reduz o custo de transferência gráfica; não compensa atrasos causados pelo próprio cálculo do jogo.
