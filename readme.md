# i12play

Protótipo de jogo para **MSX**, escrito em **Assembly Z80** e montado com **SjASMPlus**. O projeto explora um veículo com aparência de Fusca, movimentação em oito direções, disparos, rolagem vertical de cenário e reprodução de sons pelo PSG.

O código está em desenvolvimento: reúne mecânicas de jogo e experimentos de teclado e áudio, com algumas rotinas ainda incompletas.

## Recursos presentes

- Gráficos em SCREEN 2, com área de 256 × 192 pixels e mapa visível de 32 × 24 tiles.
- Três tiles de cenário, com padrões e cores definidos em Assembly.
- Veículo composto por dois sprites de 16 × 16 pixels.
- Dois projéteis alternados, com intervalo entre disparos e movimento para cima.
- Rotinas de pontuação em BCD de oito dígitos e conversão para texto.
- Leitura das setas e da barra de espaço pela BIOS, além de varredura da matriz do teclado.
- Reprodução de notas e sequências nos canais A, B e C do PSG, com rotinas de ruído e envelope.
- Laço principal sincronizado por interrupções do VDP, usando `HALT`.

## Requisitos

- **SjASMPlus** para montar o código. A compilação foi verificada com a versão **1.21.0**; a distribuição ao redor desta pasta inclui `sjasmplus.exe` da versão 1.20.2.
- Um emulador de MSX ou equipamento compatível para executar a ROM, com BIOS MSX disponível.

Os fontes e os recursos necessários à montagem estão nesta pasta. Não há dependências de bibliotecas externas, gerenciador de pacotes ou etapa de conversão de imagens.

## Compilação

Execute os comandos a partir da pasta `i12play`, para que os caminhos dos arquivos incluídos sejam resolvidos corretamente.

### Linux

Com `sjasmplus` disponível no `PATH`:

```sh
sjasmplus i12play.asm
```

### Windows — PowerShell

Usando o executável que acompanha a distribuição na pasta superior:

```powershell
..\sjasmplus.exe i12play.asm
```

A diretiva `OUTPUT i12play.rom`, no arquivo principal, define o nome da saída. A montagem substitui a ROM existente nessa pasta.

A ROM começa no endereço `0x4000`, com cabeçalho de cartucho MSX identificado pelos bytes `AB` e ponteiro de inicialização para `START`. O fonte atual não contém preenchimento para fixar o tamanho em 16 ou 32 KiB.

Na verificação com SjASMPlus 1.21.0, a montagem terminou com **zero erros e zero avisos**, gerando **5.558 bytes**. A ROM que já acompanhava o projeto tem **5.570 bytes**; portanto, não deve ser tratada como uma reprodução exata da montagem verificada.

## Execução

Carregue `i12play.rom` como cartucho no emulador de MSX e inicialize a máquina. Para um ambiente com openMSX instalado e BIOS configurada, o comando é:

```sh
openmsx -cart i12play.rom
```

A execução em emulador ou hardware não foi validada nesta análise; a verificação realizada cobre a montagem dos fontes. Caso o carregador exija um tamanho padrão de cartucho, será necessário ajustar o preenchimento da imagem antes de usá-la nesse ambiente.

## Controles

| Tecla | Ação no código atual |
| --- | --- |
| Setas | Movimentam o veículo, incluindo diagonais. |
| Espaço | Aciona os dois disparos, respeitando seus estados e intervalos. |
| Esquerda / direita, sem diagonal | Também alteram a posição horizontal do sprite de teste e o deslocamento de notas em `0xC090`. |

O controle de direção usa `GTSTCK` com `A = 0`, e o disparo usa `GTTRIG` com `A = 0`; assim, essas chamadas consultam o teclado. Não há seleção de joystick físico no fluxo atual.

Há também um teste de notas que seleciona uma entrada da tabela `_teclas` pelo conteúdo de `0xC080`. Como esse índice não é inicializado nem limitado pelo programa, esse teste ainda não constitui um controle musical estável.

## Estrutura do projeto

