# Sebollas

Jogo de estrada rural para **MSX2**, escrito em **Assembly Z80**. Saia da casa do Vavá e leve o Fusquinha amarelo até a casa de destino. A estrada de terra tem trechos estreitos, duas pontes sobre rios e dois postos de combustível. Desvie das vaquinhas e use os tiros para espantá-las até a margem.

A ROM usa **SCREEN 4, 256 × 192 pixels**, gráficos em tiles, sprites coloridos sobrepostos e áudio PSG. A abertura e os textos reutilizam os desenhos da fonte do projeto original.

![Gameplay capturado no openMSX](previews/gameplay-openmsx-4x.png)

## Jogar

Requisitos: MSX2 ou superior, ou emulador com BIOS compatível. Não funciona como jogo no MSX1; nesse modelo, a ROM apresenta a mensagem de que requer MSX2.

A imagem [Sebollas.rom](Sebollas.rom) é um cartucho simples de **16 KiB**, com cabeçalho `AB` e origem em `0x4000`.

```sh
openmsx -machine C-BIOS_MSX2 -cart Sebollas.rom
```

Também é possível carregar a ROM pela interface de outro emulador ou por um carregador de cartuchos compatível.

| Controle | Ação |
| --- | --- |
| Espaço ou Enter, na abertura | Inicia `PLAY`. |
| Setas | Move o Fusca em oito direções, com limites laterais da área de jogo. |
| Espaço, na partida | Dispara; pode ser mantido pressionado. |
| Espaço ou Enter, em GAME OVER ou na chegada | Retorna à abertura. Solte a tecla antes de iniciar novamente. |

O jogo lê o teclado pela BIOS. Joystick físico não está selecionado nesta versão.

### Regras

- O percurso é finito: parte da casa `VAVA` e termina na casa `DESTINO`. Ao final, avance até o acesso central da casa para ver `CHEGAMOS!`.
- A estrada se estreita antes das pontes. Sair da pista, atingir a margem ou entrar no rio custa uma vida e recoloca o carro no centro da estrada.
- O tanque começa cheio, com **100 unidades**, e gasta uma unidade a cada 12 ticks (cerca de 24 segundos por tanque). Tanque vazio encerra a partida.
- Existem **dois postos**, com bombas vermelhas e placas `POSTO`, à direita da estrada. Encoste no piso cinza junto às bombas para abastecer automaticamente; a rolagem pausa enquanto o tanque enche. A barra `GAS` fica vermelha abaixo de 21 unidades.
- O jogador começa com **três corações vermelhos**, que se apagam a cada batida.
- Cada batida retira uma vida e concede **dois segundos de invulnerabilidade**, com o carro piscando.
- A terceira batida mostra `GAME OVER` no centro do cenário da partida, mantendo a pontuação final no HUD.
- Um tiro espanta a vaca, que passa a caminhar com o dobro da velocidade horizontal. A vaca usa uma pose fixa, espelhada conforme a direção, sem animação ao andar.
- Cada vaca espantada vale **100 pontos**, concedidos uma única vez.
- Uma vaca que conclui a travessia sem ser atingida vale **10 pontos**.
- Existem no máximo duas vacas e dois tiros ativos. A dificuldade é fixa.
- As duas linhas superiores mostram a pontuação de oito dígitos, as vidas, o combustível e o trajeto; somente o cenário abaixo delas rola.

## Abertura

![Abertura com a fonte original](previews/abertura-openmsx-4x.png)

`PLAY` pisca na abertura. Abaixo dele não há instruções nem outros textos. A transição exige que Espaço/Enter tenham sido soltos antes de um novo pressionamento, evitando reinícios e disparos involuntários.

## Três prévias

As prévias abaixo são renderizadas dos **mesmos padrões de tiles, máscaras de sprites e fonte que entram na ROM**. Cada arquivo tem uma versão nativa de 256 × 192 e uma ampliação de 1024 × 768 sem suavização. A composição é ilustrativa de uma situação de gameplay, com pontuação de exemplo.

