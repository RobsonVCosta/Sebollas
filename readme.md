# Sebollas

Jogo para MSX2 em Assembly Z80. A aventura começa a pé, com uma pescaria e a coleta de canas, e continua de Fusca até o bar e o confronto com o homem do queijo. Depois da vitória, Argon, Gordinho (Leto) e Robson correm para pegar o ônibus para Nova Iguaçu.

## Jogar

Carregue [Sebollas.rom](Sebollas.rom), cartucho **ASCII8 de 512 KiB**, em um MSX2 ou superior. O [WebMSX](https://webmsx.org/) detecta o mapper automaticamente; se houver uma escolha antiga salva, selecione ASCII8.

```sh
openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom -romtype ASCII8
```

| Comando | Ação |
| --- | --- |
| Setas | Movem o trio ou o Fusca dentro da área transitável. |
| Espaço/Enter na abertura | Inicia a aventura. |
| Espaço nas fases de carro | Buzina; afasta as vacas comuns e atinge o chefe final. |
| Espaço/Enter em GAME OVER ou nos créditos | Retorna à abertura. Solte antes de iniciar novamente. |

Após o Play, uma introdução conta a história de 1991, com a mesma fonte e escrita letra a letra dos créditos. Cada caractere produz um breve estalo de máquina de escrever. O texto completo permanece cinco segundos antes do cartão “Indo pescar”.

Há **cinco corações vermelhos**, juntos no canto superior direito. O jogo começa com cinco vidas. As vidas restantes são mantidas entre as fases, no desafio das canas e na luta final. Uma batida retira uma vida e concede dois segundos de invulnerabilidade. Encostar na borda da estrada não tira vida. GAME OVER aparece no centro do gameplay.

As telas de nome duram dois segundos e são seguidas pela imagem da etapa por cinco segundos. Não há consumo nem obstáculos durante as imagens. Todos os gameplays, inclusive os encontros, esperam pelo primeiro movimento nas setas ou no joystick. Espaço sozinho não inicia o percurso.

## As quatro etapas

| Etapa | Personagem e objetivo |
| --- | --- |
| **Indo pescar** | O trio da referência sai de uma casa sem o nome Vavá. Segue por uma estrada sinuosa com pontes, desvia dos burros e recupera a barra FOME nos decks PESCA. O garoto da garapa entra pelo topo e acompanha o scroll até o ponto de encontro. A etapa termina ao encostar nele; ele não ataca e não aparece um título sobre o encontro. A pista é mais larga nesta etapa. |
| **Fase 1** | Continua a pé. No encontro com o garoto aparece **“Vocês tomam garapa?”**. Colete **30 canas** enquanto foge dos burros de 32×32, na arena ampliada. A fala alterna com **“Levem cana pra casa”**. A quantidade de burros aumenta de uma para duas após 1000 ticks e para três após 2000 ticks de jogo, sem limite de tempo. As canas são coletáveis e não tiram vida; o trio não causa dano ao garoto. Os decks continuam disponíveis durante o encontro. |
| **Fase 2** | Usa o Fusca, gasolina e postos. A estrada é sinuosa, com pontes, e termina em um **bar** centralizado, com a pista afunilando até sua entrada, sem passagem pelas laterais. A tela de nome mostra **“Vovó!!!”** e, após duas linhas em branco, **“Buzine para espantar as vacas”**. Há uma pausa de chegada e bônus. Não há luta nessa etapa. |
| **Fase final** | Mantém a estrada estreita, mais vacas e o homem do queijo. Ele lança queijos quadrados; desvie e acerte 12 buzinadas. Depois pisca e foge. |

Nas etapas a pé não há buzina. Um burro atravessa a estrada por vez. Quando o grupo chega perto, ele persegue por **cinco segundos medidos pelo relógio do BIOS** (250 VBlanks em 50 Hz ou 300 em 60 Hz), e depois volta a atravessar e desiste; o mesmo burro não reinicia a perseguição. O trio é mais ágil que o burro perseguidor. Durante o desafio das canas, até três burros cruzam faixas separadas, perseguindo o grupo na horizontal por cinco segundos. Nesse desafio, a velocidade horizontal dos burros é de um pixel por tick, o dobro da velocidade da pescaria.

Nas etapas de carro as vacas ficam paradas até ouvir a buzina. Na fase final podem aparecer três simultaneamente, e uma em cada quatro ignora a buzina, deixando uma passagem pela direita.

As barras FOME e GAS têm as laterais fechadas, sem letras E/F. Vão de 0 a 100 e gastam uma unidade a cada 12 ticks, cerca de 24 segundos por barra. Encoste nos decks ou postos para recuperar a barra automaticamente. Os dois pontos da estrada pausam o scroll durante a recuperação. Nos encontros há outro ponto no canto inferior direito, sem pausar o inimigo ou a coleta. A barra vazia encerra a partida; abaixo de 21 unidades há alerta visual e sonoro.

O contador **CANAS** aparece na Fase 1; **QUEIJOS** aparece nas fases de carro, alinhado à direita. O queijo redondo tem uma borda clara, lateral amarela e furos que mudam ao rolar; seus dois tons e o fundo transparente se mantêm nas fases. A tela do bônus diz **“Fase concluída”**, sem numeração. As coletas viram bônus ao fim da etapa: o contador diminui, o placar sobe 100 pontos por item e toca um som. O encontro pacífico da pescaria segue diretamente para a Fase 1.

A paisagem usa árvores de copa maior, arbustos, flores, pequenas plantações e vegetação nas margens do rio. A estrada tem pedras cinzentas maiores espalhadas, substituindo as antigas marcas pretas.

## Som e encerramento

A música de estrada usa o canal C do PSG. Nos encontros com inimigos, muda para arpejos mais rápidos em dó menor. Na luta final ela continua durante a buzina dos canais A/B; alertas de prioridade podem interrompê-la.

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
make test             # montagem e 16 testes Python
make test-emulator    # 266 rotinas Z80 e campanha completa em 50/60 Hz
make captures         # capturas reais do V9938
```

O teste de campanha usa somente teclado, sem modificar vida, barra, posição ou resistência do chefe. Confere as quatro etapas, coleta das 30 canas e crescimento da manada, encontros pacíficos na pescaria e no bar, 12 acertos no chefe final, bônus, corrida atrás do ônibus, imagens finais e créditos. Também verifica as quatro introduções de 250 ticks, a área transitável e zero quadros com excesso de sprites. O teste do percurso isola fome e decks das batidas.

O teste opcional do WebMSX precisa de Node.js 18+, Chrome e `playwright-core`:

```sh
npm install --prefix /tmp/sebollas-webmsx-test playwright-core
NODE_PATH=/tmp/sebollas-webmsx-test/node_modules node tests/webmsx_smoke.cjs
```

Use `CHROME_PATH` se o navegador estiver fora de `/usr/bin/google-chrome`. O teste carrega a ROM sem dica de mapper em MSX2+ de 50 e 60 Hz, usa o teclado e pontos de verificação para capturar as quatro etapas, as perseguições, os decks, a coleta, o bar e a luta final. As capturas ficam em `previews/*-webmsx-MSX2P*.png`.

## Organização e limites do MSX2

| Arquivo | Uso |
| --- | --- |
| `Sebollas.asm` | Inicialização, loop, movimento, colisões, HUD e composição de sprites. |
| `walking.asm` | Trio, perseguições, encontro pacífico, coleta de canas e chegada ao bar. |
| `campaign.asm`, `bonus.asm` | Transições, chefe final, bônus, ônibus e créditos. |
| `route.asm` | Mapas, limites transitáveis, FOME/GAS, decks e postos. |
| `ending_art.asm`, `title.asm` | Abertura e imagens antes das fases e dos créditos. |
| `music.asm`, `sfx.inc` | Música e efeitos no PSG. |
| `tools/build_assets.py`, `tools/build_ending.py` | Conversão determinística das referências para recursos nativos. |
| `resources/*-reference.png` | Imagens fornecidas para os sprites e cenas. |

A abertura usa SCREEN 5, 256×212 e 16 cores. O gameplay usa SCREEN 4, 256×192. As quatro introduções e as duas imagens finais usam SCREEN 8, 256×212 e 256 cores fixas GRB332.

O cartucho tem 64 bancos de 8 KiB. Os bancos 0/1 permanecem em 4000–7FFF para código e dados fixos. As janelas 8000–BFFF recebem recursos, imagens ou mapas. Os mapas 0–3 ocupam os bancos 48–51 e são copiados para RAM **D000–E5DF** antes de cada etapa: 5120 bytes de tiles, 160 centros da pista e 320 limites laterais. As variáveis e buffers de sprites usam C000–C6FF. A imagem da pescaria está no banco 56; as outras introduções nos bancos 24/32/40, e as imagens finais nos bancos 8/16.

Há 64 padrões de sprite de 16×16, exatamente 2048 bytes. O trio reutiliza os primeiros oito slots; o Fusca usa seis deles. O homem do queijo e o queijo lançado reutilizam os slots do garoto da garapa e da cana durante a luta final. Duas máscaras por quadrante, com combinação CC, preservam até três cores por linha. No percurso a pé há um burro de 32×32 ativo. Durante a coleta de canas, até três burros do mesmo tamanho usam faixas verticais separadas; o garoto e as canas usam tiles de cenário para reservar os 32 slots ao trio e aos burros. O trio mantém a pose original fixa, sem animação dos pés, nos mesmos oito slots de VRAM. Sua colisão considera a parte inferior do corpo. O jogador pode descer até Y=160, junto à borda inferior. As duas etapas a pé avançam um tile a cada 16 ticks; de carro, a cada oito ticks. As fases de carro mantêm até 32 sprites e oito por linha. Os três corredores da cena do ônibus usam a referência lateral `resources/runners-reference.png`, com o fundo branco removido e dois quadros de passada. O glifo de interrogação é definido em `QuestionMarkGlyph`, em `string.asm`, e gerado no código ASCII 63 dos tiles.

A lógica é normalizada a 50 ticks por segundo; em vídeo de 60 Hz, um de cada seis VBlanks não avança a lógica. Testes de áudio verificam os registradores do PSG e as prioridades; não houve avaliação em hardware físico.

## Sprite do burro

O burro substitui os cachorros nas duas etapas a pé, com o mesmo tamanho de 32×32 e as mesmas regras de travessia e perseguição. O gameplay usa o trio original com os pés parados.

O sprite foi gerado com `imagegen` e convertido à paleta e aos padrões nativos do MSX2. A referência transparente está em `resources/donkey-reference.png`, a prévia convertida em `previews/donkey-0-8x.png` e o prompt em `resources/donkey-prompt.json`. As antigas ROMs nomeadas `Sebollas-cachorro-*.rom` são versões anteriores; a versão atual é `Sebollas.rom`.

O homem do queijo lança dois queijos simultâneos em trajetórias separadas. Cada um tem colisão e movimento próprios, respeitando o limite de oito sprites por linha.
