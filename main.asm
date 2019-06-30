# Autor: Yuri Becker e Daniel Libanori
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

.eqv  tamanho_pilha                 200               # constante com o tamanho da pilha

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

contador:               .word 1                       # Contador do loop / numero de instrucoes já lidas

# strings de mensagens para o usuario
msg_qtd_intrucoes:            .asciiz "Numero de instrucoes que serão executadas (Max 98): "
msg_arquivo_nao_foi_aberto:   .asciiz "\nArquivo nao pode ser aberto \n"
msg_arquivo_aberto:           .asciiz "Arquivo aberto com sucesso! \n" 
msg_output:                   .asciiz "\nOutput do simulador:  "
msg_registrador:              .asciiz "\nRegistrador simulado número "
msg_hex:                      .asciiz " --> HEX: "
msg_decimal:                  .asciiz " - DECIMAL: "
quebra_linha:                 .asciiz "\n"

# segmento de texto (programa)
###################################################################################################################
.text
main:
		la          $t0, instrucoes               # carrega o endereço da primeira instrução
		sw          $t0, pc                       # inicializa o valor de PC com o endereço da primeira instrução
            la          $t0, pilha                    # $t0 = endereço da pilha
            addi	      $t4, $t0, tamanho_pilha		# $t4 = end pilha + 200 (tamanho total)
            la	      $t3, registradores		# carrega o endereco dos registradores simulados
            sw	      $t4, 116($t3)		      # salva o endereço final da pilha simulada no registrador simulado na posição 29 ($sp)
            
		li          $v0, servico_imprime_string 
		la          $a0, msg_qtd_intrucoes
		syscall                                   # Mostra mensagem perguntando o numero de instrucoes
		li          $v0, servico_le_input  
		syscall                                   # le input do teclado
		sw          $v0, qtd_instrucoes           # salva valorm informado pelo usuario
	         
            la          $a0, nome_arquivo_data 
            la          $a1, descritor_data
            jal         abre_arquivo                  # abrimos o arquivo data.bin para a leitura  
		lw          $a0, descritor_data           # $a0 = o valor do descritor do arquivo
            la          $a1, data                     # $a1 = endereço do instrucoes que guarda os carcateres lidos
            jal         leia_caracteres_arquivo		# pula para leia_caracteres_arquivo e salva a prox posicao no $ra

            la          $a0, nome_arquivo_text 
            la          $a1, descritor_text
            jal         abre_arquivo                  # abrimos o arquivo text.bin para a leitura
		lw          $a0, descritor_text           # $a0 = o valor do descritor do arquivo
            la          $a1, instrucoes               # $a1 = endereço do instrucoes que guarda os carcateres lidos
            jal         leia_caracteres_arquivo		# pula para leia_caracteres_arquivo e salva a prox posicao no $ra

            jal         fecha_arquivos                # fecha os dois arquivos 
      
            li          $v0, servico_imprime_string 
		la          $a0, msg_output               # Mostra mensagem informando o output do processador q será simulado
		syscall                                   # chamada ao sistema

            j           busca_instrucao               # pula para busca da instrucao 
		
# lemos o arquivo e colocamos na memória
leia_caracteres_arquivo:
            li          $v0, servico_leia_arquivo     # serviço 14: leitura do arquivo
            li          $a2, 4096                     # $a2 = número máximo de carcateres lidos
            syscall                                   # fazemos a leitura de caracateres do arquivo para o instrucoes
            move        $s0, $v0                      # armazenamos o número de caracteres lidos em $s0
            move        $s1, $a1                      # armazenamos o endereço das instrucoes em $s1                                     
            jr          $ra 					# retorna para o procedimento chamador 
            
arquivo_aberto_com_sucesso:
            la          $t0, descritor_text           # $t0 = endereço da variável descritor_arquivo
            sw          $v0, 0($t0)                   # armazenamos na variável descritor_arquivo seu valor

abre_arquivo:
            addiu       $sp, $sp, -4                  # será adicionado um elemento na pilha
            sw          $a1, 0($sp)                   # guardamos na pilha o endereço da variável descritor do arquivo
            li          $v0, servico_abre_arquivo     # serviço 13: abre um arquivo
            li          $a1, 0                        # $a1 = 0: arquivo será aberto para leitura
            li          $a2, 0                        # modo não é usado. Use o valor 0.
            syscall                                   # abre o arquivo

            lw          $a1, 0($sp)                   # carregamos o endereço da variável com o descritor do arquivo
            sw          $v0, 0($a1)                   # armazenamos o descritor do arquivo em descritor_arquivo
            slt         $t0, $v0, $zero               # $t0 = 1 se $v0 < 0 ($v0 negativo)
            bne         $t0, $zero, arquivo_nao_foi_aberto  # se $v0 é negativo, o arquivo não pode ser aberto
            j           arquivo_foi_aberto            # pula para o procedimento 

