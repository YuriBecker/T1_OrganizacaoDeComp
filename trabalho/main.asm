# Autor: Yuri Becker e Daniel Libaroni
# Descrição: Trabalho da disciplina de Organização de Computadores 

# Constantes usadas no programa
##################################################################################################################

# servicos
.eqv	servico_imprime_int        	1
.eqv	servico_imprime_string        4
.eqv	servico_le_input              5
.eqv  servico_imprime_caracter      11
.eqv  servico_abre_arquivo          13
.eqv  servico_leia_arquivo          14
.eqv  servico_fecha_arquivo         16
.eqv  servico_termina_programa      17
.eqv  servico_imprime_hexa          34

# mascaras usadas para ler as instrucoes
.eqv  mask_opcode                   0xFC000000
.eqv  mask_rs                       0x03E00000
.eqv  mask_rt                       0x001F0000
.eqv 	mask_rd                       0X0000F800
.eqv  mask_shift                    0x000007C0
.eqv	mask_funct                    0x0000003F
.eqv  mask_val16bits                0x0000FFFF
.eqv  mask_val26bits                0x03FFFFFF

.eqv  tamanho_pilha                 50                # constante com o tamanho da pilha

.eqv  end_inicial_texto             0X00400000

# valores hexadecimais dos registradores
.eqv val_s0                         0X00000010
.eqv val_zero                       0X00000000
.eqv val_a0                         0X00000004
.eqv val_v0                         0X00000002
.eqv val_t0                         0X00000008
.eqv val_t1                         0X00000009

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
# end_inicial_texto:      .word 0X00400000
end_inicial_data:       .word 0X10010000

# Registradores do processador falso
pc: 		            .space 4                      # Guarda o endereco da instrucao
ir: 		            .space 4                      # Guarda a instrucao
registradores:          .space 128                    # vetor pra os registradores (32 * 4)
pilha:                  .space 200                    # pilha virtual com espaço para 50 words

# dados usados para salvar as informacoes do ir
opcode: 		      .space 4
rs: 		            .space 4
rt: 		            .space 4
rd: 	 	            .space 4
shift: 	            .space 4
funct: 	            .space 4
val16bits: 	            .space 4
val26bits: 	            .space 4

contador:               .word 1                       # <- Contador do loop / numero de instrucoes já lidas
tipo:                   .space 1                      # <- Tipo da instrucao

# strings de mensagens para o usuario
msg_qtd_intrucoes:            .asciiz "Numero de instrucoes que serão executadas (Max 48): "
msg_arquivo_nao_foi_aberto:   .asciiz "\nArquivo nao pode ser aberto \n"
msg_arquivo_aberto:           .asciiz "\nArquivo aberto com sucesso! \n" 
msg_exec_instrucao1:          .asciiz "\nExecutando instrução no endereco -> "
msg_exec_instrucao2:          .asciiz " - instrução  -> "
msg_exec_instrucao3:          .asciiz " - OPCODE  -> "
msg_tipo:                     .asciiz " - Instrucao do tipo "

# segmento de texto (programa)
###################################################################################################################
.text
main:
		la    $t0, instrucoes
		sw    $t0, pc                             # inicializa o valor de PC

            la    $t0, pilha
            # li	$t2, 4		                  # $t2 = 4
            # li	$t3, tamanho_pilha		      # $t3 = tamanho_pilha
            # mul   $t1, $t2, $t3                       # tamanho da pilha * 4
            addi	$t4, $t0, 200		            # $t4 = $t0 + 200
            la	$t3, registradores		      # pega o endereco dos registradores simulados
            sw	$t4, 116($t3)		            # salva o endereço final da pilha simulada no registrador simulado na posição 29 = sp
            
		li    $v0, servico_imprime_string 
		la    $a0, msg_qtd_intrucoes
		syscall                                   # Mostra mensagem perguntando o numero de instrucoes
		li    $v0, servico_le_input  
		syscall                                   # le input do teclado
		sw    $v0, qtd_instrucoes                 # salva valorm informado pelo usuario
	         
            la    $a0, nome_arquivo_data 
            la    $a1, descritor_data
            jal   abre_arquivo                        # abrimos o arquivo data.bin para a leitura  
		lw    $a0, descritor_data                 # $a0 <- o valor do descritor do arquivo
            la    $a1, data                           # $a1 <- endereço do instrucoes que guarda os carcateres lidos
            jal   leia_caracteres_arquivo		      # pula para leia_caracteres_arquivo e salva a prox posicao no $ra
            
            la    $a0, nome_arquivo_text 
            la    $a1, descritor_text
            jal   abre_arquivo                        # abrimos o arquivo text.bin para a leitura
		lw    $a0, descritor_text                 # $a0 <- o valor do descritor do arquivo
            la    $a1, instrucoes                     # $a1 <- endereço do instrucoes que guarda os carcateres lidos
            jal   leia_caracteres_arquivo			# pula para leia_caracteres_arquivo e salva a prox posicao no $ra
            
            jal   fecha_arquivos                      # fecha os dois arquivos 
		j     busca_instrucao                     # pula para busca da instrucao 
		