| Arquivo | Responsabilidade |
| --- | --- |
| `i12play.asm` | Cabeçalho da ROM, entrada `START`, laço principal, vídeo, movimento, disparos, rolagem e atualização dos sprites. |
| `bios.asm` | Endereços das chamadas da BIOS, tabelas de VRAM, variáveis do sistema e constantes de cores. |
| `ram_vars.asm` | Endereços das variáveis de trabalho em RAM, a partir de `0xC000`. |
| `initRAM.asm` | Dados iniciais armazenados na ROM e rotina `InitVarsAtRAM`. |
| `keyboard.asm` | Varredura de 12 linhas do teclado, comparação de estados e tabela `_teclas`. |
| `sfx.inc` | Escrita no PSG, tabela de notas, temporização, sequenciador e dados de efeitos e músicas. |
| `sprites.spr` | Padrões dos sprites em texto Assembly, incluídos diretamente na montagem. |
| `resources/bitmaps.asm` | Padrões e cores dos três tiles de cenário. |
| `resources/screenMap.asm` | Mapa de tiles usado pela rolagem. |
| `math.asm` | Operações aritméticas e soma BCD para a pontuação. |
| `string.asm` | Escrita na Name Table, conversões para texto e fonte de caracteres. |
| `bitset.asm` | Rotina de criação de máscara de bits. |
| `i12play.rom` | Imagem de cartucho já presente no projeto, substituída ao compilar. |
| `32k` | Arquivo vazio, sem referência nos fontes; não define o tamanho da ROM. |

## Funcionamento

1. A BIOS encontra o cabeçalho do cartucho e chama `START`.
2. O programa executa a inicialização de RAM e do histórico de teclado, configura SCREEN 2 e prepara áudio, tiles, caracteres e padrões dos sprites.
3. A cada interrupção, o laço principal lê o teclado e executa o teste de notas.
4. Em seguida, atualiza a pontuação, processa direção e disparo, avança o cenário e atualiza áudio e sprites.
5. Por fim, consulta o indicador de colisão de sprites mantido pela BIOS em `STATFL`.

A rolagem desloca a janela do mapa em passos de uma linha de 32 tiles e copia 768 bytes para a Name Table. O contador é recarregado com `COUNT_TILE`, definido como `30`, depois de cada avanço. A velocidade do veículo é definida pelo byte `_heroSpeed`, inicialmente `1`.

O som é escrito diretamente nas portas `0xA0` e `0xA1`. As sequências usam pares de nota e duração, além de comandos como `REST`, `LOOP`, `NEXT_MUSIC` e `FINISH`. Existem dados musicais adicionais e a rotina `StartMissionImpossible`, mas ela não é chamada pela inicialização atual.

## Estado atual e limitações

Os pontos abaixo foram identificados por leitura do código e não foram corrigidos como parte desta documentação:

- **Colisões incompletas:** `CheckCollisionWithScreenMap` e `CheckCollisionWithEnemy` contêm apenas comentários e `RET`. O laço principal consulta o bit global de colisão do VDP e zera o estado do sprite de teste, sem identificar o par envolvido nem implementar resposta completa.
- **Inicialização de RAM:** `InitVarsAtRAM` usa `LDIR` com `HL = COUNT_TILE` e `HL = 0`, copiando bytes desses endereços da BIOS em vez de gravar diretamente os valores desejados. A configuração de `_music_time` prepara registradores, mas não executa a cópia antes de iniciar a próxima etapa.
- **Tamanhos dos dados iniciais:** alguns registros de sprites têm cinco bytes, embora sejam copiados seis. O texto de pontuação reserva nove bytes em RAM, mas recebe apenas seis bytes zerados na inicialização.
- **Teste de teclado e áudio:** `0xC080` e `0xC090` são usados sem inicialização no caminho de `START`. Além disso, os comentários de `GetKeyState` não correspondem ao retorno implementado: o código produz `0` para solta, `1` para pressionamento inicial, `2` para liberação e `3` para tecla mantida.
- **Limites de movimento:** os handlers não restringem as coordenadas à área visível; somas e subtrações de oito bits podem causar retorno de posição por overflow.
- **Pontuação experimental:** `Fire1` soma `10` em BCD quando alcança o trecho posterior à verificação do canal de áudio. Não há pontuação vinculada a inimigos derrotados.
- **Validação:** não há suíte automatizada de testes ou script de build nesta pasta. A montagem sem erros não comprova o funcionamento do jogo.

## Alterações comuns

- **Cenário:** edite os índices em `resources/screenMap.asm` e os padrões e cores em `resources/bitmaps.asm`.
- **Sprites:** edite os bytes em `sprites.spr` e os atributos iniciais em `initRAM.asm`.
- **Movimento:** ajuste `_heroSpeed` e os handlers `HANDLE_*` em `i12play.asm`.
- **Disparos:** ajuste `DELAY_BULLETS` e as rotinas `Fire1`, `Fire2` e `Updatefire`.
- **Rolagem:** ajuste `COUNT_TILE`, após revisar sua inicialização em RAM.
- **Áudio:** edite as sequências e rotinas em `sfx.inc`.

Após alterações, monte novamente e verifique no emulador a inicialização, as oito direções, disparos, rolagem, som e comportamento nas bordas da tela.

## Licença

Não há arquivo de licença nesta pasta. As condições de uso e redistribuição do código e dos recursos precisam ser definidas pelo responsável pelo projeto.