| Direção visual | Nativa | Ampliação 4× |
| --- | --- | --- |
| Pasto verde, estrada marrom, Fusca amarelo — visual da ROM | [256 × 192](previews/01-pasto-fusca-amarelo.png) | [1024 × 768](previews/01-pasto-fusca-amarelo-4x.png) |
| Terra vermelha e Fusca azul | [256 × 192](previews/02-terra-vermelha-fusca-azul.png) | [1024 × 768](previews/02-terra-vermelha-fusca-azul-4x.png) |
| Fazenda seca e Fusca vermelho | [256 × 192](previews/03-fazenda-seca-fusca-vermelho.png) | [1024 × 768](previews/03-fazenda-seca-fusca-vermelho-4x.png) |

As duas alternativas mudam a paleta dos mesmos gráficos. O jogo usa a primeira direção; não há seletor de temas na abertura.

A [exploração artística inicial](previews/conceito-rural.png) foi gerada com a ferramenta integrada **Image Gen**, usando este [prompt](previews/conceito-prompt.txt). Ela orienta a composição e não representa uma captura do MSX. As três prévias finais são produzidas pelo renderizador determinístico do projeto.

## Compilar

Os recursos binários de montagem já estão em `resources/generated/`. Para montar a ROM, basta **SjASMPlus** disponível no `PATH`, executado a partir desta pasta:

```sh
sjasmplus Sebollas.asm
```

No PowerShell, usando a distribuição do assembler na pasta superior:

```powershell
..\sjasmplus.exe Sebollas.asm
```

A diretiva `OUTPUT` substitui `Sebollas.rom`. O fonte verifica o limite de `0x8000` com `ASSERT` e preenche o restante do cartucho com `0xFF`, até completar 16.384 bytes.

A montagem foi validada com **SjASMPlus 1.21.0**, sem erros ou avisos.

### Recriar os gráficos

Python 3 e Pillow são necessários somente para editar/recriar os recursos, gerar prévias e executar os testes Python. Não são dependências da ROM nem da montagem com os binários existentes.

```sh
python3 tools/build_assets.py
sjasmplus --sym=resources/generated/sebollas.sym Sebollas.asm
python3 tools/render_previews.py
```

A fonte original de 39 caracteres está preservada em `resources/font-original.bin`. O gerador remapeia seus desenhos para os códigos ASCII corretos, separa os tiles de cenário e gera as máscaras de sprites e suas cores por linha.

Também há alvos de Make:

```sh
make                  # monta a ROM e gera símbolos para o depurador
make assets           # recria recursos binários
make previews         # recria as três prévias e ampliações
make test             # montagem e testes de recursos
make test-emulator    # rotinas Z80 e gameplay contínuo em 50/60 Hz
make captures         # capturas reais de abertura, jogo e GAME OVER
```

## Organização

| Arquivo ou pasta | Responsabilidade |
| --- | --- |
| `Sebollas.asm` | Cabeçalho, configuração do vídeo, estados, controles, tiros, vacas, colisões, cenário e composição dos sprites. |
| `route.asm` | Combustível, abastecimento, colisão com terreno, chegada e barra do tanque. |
| `bios.asm` | Endereços da BIOS e das tabelas de SCREEN 4. |
| `ram_vars.asm` / `initRAM.asm` | Mapa e inicialização explícita da RAM e reinício da partida. |
| `string.asm` | Impressão por coordenadas, conversão BCD e desenhos originais da fonte. |
| `math.asm` | Rotinas aritméticas; a soma BCD é usada pela pontuação. |
| `sfx.inc` | Efeitos PSG nos três canais e desligamento por contagem de ticks. |
| `tools/build_assets.py` | Fonte, tiles rurais, mapa, paletas, carro, vacas, poeira e tiros. |
| `tools/render_previews.py` | Composição das prévias com os recursos reais. |
| `resources/generated/` | Binários usados na ROM e dados locais de verificação. |
| `tests/` | Restrições de hardware, testes das rotinas no openMSX e capturas. |
| `previews/` | Três estilos, conceito artístico e capturas do emulador. |

`keyboard.asm`, `bitset.asm`, `sprites.spr` e os antigos arquivos de mapa/bitmaps continuam disponíveis como material do protótipo anterior, mas não são incluídos pela nova ROM. O arquivo vazio `32k` também não participa da montagem.

## Limites gráficos e implementação

