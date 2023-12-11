import psutil
import threading
import time
import keyboard
import socket
import pymssql
import mysql.connector
import json
import requests
from datetime import datetime
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

        # Verificar se a máquina com id_maquina 1 existe
        check_machine_query = "SELECT id_maquina FROM maquina WHERE id_maquina = 1;"
        check_machine_cursor = mydb.cursor()
        check_machine_cursor.execute(check_machine_query)
        machine_exists = check_machine_cursor.fetchone()

        if machine_exists:
            # Máquina com id_maquina 1 existe, obter o timestamp da última reinicialização
            ultimo_boot_timestamp = psutil.boot_time()
            ultimo_boot_formatado = datetime.fromtimestamp(ultimo_boot_timestamp).strftime("%Y-%m-%d %H:%M:%S")

            # Atualizar a tabela maquina com o novo timestamp
            update_machine_query = "UPDATE maquina SET data_ultima_inicializacao = %s WHERE id_maquina = %s;"
            update_machine_cursor = mydb.cursor()
            update_machine_cursor.execute(update_machine_query, (ultimo_boot_formatado, 1))
            mydb.commit()

            print("Data_ultima_inicializacao atualizada na tabela maquina.")

            # Restante do código para inserir os dados de monitoramento
            sql_query = "SELECT id_maquina, fk_empresaM FROM maquina WHERE hostname = %s;"
            mycursor = mydb.cursor()
            mycursor.execute(sql_query, (hostname,))
            
            result = mycursor.fetchone()

            if result:
                id_maquina, fk_empresaM = result

                try:
                    mydb_server = pymssql.connect(server='52.22.58.174', database='nocline', user='sa', password='urubu100')

                    try:
                        mycursor_server = mydb_server.cursor()
                        sql_query_server = "SELECT id_maquina, fk_empresaM FROM maquina WHERE hostname = %s;"
                        mycursor_server.execute(sql_query_server, (hostname,))
                        result = mycursor_server.fetchone()

                        ultimo_boot_timestamp = psutil.boot_time()
                        ultimo_boot_formatado = datetime.fromtimestamp(ultimo_boot_timestamp).strftime("%Y-%m-%d %H:%M:%S")

                        test_update_query_server = "UPDATE maquina SET data_hora_inicializacao = %s WHERE id_maquina = 1;"
                        test_update_cursor_server = mydb_server.cursor()
                        test_update_cursor_server.execute(test_update_query_server)
                        mydb_server.commit()

                        print("Teste de atualização bem-sucedido no SQL Server.")

                        if result:
                            id_maquina, fk_empresaM = result
                            data_hora_local = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

                            sql_query = """
                            INSERT INTO monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida)
                            VALUES (%s, %s, 'memoria disponivel', (SELECT id_componente from componente WHERE nome_componente = 'RAM' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s)),
                                    (%s, %s, 'memoria total', (SELECT id_componente from componente WHERE nome_componente = 'RAM' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s)),
                                    (%s, %s, 'tempo corrido em horas', (SELECT id_componente from componente WHERE nome_componente = 'SISTEMA' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s));
                            """
                            
                            val = (memoria.available, data_hora_local, id_maquina, id_maquina, fk_empresaM, 'B',
                                   memoria.total, data_hora_local, id_maquina, id_maquina, fk_empresaM, 'B',
                                   ((datetime.now() - datetime.fromtimestamp(ultimo_boot_timestamp)).total_seconds()) / 3600, data_hora_local, id_maquina, id_maquina, fk_empresaM, 'H')

                            mycursor_server.execute(sql_query, val)
                            mydb_server.commit()
                            print(mycursor_server.rowcount, "registros inseridos no banco")
                            print("\r\n")

                    except Exception as e:
                        print("Erro durante a execução no servidor SQL Server:", e)

                    finally:
                        mycursor_server.close()
                        mydb_server.close()

                except pymssql.OperationalError as e:
                    print("MYSQL Server não está ativo, contate nossa equipe para mais detalhes")
                    print(e)

                try:
                    sql_query = """
                        INSERT INTO monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida)
                        VALUES 
                        (%s, %s, 'memoria disponivel', (SELECT id_componente from componente WHERE nome_componente = 'RAM' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s)),
                        (%s, %s, 'memoria total', (SELECT id_componente from componente WHERE nome_componente = 'RAM' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s)),
                        (%s, %s, 'tempo corrido em horas', (SELECT id_componente from componente WHERE nome_componente = 'SISTEMA' and fk_maquina_componente = %s), %s, %s, (SELECT id_unidade FROM unidade_medida WHERE representacao = %s));
                    """
                    val = (
                        # Primeiro conjunto de valores
                        memoria.available, data_hora_local, id_maquina, id_maquina, fk_empresaM, 'B',
                        
                        # Segundo conjunto de valores
                        memoria.total, data_hora_local, id_maquina, id_maquina, fk_empresaM, 'B',
                        
                        # Terceiro conjunto de valores
                        ((datetime.now() - datetime.fromtimestamp(ultimo_boot_timestamp)).total_seconds()) / 3600, data_hora_local, id_maquina, id_maquina, fk_empresaM, 'H'
                    )

                    mycursor.execute(sql_query, val)
                    mydb.commit()

                    print(mycursor.rowcount, "registros inseridos no banco")
                    print("\r\n")

                except mysql.connector.Error as e:
                    print("Erro ao conectar com o MySQL:", e)

                finally:
                    if mydb and mydb.is_connected():
                        mycursor.close()
                    else:
                        print(f"A máquina {hostname} não foi cadastrada.")

    except Exception as ex:
        print(f"Erro geral: {ex}")

time.sleep(30)  # Adicionado aqui se você desejar um atraso antes da próxima iteração