# lemos o arquivo e colocamos na memória
leia_caracteres_arquivo:
            li    $v0, servico_leia_arquivo           # serviço 14: leitura do arquivo
            li    $a2, 4096                           # $a2 <- número máximo de carcateres lidos
            syscall                                   # fazemos a leitura de caracateres do arquivo para o instrucoes
            move  $s0, $v0                            # armazenamos o número de caracteres lidos em $s0
            move  $s1, $a1                            # armazenamos o endereço das instrucoes em $s1                                     
            jr    $ra 						#retorna para o procedimento chamador 
            
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

            lw    $a1, 0($sp)                         # carregamos o endereço da variável com o descritor do arquivo
            sw    $v0, 0($a1)                         # armazenamos o descritor do arquivo em descritor_arquivo
            slt   $t0, $v0, $zero                     # $t0 = 1 se $v0 < 0 ($v0 negativo)
            bne   $t0, $zero, arquivo_nao_foi_aberto  # se $v0 é negativo, o arquivo não pode ser aberto
            j     arquivo_foi_aberto                  # pula para o procedimento 

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
            jr    $ra                                 # retornamos ao procedimento chamador 

busca_instrucao:                         
            lw 	$t3, contador   				# carrega o contador
            lw    $t4, pc                             # carrega valor de pc
            lw	$t5, 0($t4)		                  # busca instrucao
            sw	$t5, ir		                  # IR recebe a instrucao que sera executada   
            lw    $t2, qtd_instrucoes                 # passa o numero de instrucoes informado pelo usuario       
            bgt 	$t3, $t2, fim_programa              # Verifica se ja mostrou a quantidade de instrucoes 
		li    $v0, servico_imprime_string 
		la    $a0, msg_exec_instrucao1            # Mostra mensagem informando o endereco
		syscall                                   # chamada ao sistema
            li    $v0, servico_imprime_hexa           # serviço 34: imprime o hexadecima em $a0
            move 	$a0, $t4		                  # $a0 = pc
            syscall                                   # chamada ao sistema
		li    $v0, servico_imprime_string         
		la    $a0, msg_exec_instrucao2            # Mostra mensagem informando a instrucao
		syscall                                   # chamada ao sistema 
            li    $v0, servico_imprime_hexa           # serviço 34: imprime o hexadecima em $a0
            move 	$a0, $t5		                  # $a0 = instrucao = IR
            syscall                                   # imprimimos o caractere do instrucoes     
           
            jal	decodifica_bin				# pula para decodifica_bin e salva a prox posicao no $ra
            jal   decodifica_tipo                     # pula para decodifica_tipo e salva a prox posicao no $ra                              
            
            lw 	$t3, contador   				# carrega o contador
            lw    $t4, pc                             # carrega valor de pc
            addi  $t3, $t3, 1                         # contador++
            addi	$t4, $t4, 4			            # pc = pc + 4
            sw    $t3, contador		            # Salva valor do contador
            sw    $t4, pc		                  # Salva valor do contador
            j     busca_instrucao                     # pulamos para o procedimento