arquivo_nao_foi_aberto:
            li          $v0, servico_imprime_string   # serviço 4: imprime uma string
            la          $a0, msg_arquivo_nao_foi_aberto     # $a0 armazena o endereço da string a ser apresentada
            syscall                                   # apresenta a string
            j           fim_programa                  # termina o programa

arquivo_foi_aberto:
            li          $v0, servico_imprime_string   # serviço 4: imprime uma string
            la          $a0, msg_arquivo_aberto       # $a0 possui o endereço da string a ser apresentada
            syscall                                   # apresenta a string
            addiu       $sp, $sp, 4                   # restauramos a pilha   
            jr          $ra                           # retornamos ao procedimento chamador 

busca_instrucao:                                  
            lw 	      $t3, contador   			# carrega o contador
            lw          $t4, pc                       # carrega valor de pc
            lw	      $t5, 0($t4)		            # busca instrucao
            sw	      $t5, ir		            # IR recebe a instrucao que sera executada   
            lw          $t2, qtd_instrucoes           # passa o numero de instrucoes informado pelo usuario       
            bgt 	      $t3, $t2, printa_regs        # Verifica se ja mostrou a quantidade de instrucoes solicitada pelo usuário 
		           
            jal	      decodifica_bin			# pula para decodifica_bin e salva a prox instrução no $ra
            jal         decodifica_tipo               # pula para decodifica_tipo e salva a prox instrução no $ra                              
            
            lw 	      $t3, contador   			# carrega o contador
            lw          $t4, pc                       # carrega valor de pc
            addi        $t3, $t3, 1                   # contador++
            addi	      $t4, $t4, 4			      # pc = pc + 4
            sw          $t3, contador		      # Salva valor do contador
            sw          $t4, pc		            # Salva valor do pc
            j           busca_instrucao               # pulamos para o procedimento busca_instrução

fecha_arquivos:
            li          $v0, servico_fecha_arquivo    # serviço 16: fecha um arquivo
            la          $t0, descritor_text           # $t0 = endereço do descritor do arquivo
            lw          $a0, 0($t0)                   # carregamos em $a0 o descritor do arquivo
            syscall                                   # fechamos o arquivo
            li          $v0, servico_fecha_arquivo    # serviço 16: fecha um arquivo
            la          $t0, descritor_data           # $t0 = endereço do descritor do arquivo
            lw          $a0, 0($t0)                   # carregamos em $a0 o descritor do arquivo
            syscall                                   # fechamos o arquivo
            jr          $ra                           # voltamos ao procedimento chamador

fim_programa:
	    	li          $v0, servico_termina_programa # código para fechar o programa
	   	syscall                                   # chamada ao sistema

decodifica_bin:                                       # decodificamos todos os posiveis cabeçalhos binários
            lw	      $s0, ir                       # carregamos instrução
            li          $s2, mask_opcode              # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o opcode
            srl	      $s3, $s1, 26                  # jogamos o resultado para o final 
            sw	      $s3, opcode		            # salvamos na memória
      
            li          $s2, mask_rs                  # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o rs
            srl	      $s3, $s1, 21                  # jogamos o resultado para o fim
            sw	      $s3, rs		            # salvamos na memória
      
            li          $s2, mask_rt                  # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o rt
            srl	      $s3, $s1, 16                  # jogamos o resultado para o fim
            sw	      $s3, rt		            # salvamos na memória
      
            li          $s2, mask_rd                  # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o rd
            srl	      $s3, $s1, 11                  # jogamos o resultado para o fim
            sw	      $s3, rd		            # salvamos na memória
      
            li          $s2, mask_shift               # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o shift
            srl	      $s3, $s1, 6                   # jogamos o resultado para o fim
            sw	      $s3, shift		            # salvamos na memória
      
            li          $s2, mask_funct               # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o funct
            sw	      $s1, funct		            # salvamos na memória
      
            li          $s2, mask_val16bits           # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o endereco 16 bits
            sw	      $s1, val16bits		      # salvamos na memória
      
            li          $s2, mask_val26bits           # carregamos a marcara
            and         $s1, $s0, $s2                 # usamos a mascara para pegar o endereco 26 bits
            sw	      $s1, val26bits		      # salvamos na memória
      
            jr          $ra                           # voltamos ao procedimento chamador
            
