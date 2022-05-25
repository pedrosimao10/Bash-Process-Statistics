#!/bin/bash

#Trabalho realizado por Pedro Jorge NMec: 98418

######## Verificar argumentos ##########
if (( $# == 0)); then
    echo "Por favor insira argumentos"
    exit
fi

####### Declarar arrays a serem usados durante o programa ########
declare -A quantiDados=()   	#neste array vai-se guardar a informação dos dados transmitidos e recebidos, a key é a interface
declare -A argumentos=()	    #neste array vai-se guardar a informação dos argumentos passados
declare -A total_tx=()			#neste array vai-se guardar o valor total do tx ao longo de s segundos
declare -A total_rx=()			#neste array vai-se guardar o valor total do rx ao longo de s segundos
declare -A array_loop=()		#neste array vai-se guardar a informação necessária para realizar o loop(TxTot e RxTot)
i=0						  		#variável inicializada a 0 que vai ser usada na validação das opções de ordenação
re='^[0-9]+([.][0-9]+)?$'       #expressão regex usada para validar as opções passadas como argumento
segundos=${@: -1}				#número de segundos usados para calcular as transferências

####### Tratar das opções passadas como argumentos ########
while getopts "c:lbkmtrTRvp:" opcao; do		#indicar todas as opções disponíveis
	if [[ -z "$OPTARG" ]]; then            	#guardar todas na variável $OPTARG    
		argumentos[$opcao]="Inválido"		#caso a opção não exista, adiciona "inválido" ao array dos argumentos
	else
		argumentos[$opcao]=$OPTARG		#caso a opção exista, adicionar ao array
	fi

	case $opcao in
	#Seleção das interfaces de rede a visualizar através de uma expressão regular
	c)
        exp=${argumentos['c']}
		if [[ $exp == 'Inválido' || ${exp:0:1} == "-" ]]; then   #caso a opção passada não seja válida ou se não foi passado o traço atrás do argumento
			echo "Introduzido argumento inválido ou -c não foi preenchido"
			exit 1
		fi
		;;
	
	#Visualização em loop
	l)
		;;	

	#Visualização realizada em bytes
	b) 
		exp=${argumentos['b']}
		if [[  $exp =~ $re || ${exp:0:1} == "-" ]]; then   #caso a opção passada não seja um número ou se não foi passado o traço atrás do argumento
			echo "Introduzido argumento inválido. O argumento a passar tem de ser um número"
			exit 1
		fi
		;;

	#Visualização realizada em kilobytes
	k) 
		exp=${argumentos['k']}
		if [[  $exp =~ $re || ${exp:0:1} == "-" ]]; then   #caso a opção passada não seja um número ou se não foi passado o traço atrás do argumento
			echo "Introduzido argumento inválido. O argumento a passar tem de ser um número"
			exit 1
		fi
		;;

	#Visualização realizada em megabytes
	m) 
		exp=${argumentos['m']}
		if [[  $exp =~ $re || ${exp:0:1} == "-" ]]; then   #caso não seja um número ou se não foi passado o traço atrás do aegumento
			echo "Introduzido argumento inválido. O argumento a passar tem de ser um número"
			exit 1
		fi
		;;

	#Ordenar em reverse
	v)

		;;
	t | T | r | R)

		if [[ $i == 1 ]]; then     #quando houver mais do que 1 argumento de ordenação
			exit 1
		else
			i = 1				 #quando algum argumento for de ordenação i=1
		fi
		;;

	#Número de processos a visualizar
	p)
        if ! [[ ${argumentos['p']} =~ $re ]]; then
            echo "Introduzido argumento inválido"
            exit 1
        fi
        ;;
	
	#Argumentos inválidos
	*)
		echo "Argumento inválido. Por favor introduza um argumento válido"
		exit 1
		;;
	esac
done

######## Verificar se último argumento passado é um número #########
if ! [[ ${@: -1} =~ $re ]]; then
	echo "Por favor introduza um número como último argumento."
	exit 1
fi