fecha_arquivos:
            li    $v0, servico_fecha_arquivo          # serviço 16: fecha um arquivo
            la    $t0, descritor_text                 # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)                         # carregamos em $a0 o descritor do arquivo
            syscall                                   # fechamos o arquivo
            li    $v0, servico_fecha_arquivo          # serviço 16: fecha um arquivo
            la    $t0, descritor_data                 # $t0 <- endereço do descritor do arquivo
            lw    $a0, 0($t0)                         # carregamos em $a0 o descritor do arquivo
            syscall                                   # fechamos o arquivo
            jr    $ra                                 # voltamos ao procedimento chamador

fim_programa:
	    	li    $v0, servico_termina_programa       # fechamos o programa
	   	syscall                                   # chamada ao sistema

decodifica_bin:                                       # decodificamos todos os posiveis cabeçalhos binários
		li    $v0, servico_imprime_string 
		la    $a0, msg_exec_instrucao3            # Mostra mensagem informando o opcode
		syscall                                   # chamada ao sistema 
		
            lw	$s0, ir                             # carregamos instrução
            li    $s2, mask_opcode                    # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o opcode
            srl	$s3, $s1, 26                        # jogamos o resultado para o final 
            sw	$s3, opcode		                  # salvamos na memória

            li    $v0, servico_imprime_hexa
		move  $a0, $s3                            # Mostra mensagem informando o endereco
		syscall                                   # chamada ao sistema

            li    $s2, mask_rs                        # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o rs
            srl	$s3, $s1, 21                        # jogamos o resultado para o fim
            sw	$s3, rs		                  # salvamos na memória

            li    $s2, mask_rt                        # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o rt
            srl	$s3, $s1, 16                        # jogamos o resultado para o fim
            sw	$s3, rt		                  # salvamos na memória

            li    $s2, mask_rd                        # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o rd
            srl	$s3, $s1, 11                        # jogamos o resultado para o fim
            sw	$s3, rd		                  # salvamos na memória

            li    $s2, mask_shift                     # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o shift
            srl	$s3, $s1, 6                         # jogamos o resultado para o fim
            sw	$s3, shift		                  # salvamos na memória

            li    $s2, mask_funct                     # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o funct
            sw	$s1, funct		                  # salvamos na memória

            li    $s2, mask_val16bits                 # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o endereco 16 bits
            sw	$s1, val16bits		            # salvamos na memória

            li    $s2, mask_val26bits                 # carregamos a marcara
            and   $s1, $s0, $s2                       # usamos a mascara para pegar o endereco 26 bits
            sw	$s1, val26bits		            # salvamos na memória

            jr    $ra                                 # voltamos ao procedimento chamador
            
decodifica_tipo:                                      # descobre o tipo da instrucao
            lw	$t5, opcode		                  # carrega opcode             
            lw    $t4, funct                          # carrega funct    
            li	$t6, 3		                  # $t6 = 3
            # li	$t1, 0X0000000C		            # $t1 = 0X0000000C
            # beq	$t4, $t1, salva_tipo_syscall	      # verifica se é uma syscall
            beq	$t5, $zero, salva_tipo_r	      # verifica se é do tipo R
            bgt	$t5, $t6, salva_tipo_i	            # verifica se é do tipo I
            j	salva_tipo_j				# é do tipo J

# salva_tipo_syscall:
#             li    $v0, servico_imprime_string 
# 		la    $a0, msg_tipo                       # Mostra mensagem informando o tipo
# 		syscall                                   # chamada ao sistema
#             li	$t7, 'S'		                  # $t7 = "S"
#             sb	$t7, tipo		                  # salva o tipo na memoria 
#             addiu $sp, $sp, -4                        # será adicionado um elemento na pilha
#             sw    $ra, 0($sp)                         # guardamos na pilha o endereço de retorno
#             jal   exec_tipo_syscall                   # executa a instrucao
#             j     fim_decodifica_tipo                 # finaliza

