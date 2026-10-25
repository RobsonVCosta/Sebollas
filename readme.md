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

Há **cinco corações vermelhos**, juntos no canto superior direito. Cada fase começa com cinco vidas, e a luta final também restaura cinco. Uma batida retira uma vida e concede dois segundos de invulnerabilidade. Encostar na borda da estrada não tira vida. GAME OVER aparece no centro do gameplay.

As telas de nome duram dois segundos e são seguidas pela imagem da etapa por cinco segundos. Não há consumo nem obstáculos durante as imagens. A primeira etapa espera por uma seta ou um novo Espaço antes de começar a andar; as seguintes começam automaticamente.

## As quatro etapas

| Etapa | Personagem e objetivo |
| --- | --- |
| **Indo pescar** | O trio da referência sai de uma casa sem o nome Vavá. Segue por uma estrada sinuosa com pontes, desvia das vacas e recupera a barra FOME nos decks PESCA. Ao chegar, encontra o garoto da garapa, que não ataca. |
| **Fase 1** | Continua a pé. No encontro com o garoto aparece **“Vocês tomam garapa?”**. Durante 30 segundos, pegue suas canas enquanto foge das vacas. As canas são coletáveis e não tiram vida; o trio não causa dano ao garoto. Os decks continuam disponíveis durante o encontro. |
| **Fase 2** | Usa o Fusca, gasolina e postos. A estrada é sinuosa, com pontes, e termina em um **bar**, com uma pausa de chegada e bônus. Não há luta nessa etapa. |
| **Fase final** | Mantém a estrada estreita, mais vacas e o homem do queijo. Ele lança queijos quadrados; desvie e acerte 12 buzinadas. Depois pisca e foge. |

Nas etapas a pé não há buzina. Uma vaca atravessa a estrada por vez. Quando o grupo chega perto, ela persegue por **cinco segundos medidos pelo relógio do BIOS** (250 VBlanks em 50 Hz ou 300 em 60 Hz), e depois volta a atravessar e desiste; a mesma vaca não reinicia a perseguição. O trio é mais ágil que a vaca perseguidora.

Nas etapas de carro as vacas ficam paradas até ouvir a buzina. Na fase final podem aparecer três simultaneamente, e uma em cada quatro ignora a buzina, deixando uma passagem pela direita.

FOME e GAS vão de 0 a 100 e gastam uma unidade a cada 12 ticks, cerca de 24 segundos por barra. Encoste nos decks ou postos para recuperar a barra automaticamente. Os dois pontos da estrada pausam o scroll durante a recuperação. Nos encontros há outro ponto no canto inferior direito, sem pausar o inimigo ou o tempo da coleta. A barra vazia encerra a partida; abaixo de 21 unidades há alerta visual e sonoro.

O contador **CANAS** aparece na Fase 1; **QUEIJOS** aparece nas fases de carro, alinhado à direita. O queijo mantém o mesmo amarelo. As coletas viram bônus ao fim da etapa: o contador diminui, o placar sobe 100 pontos por item e toca um som. O encontro pacífico da pescaria segue diretamente para a Fase 1.

## Som e encerramento

A música de estrada usa o canal C do PSG. Nos encontros com inimigos, muda para arpejos mais rápidos em dó menor. Na luta final ela continua durante a buzina dos canais A/B; alertas de prioridade podem interrompê-la.

A buzina foi ajustada a `resources/horn-reference.ogg`: corpo perto de 338 Hz, brilho metálico perto de 3,1 kHz, pequenas variações de altura e entrada/saída suaves. Mantém o “bi” de 120 ms, a pausa de 80 ms e o “biiii” de 640 ms. [Ouvir a saída real do PSG](previews/buzina-msx.ogg), gravada com `tests/capture_horn.tcl`.

Após a vitória final, o carro estaciona e os três amigos saem, esperam dois segundos, veem o ônibus entrar pela esquerda e passam a correr atrás dele. As duas imagens finais aparecem por cinco segundos cada; depois os créditos surgem letra a letra, com a fonte do projeto, a 25 caracteres por segundo:

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
make test-emulator    # 212 rotinas Z80 e campanha completa em 50/60 Hz
make captures         # capturas reais do V9938
```

O teste de campanha usa somente teclado, sem modificar vida, barra, posição ou resistência do chefe. Confere as quatro etapas, coleta de canas durante os 1500 ticks, encontros pacíficos na pescaria e no bar, 12 acertos no chefe final, bônus, corrida atrás do ônibus, imagens finais e créditos. Também verifica as quatro introduções de 250 ticks, a área transitável e zero quadros com excesso de sprites. O teste do percurso isola fome e decks das batidas.

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

Há 64 padrões de sprite de 16×16, exatamente 2048 bytes. O trio reutiliza os primeiros oito slots; o Fusca usa seis deles. O homem do queijo e o queijo lançado reutilizam os slots do garoto da garapa e da cana durante a luta final. Duas máscaras por quadrante, com combinação CC, preservam até três cores por linha. Nas etapas a pé há apenas uma vaca ativa, e uma cana pode ficar oculta atrás do conjunto de personagens quando a linha já usa os oito slots do V9938; a coleta continua funcionando. As fases de carro mantêm até 32 sprites e oito por linha. Os três corredores da cena do ônibus usam a referência lateral `resources/runners-reference.png`, com o fundo branco removido e dois quadros de passada. O glifo de interrogação é definido em `QuestionMarkGlyph`, em `string.asm`, e gerado no código ASCII 63 dos tiles.

A lógica é normalizada a 50 ticks por segundo; em vídeo de 60 Hz, um de cada seis VBlanks não avança a lógica. Testes de áudio verificam os registradores do PSG e as prioridades; não houve avaliação em hardware físico.