######## Função para tratar a quantidade de dados recebidos e envidados nas interfaces de rede
function principal() {
	for iface in $(ifconfig | cut -d ' ' -f1| tr ':' '\n' | awk NF)
	do
		tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes)
		rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
		if [[ $tx1 == 0 && $rx1 == 0 ]]; then
			continue
		else
			TX1[$iface]=$(printf "%12d\n" "$tx1")
			RX1[$iface]=$(printf "%12d\n" "$rx1")
		fi
	done

	sleep $segundos  #segundos a usar para calcular a transferência de dados, primeiro parâmetro a ser passado

	for iface in $(ifconfig | cut -d ' ' -f1| tr ':' '\n' | awk NF)
	do
		tx2=$(cat /sys/class/net/$iface/statistics/tx_bytes)
		rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
		if [[ $tx2 == 0 && $rx2 == 0 ]]; then					#ao implementar esta opção todas as interfaces vão aparecer na tabela mesmo que contenham o valor 0
			#diftx=0											#de forma a aparecerem as interfaces basta descomentar estas linhas todas
			#difrx=0
			#tRate=0  
			#rRate=0
			#quantiDados[$iface]=$(printf "%-15s %-10s %10s %10s %10s\n" "$iface" "$diftx" "$difrx" "$tRate" "$rRate")
			continue		
		else
			diftx=$(($tx2-${TX1[$iface]}))
			difrx=$(($rx2-${RX1[$iface]}))

			#### Mostrar valores em Bytes ###
			if [[ -v argumentos[b] ]]; then			
				tRate=$(echo "scale=1; $diftx/$segundos" | bc -l)   
				rRate=$(echo "scale=1; $difrx/$segundos" | bc -l)  
				quantiDados[$iface]=$(printf "%-15s %-10s %10s %10s %10s\n" "$iface" "$diftx" "$difrx" "$tRate" "$rRate")

			#### Mostrar valores em Kilobytes ####
			elif [[ -v argumentos[k] ]]; then		
				kilobyte=1024
				diftxKilo=$(echo "scale=3; $diftx/$kilobyte" | bc -l)
				difrxKilo=$(echo "scale=3; $diftx/$kilobyte" | bc -l)
				tRate=$(echo "scale=3; $diftxKilo/$segundos" | bc -l)   
				rRate=$(echo "scale=3; $difrxKilo/$segundos" | bc -l)
				tRate=${tRate/#./0.} 	 #adicionar 0 atrás, questão de estética
				rRate=${rRate/#./0.}  	 #adicionar 0 atrás, questão de estética
				quantiDados[$iface]=$(printf "%-15s %-10s %10s %10s %10s\n" "$iface" "$diftxKilo" "$difrxKilo" "$tRate" "$rRate")
			
			####Mostrar valores em Megabytes ######
			elif [[ -v argumentos[m] ]]; then
				megabyte=1048576			#multiplicar 1024*1024 para obter os megabytes
				diftxMega=$(echo "scale=3; $diftx/$megabyte" | bc -l)			#3 casas decimais de forma se possível observar o resultado
				difrxMega=$(echo "scale=3; $diftx/$megabyte" | bc -l)			#3 casas decimais de forma se possível observar o resultado
				tRate=$(echo "scale=3; $diftxMega/$segundos" | bc -l)   				#3 casas decimais de forma se possível observar o resultado
				rRate=$(echo "scale=3; $difrxMega/$segundos" | bc -l)					#3 casas decimais de forma se possível observar o resultado
				tRate=${tRate/#./0.}     #adicionar 0 atrás, questão de estética
				rRate=${rRate/#./0.}	 #adicionar 0 atrás, questão de estética
				quantiDados[$iface]=$(printf "%-15s %-10s %10s %10s %10s\n" "$iface" "$diftxMega" "$difrxMega" "$tRate" "$rRate")
			
			#### Caso não seja passado nenhum argumento específico, mostrar valores em bytes####3
			else
				tRate=$(echo "scale=1; $diftx/$segundos" | bc -l)   
				rRate=$(echo "scale=1; $difrx/$segundos" | bc -l)  
				quantiDados[$iface]=$(printf "%-15s %-10s %10s %10s %10s\n" "$iface" "$diftx" "$difrx" "$tRate" "$rRate")
			fi
		fi
	done

	######### Prints #########

	if ! [[ -v argumentos[v] ]]; then     #ordenar em reverse
		order="-rn"
	else
		order="-n"
	fi

	if ! [[ -v argumentos[p] ]]; then     #caso não seja passado valor ao -p printa todos os processos
		p=${#quantiDados[@]}
	
	elif [[ ${argumentos['p']} -gt ${#quantiDados[@]} ]]; then			#caso o número de interfaces a ser visualizada seja superior ao número de interfaces disponíveis
		echo "Erro. Foi selecionado visualizar um número de processos maior ao atualmente disponível"
		exit 1
	else
		p=${argumentos['p']}			  #passar número de argumentos pretendidos
	fi

	if [[ -v argumentos[c] ]]; then    #verificar expressão regular passada
		array_test=() 					 #criar array para guardar as interfaces
		for x in $(ifconfig | cut -d ' ' -f1| tr ':' '\n' | awk NF)
		do
			array_test+=("$x")  		 #adicionar ao array as interfaces
			for i in "${array_test[@]}";do
				if [[ ! $i =~ ${argumentos['c']} ]]; then   #selecionar processos a visualizar através da expressão regular
					unset quantiDados[$i]					#retirar do array quantiDados todas as interfaces que não sejam iguais à expressão regular passada
				fi
			done
		done
	fi

	if [[ -v argumentos[l] ]]; then
		total_tx[$iface]=$((${total_tx[$iface]}+$diftx))
		total_rx[$iface]=$((${total_rx[$iface]}+$difrx))
		array_loop[$iface]=$(printf "%-10s %8d %8d %8s %8s %8d %8d\n" "$iface" "$diftx" "$difrx" "$tRate" "$rRate" "${total_tx[$iface]}" "${total_rx[$iface]}")
		printf '%s \n' "${array_loop[@]}"
	fi


	if [[ -v argumentos[t] ]]; then       #ordenar pela pelo Tx
		printf '%s \n' "${quantiDados[@]}" | sort $order -k2 | head -n $p

	elif [[ -v argumentos[r] ]]; then       #ordenar pela pelo Rx
		printf '%s \n' "${quantiDados[@]}" | sort $order -k3 | head -n $p
	
	elif [[ -v argumentos[T] ]]; then       #ordenar pela pelo TRate
		printf '%s \n' "${quantiDados[@]}" | sort $order -k4 | head -n $p
	
	elif [[ -v argumentos[R] ]]; then       #ordenar pela pelo RRate
		printf '%s \n' "${quantiDados[@]}" | sort $order -k5 | head -n $p
	
	else									#ordenar pela ordem alfabética dos procesoss
		order="-n"
		printf '%s \n' "${quantiDados[@]}" | sort $order -k1 | head -n $p
	fi
}

function escolha(){
	if [[ ! -v argumentos[l] ]]; then
		printf "%-15s %-10s %10s %10s %10s\n" "NETIF" "TX" "RX" "TRATE" "RRATE"
		principal ${@: -1}
	else
		printf "%10s %8s %8s %8s %8s %8s %8s\n" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT"
		while true
		do
			principal ${@: -1}
		done
	fi
}
escolha ${@: -1}