salva_tipo_r:
            li    $v0, servico_imprime_string 
		la    $a0, msg_tipo                       # Mostra mensagem informando o tipo
		syscall                                   # chamada ao sistema
            li	$t7, 'R'		                  # $t7 = "R"
            sb	$t7, tipo		                  # salva o tipo na memoria 
            addiu $sp, $sp, -4                        # será adicionado um elemento na pilha
            sw    $ra, 0($sp)                         # guardamos na pilha o endereço de retorno
            jal   exec_tipo_r                         # executa a instrucao
            j     fim_decodifica_tipo                 # finaliza

salva_tipo_j:
            li    $v0, servico_imprime_string 
		la    $a0, msg_tipo                       # Mostra mensagem informando o tipo
		syscall                                   # chamada ao sistema
            li	$t7, 'J'		                  # $t7 = "J"
            sb	$t7, tipo		                  # salva o tipo na memoria 
            addiu $sp, $sp, -4                        # será adicionado um elemento na pilha
            sw    $ra, 0($sp)                         # guardamos na pilha o endereço de retorno
            jal   exec_tipo_j                         # executa a instrucao
            j     fim_decodifica_tipo                 # finaliza

salva_tipo_i:
            li    $v0, servico_imprime_string 
		la    $a0, msg_tipo                       # Mostra mensagem informando o tipo
		syscall                                   # chamada ao sistema
            li	$t7, 'I'		                  # $t7 = "I"
            sb	$t7, tipo		                  # salva o tipo na memoria
            addiu $sp, $sp, -4                        # será adicionado um elemento na pilha
            sw    $ra, 0($sp)                         # guardamos na pilha o endereço de retorno 
            jal   exec_tipo_i                         # executa a instrucao
            j     fim_decodifica_tipo                 # finaliza

fim_decodifica_tipo:                                  # printa o tipo e finaliza
            li          $v0, servico_imprime_caracter 
		lb	      $a0, tipo		            # Informa o tipo
		syscall                                   # chamada ao sistema
            lw	      $ra, 0($sp)                   # restaura valor do $ra           
            addiu       $sp, $sp, 4                   # restauramos a pilha   
            jr          $ra                           # retornamos ao procedimento chamador

exec_tipo_i:
            lw    $t0, opcode
            
            li	$t1, 0X05		                  # $t1 = 0X05 / bne
            beq	$t0, $t1, exec_bne	            # if $t0 == $t1 then exec_bne

            li	$t1, 0X08		                  # $t1 = 0X08 / addi
            beq	$t0, $t1, exec_addi	            # if $t0 == $t1 then exec_addi

            li	$t1, 0X09		                  # $t1 = 0X09 / addiu
            beq	$t0, $t1, exec_addiu	            # if $t0 == $t1 then exec_addiu

            li	$t1, 0X0F		                  # $t1 = 0X0F / lui
            beq	$t0, $t1, exec_lui	            # if $t0 == $t1 then exec_lui

            li	$t1, 0X0D		                  # $t1 = 0X0D / ori
            beq	$t0, $t1, exec_ori	            # if $t0 == $t1 then exec_ori

            li	$t1, 0X23		                  # $t1 = 0X23 / lw
            beq	$t0, $t1, exec_lw	                  # if $t0 == $t1 then exec_lw

            li	$t1, 0X2B		                  # $t1 = 0X2B / sw
            beq	$t0, $t1, exec_sw	                  # if $t0 == $t1 then exec_sw

            li	$t1, 0X70		                  # $t1 = 0X70 / mul
            beq	$t0, $t1, exec_mul	            # if $t0 == $t1 then exec_mul
            
            # jr    $ra                                 # retornamos ao procedimento chamador

exec_tipo_j:
            lw    $t0, opcode
            
            li	$t1, 0X03	                        # $t1 = 0X03 / jal
            beq	$t0, $t1, exec_jal	            # if $t0 == $t1 then exec_jal

            li	$t1, 0X02		                  # $t1 = 0X09 / addiu
            beq	$t0, $t1, exec_j	                  # if $t0 == $t1 then exec_j

            # jr    $ra                                 # retornamos ao procedimento chamador

