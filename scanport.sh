#!/bin/bash

# ---------------------------------------------------------------------------------------------
# Data: 22 de Setembro de 2016
# Criado por: Juliano Santos [x_SHAMAN_x]
# Página: https://www.facebook.com/shellscriptx
# Script: scanport.sh
# Descrição: Script utiliza o comando (netcat) que é um programa para consultoria de redes.
#			 que utilizei para escanear portas abertas em hosts remotos. o comando por si
#			 só já faz todo trabalho, o script apenas coordenou as informações a serem tratadas
#			 e os valores de retorno. :)
# ---------------------------------------------------------------------------------------------

# Script
SCRIPT=$(basename "$0")

# Arquivo temporário
OUT=/tmp/nc.out

ARG=0

# Erro
err_msg()
{
	# Imprime a mensagem de erro com os valores dos argumentos passados na função.
	# Se algum argumento for omitido, imprime o valor padrão.
	echo "$SCRIPT: erro: ${1:--}: ${2:-Erro Desconhecido}" 1>&2
	# Finaliza o script
	exit 1
}

# Argumentos inválidos.
err_arg()
{
	# Imprime mensagem em caso de parâmetros inválidos.
	echo -e "Tente '$0 --help' para mais informações."
	exit 1	# Finaliza o script
}

# Lê os parâmetros passados no script e armazena em 'ARGS'.
# Se houver algum parâmetro inválido finaliza o script.
if ! ARGS=$(getopt --options 'i:m:f:p:t:hv' --longoptions 'ip:,host:,file:,port:,timeout:,help,verbose' --name $SCRIPT -- "$@"); then err_arg; fi

# Se nenhum parâmetro for passado.
[ $# -eq 0 ] && err_arg

# Atribui todos os demais argumentos para os parâmetros posicionais.
eval set -- "$ARGS"

# Desloca o índice do 'getopt' para '1'
shift $(($OPTIND - 1))

# Executa o loop enquanto o número de descritores for maior que o indice.
while [ $# -gt $OPTIND ]
do
	# Lê o valor do descritor '$1', executa o parâmetro correspondente e trata os valores
	# Nos parâmetros com valores obrigatórios, desloca-se 2 posições (shift 2) para obter o próximo parâmetro
	# Nos parâmetros sem valores, desloca-se 1 posição (shift 1) para obter o próximo parâmetro.
	# Descrição: Parâmetro   Valor       Parâmetro    valor
	#				$1        $2		    $3         $4
	#			  --ip   192.168.1.100    --port       80
	#
	# shift 2
	# Resultado: Parâmetro   Valor
	#               $1        $2
	#             --port      80
	# Para tratar conflitos no uso de parâmetros obrigatórios, incrementa a variável 'ARG', indicando que
	# um parâmetro obrigatório foi passado.
	# Parâmetros obrigatórios:
	# -i|--ip, -h|--host, -f|--file
	case $1 in
		-i|--ip)
			IP="$2"
			# Verifica o padrão do 'IP/RANGE'
			# Padrão:
			# 192.168.1.10 -> IP
			# 192.168.1.10-192.168.1.40 -> RANGE
			[ "$(echo "$IP" | egrep "^(1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})$|^(1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})-(1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})[.](1?[0-9]{,2}|2[0-5]{,2})$")" ] || err_msg "'$IP'" "endereço de ip/range inválido."
			shift 2
			((ARG++))
			;;
		-m|--host)
			HOST="$2"
			shift 2
			((ARG++))
			;;
		-f|--file)
			FILE="$2"
			# Verifica se o arquivo existe.
			[ -e "$FILE" ] || err_msg "'$FILE'" "arquivo não encontrado."
			shift 2
			((ARG++))
			;;
		-p|--port)
			PORT="$2"
			# Testa o padrão da porta informada.
			# Padrão:
			# 80 -> Porta
			# 22-80 -> Range
			[ "$(echo "$PORT" | egrep  "^([0-9]{1,})$|^([0-9]{1,}-[0-9]{1,})$")" ] || err_msg "'$PORT'" "número da porta inválida."
			shift 2
			;;
		-t|--timeout)
			TIMEOUT="$2"
			# Verifica se o valor informado é número
			[[ "$TIMEOUT" == ?(+)+([0-9]) ]] || err_msg "'$TIMEOUT'" "valor do tempo limite inválido."
			shift 2
			;;
		-h|--help)
			# Ajuda
			echo "Uso: $0 [ip|host|file] [opcoes] [porta]"
			echo "Lista porta(s) aberta(s) em host(s) remoto."
			echo 
			echo "Opções:"
			echo "-i, --ip <ip>             IP ou Range de destino."
			echo "-m, --host <host>         Nome do computador de destino."
			echo "-f, --file <file>         Arquivo contendo uma lista personalizada de ip/host."
			echo "-p, --port <port>         Porta ou intervalo de portas de conexão."
			echo "-t, --timeout <timeout>   Tempo limite para estabelecer conexão em 'N' segundos."
			echo "-v, --verbose             Exibe as conexões malsucedidas."
			echo "-h, --help                Para obter mais informações."
			echo
			echo "Notas:"
			echo -e "\tPara determinar um intervalo utiliza-se o hifén '-' entre os valores."
			echo -e "\tSintaxe: valor_inicial-valor_final"
			exit 0
			;;
		-v|--verbose)
			# Ativa o modo verbose
			VERBOSE=true
			shift 1
			;;
		*)
			err_arg
			;;
	esac
