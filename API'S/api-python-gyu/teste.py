import psutil
import threading
import time
import keyboard
import socket
import mysql.connector
import datetime
from cred import usr, pswd

event = threading.Event()
print(event)

mydb = None 

def stop():
    event.set()
    print("\nFinalizando monitoramento")
    print(event)

keyboard.add_hotkey("esc", stop)

while not event.is_set():
    try:
        if mydb is None or not mydb.is_connected():
            mydb = mysql.connector.connect(host='localhost', user=usr, password=pswd, database='nocLine')

        memoria = psutil.virtual_memory()
        hostname = socket.gethostname()

    # Memória
        memoria_disponivel = memoria.available
        memoria_total = memoria.total


        ultimo_boot_timestamp = psutil.boot_time()

        # Obter a data e hora da última inicialização
        data_hora_inicializacao = datetime.datetime.fromtimestamp(ultimo_boot_timestamp).strftime("%Y-%m-%d %H:%M:%S")

        # Obter o timestamp atual
        timestamp_atual = datetime.datetime.now().timestamp()

        # Calcular o tempo decorrido em segundos
        tempo_decorrido_segundos = timestamp_atual - ultimo_boot_timestamp

        # Converter para horas
        tempo_decorrido_horas = tempo_decorrido_segundos / 3600

        # Exibir a data e o tempo decorrido
        print(f"Data da última inicialização: {data_hora_inicializacao}")
        print(f"Tempo decorrido desde a última inicialização: {tempo_decorrido_horas:.2f} horas")



        sql_query = "SELECT id_maquina, fk_empresaM FROM maquina WHERE hostname = %s;"            
        mycursor = mydb.cursor()
        mycursor.execute(sql_query, (hostname,))
                
        result = mycursor.fetchone()  
            
            
        if result:
            id_maquina, fk_empresaM = result
                    
            sql_query = """
            INSERT INTO monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida)
            VALUES (%s, now(), 'memoria disponivel', (SELECT id_componente from componente WHERE nome_componente = 'RAM' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s)),
                    (%s, now(), 'memoria total', (SELECT id_componente from componente WHERE nome_componente = 'RAM' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s)),
                    (%s, now(), 'tempo corrido em horas', (SELECT id_componente from componente WHERE nome_componente = 'SISTEMA' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s));
            """
            val = [memoria_disponivel, id_maquina, id_maquina, fk_empresaM, 'B',
                    memoria_total, id_maquina, id_maquina, fk_empresaM, 'B',
                   tempo_decorrido_horas, id_maquina, id_maquina, fk_empresaM, 'H'
                   ]

                    
            mycursor.execute(sql_query, val)
            mydb.commit()
            print(mycursor.rowcount, "registros inseridos no banco")
            print("\r\n")
            
    except mysql.connector.Error as e:
        print("Erro ao conectar com o MySQL:", e)

    finally:
        if mydb and mydb.is_connected():
            mycursor.close()

        time.sleep(30)  # Adicionado aqui se você desejar um atraso antes da próxima iteração
