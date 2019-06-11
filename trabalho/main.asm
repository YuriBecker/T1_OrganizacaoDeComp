# Autor: Yuri Becker e Daniel Libaroni
# Descrição: Trabalho da disciplina de Organização de Computadores 

# segmento de texto (programa)
.text
main:
# abrimos o arquivo para a leitura
            li    $v0, 13       # serviço 13: abre um arquivo
            la    $a0, nome_arquivo # $a0 <- endereço da string com o nome do arquivo
            li    $a1, 0        # $a1 <- 0: arquivo será aberto para leitura
            li    $a2, 0        # modo não é usado. Use o valor 0.
            syscall             # abre o arquivo
            
# guardamos o descritor do arquivo aberto em descritor_arquivo
arquivo_aberto_com_sucesso:
            la    $t0, descritor_arquivo # $t0 <- endereço da variável descritor_arquivo
            sw    $v0, 0($t0)   # armazenamos na variável descritor_arquivo seu valor

# lemos o arquivo até preencher o instrucoes
leia_caracteres_arquivo:
            li    $v0, 14       # serviço 14: leitura do arquivo
            la    $t0, descritor_arquivo # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)   # $a0 <- o valor do descritor do arquivo
            la    $a1, instrucoes   # $a1 <- endereço do instrucoes que guarda os carcateres lidos
            li    $a2, 1024      # $a2 <- número máximo de carcateres lidos
            syscall             # fazemos a leitura de caracateres do arquivo para o instrucoes
           
           
# Os registradores $v0 e $a1 serão usados no código a seguir.
# Armazenamos o conteúdo destes registradores em outros registradores
            move  $s0, $v0      # armazenamos o número de caracteres lidos em $s0
            move  $s1, $a1      # armazenamos o endereço do instrucoes em $s1
imprime_instrucoes:
             # imprime caractere do instrucoes
             li    $v0, 34       # serviço 34: imprime o hexadecima em $a0
             la    $s1, instrucoes # $s1 <- endereço do descritor da instrucao
             lw    $a0, 0($s1)   # carregamos em $a0 o descritor do arquivo
             syscall             # imprimimos o caractere do instrucoes
             
             li    $v0,4          # serviço 4: imprime uma string
            la    $a0, quebra_linha # $a0 <- endereço da string a ser apresentada
            syscall             # apresenta a string
             
             li    $v0, 34       # serviço 34: imprime o hexadecima em $a0
             la    $s1, instrucoes # $s1 <- endereço do descritor da instrucao
             lw    $a0, 4($s1)   # carregamos em $a0 o descritor do arquivo
             syscall             # imprimimos o caractere do instrucoes
             
             li    $v0,4          # serviço 4: imprime uma string
            la    $a0, quebra_linha # $a0 <- endereço da string a ser apresentada
            syscall             # apresenta a string
             
             li    $v0, 34       # serviço 34: imprime o hexadecima em $a0
             la    $s1, instrucoes # $s1 <- endereço do descritor da instrucao
             lw    $a0, 8($s1)   # carregamos em $a0 o descritor do arquivo
             syscall             # imprimimos o caractere do instrucoes
            
            

# fechamos o arquivo
fecha_arquivo:
            li    $v0, 16       # serviço 16: fecha um arquivo
            la    $t0, descritor_arquivo # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)   # carregamos em $a0 o descritor do arquivo
            syscall             # fechamos o arquivo


###########################################################################################################################

# segmento de dados

.data
instrucoes:        .space 192   # criamos um instrucoes com 192 bytes
descritor_arquivo: .space 4     # descritor do arquivo
nome_arquivo:      .asciiz "text.bin" # nome do arquivo a ser aberto
quebra_linha: .asciiz "\n"