exec_tipo_r:
            lw	$t5, funct		                  # carrega valor de func 
            
            li	$t6, 0X0000000C		            # $t1 = 0X0000000C
            beq	$t5, $t6, exec_syscall	            # executa uma syscall
            li	$t6, 0X00000020 		            # $t6 = 0X00000020 
            beq	$t5, $t6, exec_add	            # executa add
            li	$t6, 0X00000021 		            # $t6 = 0X00000020 
            beq	$t5, $t6, exec_addu	            # executa addu
            li	$t6, 0X00000008 		            # $t6 = 0X00000020 
            beq	$t5, $t6, exec_jr	                  # executa jr
            li	$t6, 0X0000001c 		            # $t6 = 0X0000001c 
            beq	$t5, $t6, exec_mul                 # executa mul
            # jr    $ra                                 # retornamos ao procedimento chamador

# TIPO I
exec_bne:                                             # executa bne
   # Carrega valores da instrução
            lw          $t0, rt                       # carrega rt
            lw          $t1, rs                       # carrega rs
            # sll         $t2, $t2, 16 
            # sra         $t2, $t2, 16
            la          $t3, registradores            # carrega enredeço base dos registradores
            sll         $t0, $t0, 2                   # rt * 4
            sll         $t1, $t1, 2                   # rs * 4
            add         $t0, $t3, $t0                 # endereço base + posição do registrador em rt
            add         $t1, $t3, $t1                 # endereço base + posição do registrador em rs
            lw		$t1, 0($t1)		            # carrega valor do registrador simulado
            lw		$t0, 0($t0)		            # carrega valor do registrador simulado
            
            bne         $t1, $t0, registradores_diferentes    # instrução será exeutada caso for falsa
            j           fim_exec                              # segue para próxima instrução
            
            registradores_diferentes:
                  lw          $t2, val16bits                # carrega o imediato de 16bits
                  sll         $t2, $t2, 2                   # offset * 4
                  lw		$t3, pc		            # carrega o pc simulado
                  add		$t3, $t3, $t2		      # $t3 = $t3 + $t2
                  # addi	      $t5, $t3, -4                  # $t5 = 5 + -1
                  sw          $t3, pc                       # salva o endereço da instrução no pc simulado
                  j           fim_exec                      # segue para próxima instrução

exec_addiu:                                           # executa o addiu
            lw		$t1, rs		            # carrega o primeiro valor a ser somado
            sll         $t1, $t1, 2                   # registrador * 4 
            lw		$t2, val16bits		      # carrega o segundo valor a ser somado
            sll         $t2, $t2, 16 
            sra         $t2, $t2, 16
            la		$t4, registradores		# carrega endereço base dos registradores 
            lw		$t0, rt		            # carrega o registrador onde será salvo
            sll         $t0, $t0, 2                   # registrador * 4
            
            add		$t6, $t4, $t1		      # $t6 = $t1 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            lw		$t1, 0($t6)		            # carrega valor do registrador simulado 
            add		$t5, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            addu		$t3, $t1, $t2		      # $t3 = $t1 + $t2
            sw		$t3, 0($t5)		            # salva a soma no registrador simulado 
            j           fim_exec

exec_addi:                                            # executa o addiu
            lw		$t0, rt		            # carrega o registrador onde será salvo
            sll         $t0, $t0, 2                   # registrador * 4
            lw		$t1, rs		            # carrega o primeiro valor a ser somado 
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, val16bits		      # carrega o segundo valor a ser somado
            sll         $t2, $t2, 16 
            sra         $t2, $t2, 16 
            la		$t4, registradores		# carrega endereço base dos registradores 
            
            add		$t0, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            add		$t3, $t4, $t1		      # $t3 = $t4 + $t1 (ENDEREÇO DO REGISTRADOR NO VETOR)
            lw		$t3, 0($t3)		            # carrega o valor do registrador 
            add		$t5, $t2, $t3		      # $t5 = valor do registrador + imediato                 
            sw		$t5, 0($t0)		            # salva a soma no registrador simulado 
            j           fim_exec