decodifica_tipo:                                      # decodifica o tipo da instrucao usando o opcode 
            lw	      $t3, ir		            # carrega a instrução   
            lw	      $t5, opcode		            # carrega o opcode             
            
            li	      $t6, 3		            # $t6 = 3
            li	      $t1, 0X0000000C		      # $t1 = 0X0000000C (valor para identificação de uma syscall)
            
            beq	      $t3, $t1, tipo_syscall	      # verifica se é uma syscall
            beq	      $t5, $zero, tipo_r	      # verifica se é do tipo R
            bgt	      $t5, $t6, tipo_i	            # verifica se é do tipo I
            j	      tipo_j				# é do tipo J

tipo_syscall:
            addiu       $sp, $sp, -4                  # será adicionado um elemento na pilha
            sw          $ra, 0($sp)                   # guardamos na pilha o endereço de retorno
            jal         exec_syscall                  # executa a instrucao
            j           fim_decodifica_tipo           # finaliza

tipo_r:
            addiu       $sp, $sp, -4                  # será adicionado um elemento na pilha
            sw          $ra, 0($sp)                   # guardamos na pilha o endereço de retorno
            jal         exec_tipo_r                   # executa a instrucao
            j           fim_decodifica_tipo           # finaliza

tipo_j:
            addiu       $sp, $sp, -4                  # será adicionado um elemento na pilha
            sw          $ra, 0($sp)                   # guardamos na pilha o endereço de retorno
            jal         exec_tipo_j                   # executa a instrucao
            j           fim_decodifica_tipo           # finaliza

tipo_i:
            addiu       $sp, $sp, -4                  # será adicionado um elemento na pilha
            sw          $ra, 0($sp)                   # guardamos na pilha o endereço de retorno 
            jal         exec_tipo_i                   # executa a instrucao
            j           fim_decodifica_tipo           # finaliza

fim_decodifica_tipo:                                  # printa o tipo e finaliza
            lw	      $ra, 0($sp)                   # restaura valor do $ra           
            addiu       $sp, $sp, 4                   # restauramos a pilha   
            jr          $ra                           # retornamos ao procedimento chamador

exec_tipo_i:
            lw          $t0, opcode                   # carrega o opcode
            
            li	      $t1, 0X05		            # $t1 = 0X05 (opcode bne)
            beq	      $t0, $t1, exec_bne	      # se opcode == opcode bne -> exec_bne

            li	      $t1, 0X08		            # $t1 = 0X08 (opcode addi)
            beq	      $t0, $t1, exec_addi	      # se opcode == opcode addi -> exec_addi

            li	      $t1, 0X09		            # $t1 = 0X09 / (opcode addiu)
            beq	      $t0, $t1, exec_addiu	      # se opcode == opcode addiu -> exec_addiu

            li	      $t1, 0X0F		            # $t1 = 0X0F / (opcode lui)
            beq	      $t0, $t1, exec_lui	      # se opcode == opcode lui -> exec_lui

            li	      $t1, 0X0D		            # $t1 = 0X0D / (opcode ori)
            beq	      $t0, $t1, exec_ori	      # se opcode == opcode ori -> exec_ori

            li	      $t1, 0X23		            # $t1 = 0X23 / (opcode lw)
            beq	      $t0, $t1, exec_lw	            # se opcode == opcode lw -> exec_lw

            li	      $t1, 0X2B		            # $t1 = 0X2B / (opcode sw)
            beq	      $t0, $t1, exec_sw	            # se opcode == opcode sw -> exec_sw

exec_tipo_j:
            lw          $t0, opcode

            li	      $t1, 0X03	                  # $t1 = 0X03 / (opcode jal)
            beq	      $t0, $t1, exec_jal	      # se opcode == opcode jal -> exec_jal

            li	      $t1, 0X02		            # $t1 = 0X09 / (opcode addiu)
            beq	      $t0, $t1, exec_j	            # se $t0 == opcode j -> exec_j

