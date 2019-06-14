# Autor: Yuri Becker e Daniel Libaroni
# Descrição: Trabalho da disciplina de Organização de Computadores 

# Constantes usadas no programa
##################################################################################################################

#servicos
.eqv	servico_imprime_string        4
.eqv	servico_le_input              5
.eqv  servico_imprime_caracter      11
.eqv  servico_abre_arquivo          13
.eqv  servico_leia_arquivo          14
.eqv  servico_fecha_arquivo         16
.eqv  servico_termina_programa      17

# mascaras usadas para ler as instrucoes
.eqv  mask_opcode                   0xFC000000
.eqv  mask_rs                       0x03E00000
.eqv  mask_rt                       0x001F0000
.eqv 	mask_rd                       0X0000F800
.eqv  mask_shift                    0x000007C0
.eqv	mask_funct                    0x0000003F
.eqv  mask_end16bits                0x0000FFFF
.eqv  mask_end26bits                0x03FFFFFF


# segmento de texto (programa)
###################################################################################################################
.text
main:
# inicializa o valor de PC
		lw $t0, end_inicial_texto
		sw $t0, pc
# Mostra mensagem perguntando o numero de instrucoes
		li $v0, servico_imprime_string 
		la $a0, msg_qtd_intrucoes
		syscall
# le input do teclado
		li $v0, servico_le_input  
		syscall
		sw $v0, qtd_instrucoes
	
# abrimos o arquivo data.bin para a leitura           
            la    $a0, nome_arquivo_data 
            la    $a1, descritor_data
            jal   abre_arquivo
		lw    $a0, descritor_data                # $a0 <- o valor do descritor do arquivo
            la    $a1, data                          # $a1 <- endereço do instrucoes que guarda os carcateres lidos
            jal   leia_caracteres_arquivo		     # Guarda caracteres na memória
            
# abrimos o arquivo text.bin para a leitura
            la    $a0, nome_arquivo_text 
            la    $a1, descritor_text
            jal   abre_arquivo
		lw    $a0, descritor_text                 # $a0 <- o valor do descritor do arquivo
            la    $a1, instrucoes                     # $a1 <- endereço do instrucoes que guarda os carcateres lidos
            jal   leia_caracteres_arquivo			# Guarda caracteres na memória
            
            jal   fecha_arquivos                      # fecha os dois arquivos 
		la    $a1, instrucoes				# passa o buffer de instrucoes
            lw    $a2, qtd_instrucoes                 # passa o numero de instrucoes informado pelo usuario
		j     busca_instrucao                     # pula para busca da instrucao 
		
# lemos o arquivo e colocamos na memória
leia_caracteres_arquivo:
            li    $v0, servico_leia_arquivo           # serviço 14: leitura do arquivo
            li    $a2, 4096                           # $a2 <- número máximo de carcateres lidos
            syscall                                   # fazemos a leitura de caracateres do arquivo para o instrucoes
            move  $s0, $v0                            # armazenamos o número de caracteres lidos em $s0
            move  $s1, $a1                            # armazenamos o endereço das instrucoes em $s1                                     
            jr    $ra 						#retorna para o procedimento chamador 
            
# guardamos o descritor do arquivo 
arquivo_aberto_com_sucesso:
            la    $t0, descritor_text                 # $t0 <- endereço da variável descritor_arquivo
            sw    $v0, 0($t0)                         # armazenamos na variável descritor_arquivo seu valor

abre_arquivo:
            addiu $sp, $sp, -4                        # será adicionado um elemento na pilha
            sw    $a1, 0($sp)                         # guardamos na pilha o endereço da variável descritor do arquivo
            li    $v0, servico_abre_arquivo           # serviço 13: abre um arquivo
            li    $a1, 0                              # $a1 <- 0: arquivo será aberto para leitura
            li    $a2, 0                              # modo não é usado. Use o valor 0.
            syscall                                   # abre o arquivo

            # guardamos o descritor do arquivo em descritor_arquivo
            lw    $a1, 0($sp)                         # carregamos o endereço da variável com o descritor do arquivo
            sw    $v0, 0($a1)                         # armazenamos o descritor do arquivo em descritor_arquivo
            slt   $t0, $v0, $zero                     # $t0 = 1 se $v0 < 0 ($v0 negativo)
            bne   $t0, $zero, arquivo_nao_foi_aberto  # se $v0 é negativo, o arquivo não pode ser aberto
            j     arquivo_foi_aberto