O cenário usa tiles de 8 × 8, com dois índices de cor por linha de oito pixels. O mapa tem 160 linhas, com início na linha 138 e fim na linha 0, sem repetição; a janela de 22 linhas avança oito pixels a cada 16 ticks. O percurso leva cerca de 45 segundos, mais o tempo de abastecimento e de aproximação final. Os bancos gráficos recebem a mesma fonte e os mesmos tiles, permitindo imprimir nas três regiões verticais.

| Elemento | Composição |
| --- | --- |
| Fusca 16 × 32 | Seis sprites: três camadas em cada metade de 16 × 16. |
| Vaca 32 × 32 | Oito sprites: duas camadas por quadrante, com cores por linha para corpo e focinho. Uma pose fixa, nos dois sentidos. |
| Poeira | Um sprite de 16 × 16, com quatro quadros, colocado logo após a traseira. |
| Cada tiro | Um sprite de 16 × 16, com desenho visível de 2 × 5 pixels. |

As vacas ficam separadas verticalmente por pelo menos 48 pixels e os tiros por pelo menos 16 pixels. Carro e poeira não compartilham linhas. Assim, o pior caso usa quatro entradas de uma vaca, três do carro e uma de tiro: **oito sprites por linha**, sem alternância de camadas por excesso. A piscada de invulnerabilidade é intencional.

A capacidade máxima é de **25 entradas de sprite** e **27 padrões de 16 × 16**. A RAM de trabalho fica em `0xC000–0xC6FF`; os atributos e cores são preparados em RAM antes do envio à VRAM.

| VRAM | Uso |
| --- | --- |
| `0x0000–0x17FF` | Três bancos de padrões de tiles. |
| `0x1800–0x1AFF` | Name Table de 32 × 24. |
| `0x1C00–0x1DFF` | Cores dos sprites por linha. |
| `0x1E00–0x1E7F` | Atributos dos sprites. |
| `0x2000–0x37FF` | Três bancos de cores dos tiles. |
| `0x3800–0x3FFF` | Padrões dos sprites. |

A lógica roda a 50 ticks por segundo. Em vídeo de 60 Hz, um de cada seis VBlanks não avança a lógica. As colisões usam caixas reduzidas em software: a sobreposição das camadas do carro, a poeira e os pixels transparentes dos tiros não provocam batidas.

## Verificação realizada

- Montagem sem erros ou avisos; cartucho de 16 KiB.
- **Sete testes Python**: fonte original, paletas, endereços de VRAM, máscaras, direções da vaca, percurso e pontos de interesse, ROM e limite de sprites.
- **62 casos de rotinas Z80 em cada frequência**, no openMSX 17.0 com C-BIOS MSX2 de 50 e 60 Hz: oito direções, bordas, tiros, vacas, pontuação BCD, três vidas, invulnerabilidade, menu, áudio, combustível, postos, pontes, terreno e chegada.
- Dois testes contínuos de aproximadamente 30 segundos, com direção e tiros: **zero quadros com excesso de sprites**, máximo observado de oito por linha.
- Duas viagens completas, em 50 e 60 Hz, com direção pelas teclas e abastecimento nos dois postos, chegando ao destino com combustível. O teste isola a viagem das batidas com vacas.
- Capturas reais de [abertura](previews/abertura-openmsx.png), [gameplay](previews/gameplay-openmsx.png) e [GAME OVER](previews/gameover-openmsx.png), além de [ponte](previews/ponte-openmsx.png), [posto](previews/posto-openmsx.png) e [chegada](previews/chegada-openmsx.png).
- Comparação da VRAM capturada com os padrões, cores, paleta e fonte empacotados na ROM.

Os relatórios locais são gerados em `resources/generated/emulator-50.txt`, `emulator-60.txt`, `stress-50.txt`, `stress-60.txt`, `route-50.txt` e `route-60.txt`. O teste de áudio verifica os registradores e o desligamento dos canais; não houve avaliação auditiva ou teste em hardware físico.

Neste ambiente, o openMSX precisa ser executado fora do sandbox para iniciar corretamente. Esse requisito é do ambiente de desenvolvimento, não da ROM.

## Licença

O projeto ainda não inclui arquivo de licença. As condições de uso e redistribuição do código e dos recursos precisam ser definidas pelo responsável.