exec_tipo_r:
            lw	      $t5, funct		            # carrega valor de func 
            lw	      $t4, opcode		            # carrega o valor do opcode 
                        
            li	      $t6, 0X0000001c 		      # $t6 = 0X0000001c (opcode mul)
            beq	      $t4, $t6, exec_mul            # se opcode == opcode mul -> executa mul
            li	      $t6, 0X00000020 		      # $t6 = 0X00000020 (opcode add)
            beq	      $t5, $t6, exec_add	      # se opcode == opcode add -> add
            li	      $t6, 0X00000021 		      # $t6 = 0X00000020 (opcode addu)
            beq	      $t5, $t6, exec_addu	      # se opcode == opcode addu -> addu
            li	      $t6, 0X00000008 		      # $t6 = 0X00000020 (opcode jr)
            beq	      $t5, $t6, exec_jr	            # se opcode == opcode jr -> jr

# TIPO I
exec_bne:                                             # executa bne
   # Carrega valores da instrução
            lw          $t0, rt                       # carrega rt
            lw          $t1, rs                       # carrega rs
            la          $t3, registradores            # carrega enredeço base dos registradores
            sll         $t0, $t0, 2                   # rt * 4
            sll         $t1, $t1, 2                   # rs * 4
            add         $t0, $t3, $t0                 # endereço base + posição do registrador em rt
            add         $t1, $t3, $t1                 # endereço base + posição do registrador em rs
            lw		$t1, 0($t1)		            # carrega valor do registrador simulado
            lw		$t0, 0($t0)		            # carrega valor do registrador simulado
            
            bne         $t1, $t0, registradores_diferentes    # instrução será exeutada caso for falsa
            j           fim_exec                              # segue para próxima instrução ($t1 == $t0)
            
            registradores_diferentes:
                  lw          $t2, val16bits                # carrega o imediato de 16bits
                  sll         $t2, $t2, 2                   # offset * 4
                  lw		$t3, pc		            # carrega o pc simulado
                  add		$t3, $t3, $t2		      # $t3 = pc + $t2
                  sw          $t3, pc                       # salva o endereço da instrução no pc simulado
                  j           fim_exec                      # segue para próxima instrução

exec_addiu:                                           # executa o addiu
            lw		$t1, rs		            # carrega o primeiro registrador a ser somado
            sll         $t1, $t1, 2                   # registrador * 4 
            lw		$t2, val16bits		      # carrega o imediasto de 16 bits
            sll         $t2, $t2, 16                  # arruma os bits para realizar os cálculos com números negativos      
            sra         $t2, $t2, 16                  # arruma os bits para realizar os cálculos com números negativos
            la		$t4, registradores		# carrega endereço base dos registradores 
            lw		$t0, rt		            # carrega o registrador onde será salvo
            sll         $t0, $t0, 2                   # registrador * 4
            
            add		$t6, $t4, $t1		      # $t6 = $t1 + $t4 (ENDEREÇO DO REGISTRADOR NO VETOR)
            lw		$t1, 0($t6)		            # carrega valor do registrador simulado 
            add		$t5, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            addu		$t3, $t1, $t2		      # $t3 = valor do regitrador + imediato
            sw		$t3, 0($t5)		            # salva a soma no registrador simulado 
            j           fim_exec

exec_addi:                                            # executa o addiu
            lw		$t0, rt		            # carrega o registrador onde será salvo
            sll         $t0, $t0, 2                   # registrador * 4
            lw		$t1, rs		            # carrega o primeiro valor a ser somado 
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, val16bits		      # carrega o segundo valor a ser somado
            sll         $t2, $t2, 16                  # arruma os bits
            sra         $t2, $t2, 16                  # arruma os bits        
            la		$t4, registradores		# carrega endereço base dos registradores 
            
            add		$t0, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            add		$t3, $t4, $t1		      # $t3 = $t4 + $t1 (ENDEREÇO DO REGISTRADOR NO VETOR)
            lw		$t3, 0($t3)		            # carrega o valor do registrador 
            add		$t5, $t2, $t3		      # $t5 = valor do registrador + imediato                 
            sw		$t5, 0($t0)		            # salva a soma no registrador simulado 
            j           fim_exec