exec_lui:                                             # executa o load upper immediate
            lw		$t0, rt		            # carrega o rt 
            lw		$t2, val16bits		      # carrega o imediato 
            # sll         $t2, $t2, 16                  
            # sra         $t2, $t2, 16
            sll         $t0, $t0, 2                   # registrador * 4
            la		$t4, registradores		# carrega endereço base dos registradores 
            add		$t5, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            sll         $t3, $t2, 16                  # sll de 16 bits
            sw		$t3, 0($t5)		            # salva no registrador simulado            
            j           fim_exec

exec_ori:                                             # executa bitwise OR immediate
            lw		$t0, rt		            # carrega registrador target 
            sll         $t0, $t0, 2                   # registrador * 4
            
            la		$t4, registradores		# carrega endereço base dos registradores 
            add		$t5, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            lw		$t1, rs		            # t1 = rs
            lw		$t2, val16bits		      # t2 = valor de 16 bits 
            la		$t4, data 
            andi        $t4, $t4, 0X0000FFFF		# 
            add		$t2, $t2, $t4		      # 
            or          $t3, $t1, $t2
            sw		$t3, 0($t5)		            # 
            j           fim_exec

exec_lw:                                              # executa o load word
            la		$t0, registradores		# carrega endereço base dos registradores 
            lw		$t1, rt		            # carrega rt
            sll         $t1, $t1, 2                   # $t1 * 4
            add		$t1, $t1, $t0		      # $t1 = endereço do regitrador simulado 
            lw          $t3, val16bits                # carrega o offset
            lw		$t2, rs		            # carrega o endereco
            sll         $t2, $t2, 2                   # $t2 * 4
            add		$t2, $t2, $t0		      # $t2 = endereço + offset
            lw		$t4, 0($t2)		            # 
            add		$t2, $t3, $t4		      # $t2 = endereço + offset            
            lw		$t3, 0($t2)		            # busca na memoria  
            sw		$t3, 0($t1)		            # guarda o valor no registrador simulado 
            
            j           fim_exec

exec_sw:                                              # executa o save word
            la		$t0, registradores		# carrega endereço base dos registradores 
            lw		$t1, rt		            # carrega o valor de rt
            sll         $t1, $t1, 2                   # num do registrador * 4
            add		$t1, $t1, $t0		      # $t1 = endereço na memoria do registrador simulado
            lw		$t2, 0($t1)		            # carrega o conteudo do registrador 
            lw		$t3, rs		            # carrega rs
            sll         $t3, $t3, 2                   # num do registrador * 4
            add		$t3, $t3, $t0		      # $t3 = endereço na memoria do registrador simulado
            lw		$t3, 0($t3)		            # 
            lw          $t4, val16bits                # carrega o  offset
            add		$t5, $t3, $t4		      # endereço + offset
            sw		$t2, 0($t5)		            # salva na memória 
            j           fim_exec

# TIPO R
exec_add:                                             # executa uma soma
            lw		$t1, rt		            # carrega o registrador a ser somado
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, rs		            # carrega o registrador a ser somado
            sll         $t2, $t2, 2                   # registrador * 4
            lw		$t3, rd		            # carrega registrador de destino
            sll         $t5, $t3, 2                   # registrador * 4
            la		$t4, registradores		# carrega endereço base dos registradores
            add		$t1, $t1, $t4                 # soma end base + deslocamento
            add		$t2, $t2, $t4                 # soma end base + deslocamento
            add		$t3, $t4, $t5                 # soma end base + deslocamento
            lw		$t6, 0($t1)		            # carrega valor do registrador 
            lw		$t7, 0($t2)		            # carrega valor do registrador
            add		$t0, $t7, $t6		      # $t0 = $t7 + $t6 
            sw		$t0, 0($t3)		            # salva a soma no vetor de registradores                            
            j           fim_exec
exec_addu:                                            # executa soma com unsigned
            lw		$t1, rt		            # carrega o registrador a ser somado
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, rs		            # carrega o registrador a ser somado
            sll         $t2, $t2, 2                   # registrador * 4
            lw		$t3, rd		            # carrega registrador de destino
            sll         $t5, $t3, 2                   # registrador * 4
            la		$t4, registradores		# carrega endereço base dos registradores
            add		$t3, $t4, $t5                 # soma end base + deslocamento
            lw		$t6, 0($t1)		            # carrega valor do registrador 
            lw		$t7, 0($t2)		            # carrega valor do registrador
            addu		$t0, $t6, $t7		      # $t0 = $t6 + $t7 
            sw		$t0, 0($t3)		            # salva a soma no vetor de registradores 
           
            j            fim_exec