arquivo_nao_foi_aberto:
            li    $v0, servico_imprime_string         # serviço 4: imprime uma string
            la    $a0, msg_arquivo_nao_foi_aberto     # $a0 armazena o endereço da string a ser apresentada
            syscall                                   # apresenta a string
            j     fim_programa                        # termina o programa

arquivo_foi_aberto:
            li    $v0, servico_imprime_string         # serviço 4: imprime uma string
            la    $a0, msg_arquivo_aberto             # $a0 possui o endereço da string a ser apresentada
            syscall                                   # apresenta a string
            addiu $sp, $sp, 4                         # restauramos a pilha   
            jr    $ra                                # retornamos ao procedimento chamador 

busca_instrucao:                         
           
            lw 	$t3, contador   				# carrega o contador
            lw    $t4, pc                             # carrega valor de pc
            lw	$t5, 0($a1)		                  # busca instrucao
            sw	$t5, ir		                  # IR recebe a instrucao que sera executada
            
            bgt 	$t3, $a2, fim_programa              # Verifica se ja mostrou a quantidade de instrucoes 
            # Mostra mensagem informando o endereco
		li $v0, servico_imprime_string 
		la $a0, msg_exec_instrucao1
		syscall
            li    $v0, 34                             # serviço 34: imprime o hexadecima em $a0
            move 	$a0, $t4		                  # $a0 = pc
            syscall 
            # Mostra mensagem informando a instrucao
		li $v0, servico_imprime_string 
		la $a0, msg_exec_instrucao2
		syscall
            li    $v0, 34                             # serviço 34: imprime o hexadecima em $a0
            move 	$a0, $t5		                  # $a0 = instrucao = IR
            syscall                                   # imprimimos o caractere do instrucoes     
            # li    $v0, servico_imprime_caracter       # imprime um caractere
            # li    $a0, '\n'                           # $a0 <- endereço do caractere a ser apresentado
            # syscall                                   # apresenta o caractere 

            addi  $a1, $a1, 4                         # incrementa o endereco
            addi  $t3, $t3, 1                         # contador++
            addi	$t4, $t4, 4			            # pc = pc + 4
            sw    $t3, contador		            # Salva valor do contador
            sw    $t4, pc		                  # Salva valor do contador
            j     busca_instrucao
                         
# fechamos o arquivo
fecha_arquivos:
            li    $v0, servico_fecha_arquivo          # serviço 16: fecha um arquivo
            la    $t0, descritor_text                 # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)                         # carregamos em $a0 o descritor do arquivo
            syscall                                   # fechamos o arquivo
            li    $v0, servico_fecha_arquivo          # serviço 16: fecha um arquivo
            la    $t0, descritor_data                 # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)                         # carregamos em $a0 o descritor do arquivo
            syscall                                   # fechamos o arquivo
            jr    $ra  
#fechamos o programa
fim_programa:
	    	li $v0, 10
	   	syscall

####################################################################################################################
# segmento de dados

.data
# Usados para manipulacao dos arquivos
data: 	            .space 4096                   # guarda isntrucoes do data.bin
instrucoes:	            .space 4096                   # guarda isntrucoes do text.bin 
descritor_data:         .space 4                      # descritor do arquivo 1
descritor_text:         .space 4                      # descritor do arquivo 2
nome_arquivo_text:      .asciiz "text.bin"            # nome do arquivo1 a ser aberto
nome_arquivo_data:      .asciiz "data.bin"            # nome do arquivo2 a ser aberto

# dados do usuário
qtd_instrucoes:         .word 

# enderecos
end_inicial_texto:      .word 0X00400000
end_inicial_data:       .word 0X10010000

# dados usados para salvar as informacoes do text.bin
pc: 		            .space 4
ir: 		            .space 4
op: 		            .space 4
rs: 		            .space 4
rt: 		            .space 4
rd: 	 	            .space 4
shift: 	            .space 4
funct: 	            .space 4
end16bits: 	            .space 4
end26bits: 	            .space 4

contador:               .word 1 # <- Contador do loop

# strings de mensagens para o usuario
msg_qtd_intrucoes:      .asciiz "Numero de instrucoes que serão executadas (Max 48): "
msg_arquivo_nao_foi_aberto: .asciiz "\nArquivo nao pode ser aberto \n"
msg_arquivo_aberto:     .asciiz "\nArquivo aberto com sucesso! \n" 
msg_exec_instrucao1:     .asciiz "\nExecutando instrução no endereco -> "
msg_exec_instrucao2:     .asciiz " - instrução  -> "