exec_lui:                                             # executa o load upper immediate
            lw		$t0, rt		            # carrega o rt 
            sll         $t0, $t0, 2                   # registrador * 4
            lw		$t2, val16bits		      # carrega o imediato 
            la		$t4, registradores		# carrega endereço base dos registradores 
            sll         $t2, $t2, 16                  # sll de 16 bits
            add		$t5, $t4, $t0		      # $t5 = $t4 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            sw		$t2, 0($t5)		            # salva no registrador simulado            
            j           fim_exec

exec_ori:                                             # executa bitwise OR immediate
            lw		$t0, rt		            # carrega registrador destino 
            sll         $t0, $t0, 2                   # registrador * 4
            lw		$t1, rs		            # t1 = rs
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, val16bits		      # t2 = valor de 16 bits 
            la		$t3, registradores		# carrega endereço base dos registradores 
           
            add		$t0, $t3, $t0		      # $t0 = $t3 + $t0 (ENDEREÇO DO REGISTRADOR NO VETOR)
            add		$t1, $t3, $t1		      # $t1 = $t3 + $t1 (ENDEREÇO DO REGISTRADOR NO VETOR)
            lw		$t1, 0($t1)		            # carrega o valor de dentro do registrador simulado
            or          $t4, $t2, $t1                 # realiza o OR entre o imediato e o valor do registrador
            sw		$t4, 0($t0)		            # salva o resultado no registrador rt
            j           fim_exec

exec_lw:                                              # executa o load word
            la		$t0, registradores		# carrega endereço base dos registradores 
            lw		$t1, rt		            # carrega rt
            sll         $t1, $t1, 2                   # $t1 * 4
            add		$t1, $t1, $t0		      # $t1 = endereço do regitrador simulado 
            lw          $t3, val16bits                # carrega o offset
            lw		$t2, rs		            # carrega o rs
            sll         $t2, $t2, 2                   # $t2 * 4
            add		$t2, $t2, $t0		      # $t2 = endereço + offset
            lw		$t4, 0($t2)		            # carrega o valor de dentro do registrador 
            add		$t2, $t3, $t4		      # $t2 = valor carregado + offset            
            lw		$t3, 0($t2)		            # busca na memoria  
            sw		$t3, 0($t1)		            # guarda o valor no registrador simulado 
            j           fim_exec

exec_sw:                                              # executa o save word
            la		$t0, registradores		# carrega endereço base dos registradores 
            lw		$t1, rt		            # carrega o valor de rt
            sll         $t1, $t1, 2                   # num do registrador * 4
            add		$t1, $t1, $t0		      # $t1 = endereço de memoria do registrador simulado
            lw		$t2, 0($t1)		            # carrega o conteudo do registrador 
            lw		$t3, rs		            # carrega rs
            sll         $t3, $t3, 2                   # num do registrador * 4
            add		$t3, $t3, $t0		      # $t3 = endereço de memoria do registrador simulado
            lw		$t3, 0($t3)		            # carrega o valor dentro do registrador
            lw          $t4, val16bits                # carrega o  offset
            add		$t5, $t3, $t4		      # endereço + offset
            sw		$t2, 0($t5)		            # salva no registrador simulado na memória
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
            sll         $t3, $t3, 2                   # registrador * 4
            la		$t4, registradores		# carrega endereço base dos registradores
            
            add		$t1, $t1, $t4		      # $t1 = $t1 + $t4
            add		$t2, $t2, $t4		      # $t2 = $t2 + $t4
            add		$t3, $t3, $t4		      # $t3 = $t3 + $t4
            
            lw		$t1, 0($t1)		            # carrega valor do registrador 
            lw		$t2, 0($t2)		            # carrega valor do registrador
                 
            addu		$t0, $t1, $t2		      # $t0 = $t1 + $t2 
            sw		$t0, 0($t3)		            # salva a soma no vetor de registradores 
           
            j            fim_exec
exec_jr:                                              # executa jump register
            lw		$t1, rs		            # carrega o registrador q contem o endereço
            sll         $t1, $t1, 2                   # registrador * 4
            la		$t2, registradores		# cerrega endereço base dos registradores 
            add		$t0, $t1, $t2		      # soma base + deslocamento
            lw          $t3, 0($t0)                   # carrega o endereço que será armazenado no pc 
            addiu	      $t3, $t3, -4			# $t3 = endereço - 4 (Por causa do incremento do pc no loop do busca_instrução)
            la		$t4, pc		            # carrega o endereço de pc
            sw		$t3, 0($t4)		            # coloca o endereço da instrução no pc 
            j           fim_exec

