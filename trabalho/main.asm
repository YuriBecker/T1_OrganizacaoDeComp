# Autor: Yuri Becker e Daniel Libaroni
# Descrição: Trabalho da disciplina de Organização de Computadores 

# Constantes usadas no programa
##################################################################################################################

#servicos
.eqv        servico_imprime_string      4
.eqv        servico_imprime_caracter    11
.eqv        servico_abre_arquivo        13
.eqv        servico_leia_arquivo        14
.eqv        servico_fecha_arquivo       16
.eqv        servico_termina_programa    17
# mascaras usadas para ler as instrucoes
.eqv  	    mask_opcode 0xFC000000
.eqv  	    mask_rs 0x03E00000
.eqv  	    mask_rt 0x001F0000
.eqv 	    mask_rd 0X0000F800
.eqv        mask_shift 0x000007C0
.eqv	    mask_funct 0x0000003F
.eqv        mask_end16bits 0x0000FFFF
.eqv        mask_end26bits 0x03FFFFFF


# segmento de texto (programa)
###################################################################################################################
.text
main:
# abrimos o arquivo para a leitura
            li    $v0, 13       # serviço 13: abre um arquivo
            la    $a0, nome_arquivo1 # $a0 <- endereço da string com o nome do arquivo
            li    $a1, 0        # $a1 <- 0: arquivo será aberto para leitura
            li    $a2, 0        # modo não é usado. Use o valor 0.
            syscall             # abre o arquivo
            
# guardamos o descritor do arquivo aberto em descritor_arquivo
arquivo_aberto_com_sucesso:
            la    $t0, descritor_arquivo1 # $t0 <- endereço da variável descritor_arquivo
            sw    $v0, 0($t0)   # armazenamos na variável descritor_arquivo seu valor

# lemos o arquivo até preencher o instrucoes
leia_caracteres_arquivo:
            li    $v0, 14       # serviço 14: leitura do arquivo
            la    $t0, descritor_arquivo1 # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)   # $a0 <- o valor do descritor do arquivo
            la    $a1, instrucoes   # $a1 <- endereço do instrucoes que guarda os carcateres lidos
            li    $a2, 1024      # $a2 <- número máximo de carcateres lidos
            syscall             # fazemos a leitura de caracateres do arquivo para o instrucoes
           
           
           
# Os registradores $v0 e $a1 serão usados no código a seguir.
# Armazenamos o conteúdo destes registradores em outros registradores
            move  $s0, $v0      # armazenamos o número de caracteres lidos em $s0
            move  $s1, $a1      # armazenamos o endereço do instrucoes em $s1
            la    $s1, instrucoes

imprime_instrucoes:
             
             # imprime caractere do instrucoes
             li    $v0, 34       # serviço 34: imprime o hexadecima em $a0
             #la    $s1, instrucoes # $s1 <- endereço do descritor da instrucao
             lw    $a0, 0($s1)   # carregamos em $a0 o descritor do arquivo
             syscall             # imprimimos o caractere do instrucoes
             
             li    $v0, 11        # serviço 4: imprime uma string
             li    $a0, '\n' # $a0 <- endereço da string a ser apresentada
             syscall             # apresenta a string
             
             addi $s1, $s1, 4 
             
             j imprime_instrucoes
                         
            

# fechamos o arquivo
fecha_arquivo:
            li    $v0, 16       # serviço 16: fecha um arquivo
            la    $t0, descritor_arquivo1 # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)   # carregamos em $a0 o descritor do arquivo
            syscall             # fechamos o arquivo

#fechamos o programa
fim_programa:
	    li $v0, 10
	    syscall

####################################################################################################################
# segmento de dados

.data
str1: .space 15 # primeira string do data.bin
str2: .space 5 # segunda string do data.bin
instrucoes: .space 192   # instrucoes lidas do text.bin

mem_text: .space 4096
mem_data: .space 4096

# dados usados para salvar as informacoes do text.bin
pc: .space 4
ir: .space 4
op: .space 4
rs: .space 4
rt: .space 4
rd: .space 4
shift: .space 4
funct: .space 4
end16bits: .space 4
end26bits: .space 4

# Usados para manipulacao dos arquivos
descritor_arquivo1: .space 4     # descritor do arquivo 1
descritor_arquivo2: .space 4     # descritor do arquivo 2
nome_arquivo1:      .asciiz "text.bin" # nome do arquivo1 a ser aberto
nome_arquivo2:      .asciiz "data.bin" # nome do arquivo2 a ser aberto