exec_jr:                                              # executa jump register
            lw		$t1, rs		            # carrega o registrador q contem o endereço
            sll         $t1, $t1, 2                   # registrador * 4
            la		$t2, registradores		# cerrega endereço base dos registradores 
            add		$t0, $t1, $t2		      # soma base + deslocamento
            lw          $t3, 0($t0)                   # carrega o endereço que será armazenado no pc 
            addiu	      $t3, $t3, -4			# $t3 = endereço - 4 (POr causa do incremento do pc no loop)
            la		$t4, pc		            # 
            sw		$t3, 0($t4)		            # coloca o endereço da instrução no pc 
            j           fim_exec

exec_mul:                                             # executa a multiplicação
            lw		$t1, rt		            # carrega valor a ser multiplicado
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, rs		            # carrega valor a ser multiplicado
            sll         $t2, $t2, 2                   # registrador * 4
            lw		$t3, rd		            # carrega registrador de destino
            la		$t4, registradores		# carrega endereço base dos registradores
            sll         $t5, $t3, 2                   # registrador * 4
            add		$t3, $t4, $t5                 # soma end base + deslocamento
            lw		$t6, 0($t1)		            # carrega valor do registrador 
            lw		$t7, 0($t2)		            # carrega valor do registrador
            mul		$t0, $t6, $t7		      # $t0 = $t6 * $t7 
            sw		$t0, 0($t3)		            # salva a soma no vetor de registradores 
            j           fim_exec           

exec_syscall:                                         # 10, 1, 4, 11
            la		$t0, registradores		# cerrega endereço base dos registradores simulados
            lw          $a0, 16($t0)                  # carrega o conteudo de $a0 simulado       
            lw          $a1, 20($t0)                  # carrega o conteudo de $a1 simulado 
            lw          $a2, 24($t0)                  # carrega o conteudo de $a2 simulado 
            lw          $v0, 32($t0)                  # carrega o conteudo de $v0 simulado
            syscall
            sw          $a0, 16($t0)                  # carrega o conteudo de $a0 simulado       
            sw          $v0, 32($t0)                  # carrega o conteudo de $v0 simulado

            j           fim_exec           

#TIPO J
exec_jal:                                             # executa um jump and link
            la		$t2, instrucoes		      # carrega endereço base das instrucoes
            lw		$t1, val26bits		      # carrega o endereço
            subi	      $t3, $t1, 0X00100000          # valor imediato de 26 bits - 0X00100000  
            sll         $t3, $t3, 2                   # registrador * 4
            add		$t4, $t2, $t3		      # soma base + deslocamento
            addi	      $t4, $t4, -4			# $t4 = endereço - 4 (Por causa do incremento do pc no loop)
            lw          $t5, pc                       # carrega o endereço do pc simulado
            addi        $t5, $t5, 4                   # calculo endereço da próxima instrução
            la		$t6, registradores	      # carrega endereço base dos registradores simulados
            sw          $t5, 124($t6)                 # salva no ra simulado o valor de pc + 4
            sw          $t4, pc                       # salva o endereço no pc simulado
            j           fim_exec

exec_j:                                               # executa um jump
            li          $t0, end_inicial_texto        # $t0 recebe 0x00400000
            lw		$t1, val26bits		      # carrega o endereço
            la		$t2, registradores		# cerrega endereço base dos registradores simulados
            sub		$t3, $t1, $t0	      	# $t3 = valor imediato de 26 bits - 0x0040000
            add		$t4, $t2, $t3		      # soma base + deslocamento
            addiu	      $t4, $t4, -4			# $t4 = endereço - 4 (POr causa do incremento do pc no loop)
            sw          $t4, pc                       # pc recebe o endereco da instrução
            
            j           fim_exec

fim_exec:
            jr          $ra                                 # retornamos ao procedimento chamador