done

# Verifica se há conflitos
[ $ARG -gt 1 ] && err_msg "" "Excesso de argumentos."

# Verfica se o argumento obrigatório foi omitido.
[ "$IP" -o "$HOST" -o "$FILE" ] || err_msg "" "requer ip/host destino."

# Número da porta foi omitido
[ "$PORT" ] || err_msg "" "requer número da porta."

# Desenhando a barra de título.
# Armazena 60 espaços na variável 'bar'
printf -v BAR '%*s' 60
BAR=${BAR// /-}		# Substitui cada espaço por '-'

# Imprime o título com as tabulações.
printf '%s\n' $BAR
printf 'IP/HOST\t\tPROTOCOLO\tSERVIÇO\tPORTA\tSTATUS\n'
printf '%s\n' $BAR

# Valor padrão
VERBOSE=${VERBOSE:-false}
TIMEOUT=${TIMEOUT:-3}

# Imprime os valores que é executado pelo 'eval'
PRINT='echo'

# Define o delimitador dos campos
IFS='-'

# Cria um array com o(s) número(s) da(s) porta(s).
PORT=($(echo "$PORT"))

# Verifica se no parâmetro '--port' foi informado uma única porta ou intervalo de portas
# Se apenas uma porta foi informada, armazena em 'IPORT' o valor do indice '0' da várivavel 'PORT'
# senão, armazena o padrão de intervalos '{portal_inicial..portal_final}'
[ ${#PORT[@]} -eq 1 ] && IPORT=${PORT[0]} || IPORT="{${PORT[0]}..${PORT[1]}}"

# Limpa o delimitador
unset IFS

# Trata o argumento obrigatório

# --host
if [ "$HOST" ]; then
	RANGE="$HOST"
# --ip
elif [ "$IP" ]; then
	# Define o delimitador do range
	IFS='-'
	# Cria um array contendo o(s) IP(s)
	IP=($(echo "$IP"))
	unset IFS

	# Se apenas um IP foi informado
	if [ ${#IP[@]} -eq 1 ]; then
		# Armazena o IP em 'RANGE'
		RANGE=${IP[0]}
	else 
		# Se um Range de IP foi especificado
		# Define o delimitador dos octetos
		IFS='.'

		# Armazena cada octeto em um indice
		# IPS_OCT - IP Inicial
		# IPE_OCT - IP Final
		IPS_OCT=($(echo "${IP[0]}"))
		IPE_OCT=($(echo "${IP[1]}"))
		
		# Limpa o delimitador
		unset IFS
		
		# Controi o padrão de intervalos entre os octetos do 'IP INICIAL' com 'IP FINAL'
		# Inicial: 192.168.0.100 (A)
		# Final:   192.168.1.200 (B)
		#
		# Octeto:      1          2       3        4
		# 			A    B     A    B    A  B    A   B
		# Padrão: {192..192}.{168..168}.{0..1}.{100..200}
		RANGE="{${IPS_OCT[0]}..${IPE_OCT[0]}}.{${IPS_OCT[1]}..${IPE_OCT[1]}}.{${IPS_OCT[2]}..${IPE_OCT[2]}}.{${IPS_OCT[3]}..${IPE_OCT[3]}}"
	fi
# --file
elif [ "$FILE" ]; then
	# Armazena o comando para ler o arquivo e desabilita a impressão de variáveis no for.
	RANGE="cat $FILE"
	unset PRINT		
fi

# Lê os elementos do 'RANGE'
for IP in $(eval $PRINT $RANGE)
do
	# Lê as portas
	for PORT in $(eval echo $IPORT)
	do
		# Escuta a porta do serviço no host especificado e redireciona a saida para '/tmp/nc.out'
		if nc -zv -w $TIMEOUT $IP $PORT &> $OUT; then
			
			# Se a porta estiver aberta, extrai do arquivo o protocolo e descrição
			# do serviço da porta e armazena em 'INFO'
			INFO=$(sed 's/[^[]*\([^]]*]\)[^[]*/\1/;s/\(\[\|\]\)//g' $OUT)
			PROTOCOL=$(echo "$INFO" | cut -d '/' -f1)	# Protocolo 
			SERVICE=$(echo "$INFO" | cut -d '/' -f2)	# Serviço
			STATUS="32m[ABERTA]"						# Status
			
			# Imprime progresso
			printf '%s\t%s\t\t%s\t%s\t\033[0;%s\033[0;m\n' "$IP" "$PROTOCOL" "$SERVICE" "$PORT" "$STATUS"
		
		# Se o modo verbose estiver ativado, imprime as conexões malsucedidas
		elif [ "$VERBOSE" == true ]; then
			STATUS="31m[FECHADA]"	# Status
			printf '%s\t%s\t\t%s\t%s\t\033[0;%s\033[0;m\n' "$IP" "$PROTOCOL" "$SERVICE" "$PORT" "$STATUS"
		fi
		
		# Limpa as informações armazenadas.
		unset PROTOCOL SERVICE INFO
	done
done

# Remove arquivo temporário
rm -f $OUT
# FIM