exec_mul:                                             # executa a multiplicação
            lw		$t1, rt		            # carrega valor a ser multiplicado
            sll         $t1, $t1, 2                   # registrador * 4
            lw		$t2, rs		            # carrega valor a ser multiplicado
            sll         $t2, $t2, 2                   # registrador * 4
            lw		$t3, rd		            # carrega registrador de destino
            sll         $t3, $t3, 2                   # registrador * 4
            la		$t4, registradores		# carrega endereço base dos registradores
   
            add		$t1, $t1, $t4                 # soma end base + deslocamento
            add		$t2, $t2, $t4                 # soma end base + deslocamento
            add		$t3, $t3, $t4                 # soma end base + deslocamento
            lw		$t6, 0($t1)		            # carrega valor do registrador 
            lw		$t7, 0($t2)		            # carrega valor do registrador
            mul		$t0, $t6, $t7		      # $t0 = $t6 * $t7 
            sw		$t0, 0($t3)		            # salva a soma no vetor de registradores 
            j           fim_exec           

exec_syscall:                                         # 10, 1, 4, 11
            la		$t0, registradores		# carrega endereço base dos registradores simulados
            lw          $a0, 16($t0)                  # carrega o conteudo de $a0 simulado       
            lw          $v0, 8($t0)                   # carrega o conteudo de $v0 simulado
            
            li		$t1, 10		            # $t1 = 10
            beq		$v0, $t1, printa_regs	      # verifica se é um comando para finalizar o programa, se for printa os registradores antes de finalizar
            syscall
            
            sw          $v0, 8($t0)                   # salva o conteudo de $v0 simulado
            sw          $a0, 16($t0)                  # salva o conteudo de $a0 simulado       

            j           fim_exec           

printa_regs:      

            li	      $s0, 0                        # inicializa $s0 com 0
            
printa:            
            li		$t3, 128		            # $t3 = 128 = 31 * 4
            beq		$s0, $t3, fim_programa	      # verifica se já imprimiu todos registradores, caso já tenha terminado finaliza o programa
            
            li          $v0, servico_imprime_string 
		la          $a0, msg_registrador          # Mostra mensagem informando o registrador
		syscall                                   # chamada ao sistema            
            
            li		$t1, 4 		            # $t1 = 4   
            div		$s0, $t1			      # divide a posição no vetor percorrido por 4 para saber o número do registrador       
            mflo	      $t1                           # $t1 recebe a divisão
             
            li          $v0, servico_imprime_int 
		move 	      $a0, $t1		            # $a0 = $01
            syscall                                   # imprime o número do registrador na tela

            li          $v0, servico_imprime_string 
		la          $a0, msg_hex                  # Mostra mensagem que printa uma seta na tela ( -> HEX: )
		syscall                                   # chamada ao sistema        

            li          $v0, servico_imprime_hexa 
		la		$t4, registradores		# carrega o endereço base dos registradores
            add		$s2, $t4, $s0		      # calcula o endereço do registrador dentro do vetor de registradores
            lw		$a0, 0($s2)		            # carrega o valor do registrador 
            syscall                                   # chamada ao sistema  

            li          $v0, servico_imprime_string 
		la          $a0, msg_decimal              # Mostra mensagem que printa uma seta na tela ( DECIMAL: )
		syscall                                   # chamada ao sistema        

            li          $v0, servico_imprime_int 
		la		$t4, registradores		# carrega o endereço base dos registradores
            add		$s2, $t4, $s0		      # calcula o endereço do registrador dentro do vetor de registradores
            lw		$a0, 0($s2)		            # carrega o valor do registrador 
            syscall                                   # chamada ao sistema  

            addi	      $s0, $s0, 4			      # incrementa o $s0 para o próximo registrador no vetor
            j printa

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
            lw		$t1, val26bits		      # carrega o endereço
            subi	      $t1, $t1, 0X00100000          # valor imediato de 26 bits - 0X00100000  
            sll         $t1, $t1, 2                   # registrador * 4
            la		$t2, instrucoes		      # carrega endereço base das instrucoes
            
            add		$t4, $t2, $t1		      # soma base + deslocamento
            addiu	      $t4, $t4, -4			# $t4 = endereço - 4 (Por causa do incremento do pc no loop de busca_instrução)
            sw          $t4, pc                       # pc recebe o endereco da instrução
            
            j           fim_exec

fim_exec:
            jr          $ra                           # retornamos ao procedimento chamador
