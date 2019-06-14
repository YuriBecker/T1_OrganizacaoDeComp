# Autor: Yuri Becker e Daniel Libaroni
# Descrição: Trabalho da disciplina de Organização de Computadores 

# Constantes usadas no programa
##################################################################################################################

#servicos
.eqv	servico_imprime_string      4
.eqv  servico_imprime_caracter    11
.eqv  servico_abre_arquivo        13
.eqv  servico_leia_arquivo        14
.eqv  servico_fecha_arquivo       16
.eqv  servico_termina_programa    17

# mascaras usadas para ler as instrucoes
.eqv  mask_opcode 0xFC000000
.eqv  mask_rs 0x03E00000
.eqv  mask_rt 0x001F0000
.eqv 	mask_rd 0X0000F800
.eqv  mask_shift 0x000007C0
.eqv	mask_funct 0x0000003F
.eqv  mask_end16bits 0x0000FFFF
.eqv  mask_end26bits 0x03FFFFFF


# segmento de texto (programa)
###################################################################################################################
.text
main:
# inicializa o valor de PC
		lw $t0, end_inicial_texto
		sw $t0, pc
# Mostra mensagem perguntando o numero de instrucoes
		li $v0,4
		la $a0,msg_qtd_intrucoes
		syscall
# le input do teclado
		li $v0,5
		syscall
		la $t0, qtd_instrucoes
		sw $v0, 0($t0)
	
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
		                
            move  $s0, $v0      # armazenamos o número de caracteres lidos em $s0
            move  $s1, $a1      # armazenamos o endereço do instrucoes em $s1
            
            la    $s1, instrucoes
            la    $t0, qtd_instrucoes 
            lw    $s3, 0($t0) # carrega o numero de instrucoes
		li 	$t3, 1 # inicializa o contador
	    	
imprime_instrucoes:
            bgt 	$t3, $s3, fim_programa # Verifica se ja mostrou a quantidade de instrucoes 
            li   $v0, 34       # serviço 34: imprime o hexadecima em $a0
            lw   $a0, 0($s1)   # carregamos em $a0 o descritor do arquivo
            syscall             # imprimimos o caractere do instrucoes
            
            li   $v0, 11        # serviço 4: imprime uma string
            li   $a0, '\n' # $a0 <- endereço da string a ser apresentada
            syscall             # apresenta a string
             
            addi $s1, $s1, 4 #incrementa o endereco
            addi $t3, $t3, 1 #contador++
             
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
str1: 	.space 15 # primeira string do data.bin
str2: 	.space 5 # segunda string do data.bin

# dados do usuário
qtd_instrucoes:    .word 

# enderecos
end_inicial_texto: .word 0X00400000
end_inicial_data:  .word 0X10010000

# dados usados para salvar as informacoes do text.bin
pc: 		.space 4
ir: 		.space 4
op: 		.space 4
rs: 		.space 4
rt: 		.space 4
rd: 	 	.space 4
shift: 	.space 4
funct: 	.space 4
end16bits: 	.space 4
end26bits: 	.space 4

# Usados para manipulacao dos arquivos
instrucoes:	.space 4096 # guarda isntrucoes do text.bin 
data: 	.space 4096 # guarda isntrucoes do data.bin
descritor_arquivo1: .space 4     # descritor do arquivo 1
descritor_arquivo2: .space 4     # descritor do arquivo 2
nome_arquivo1:      .asciiz "text.bin" # nome do arquivo1 a ser aberto
nome_arquivo2:      .asciiz "data.bin" # nome do arquivo2 a ser aberto

# strings de mensagens para o usuario
msg_qtd_intrucoes: .asciiz "Numero de instrucoes que serão executadas (Max 48): "
 
