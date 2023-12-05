import com.github.britooo.looca.api.core.Looca
import com.github.britooo.looca.api.group.janelas.Janela
import com.github.britooo.looca.api.group.processos.Processo
import com.github.britooo.looca.api.group.temperatura.Temperatura
import org.springframework.jdbc.core.JdbcTemplate
import java.time.LocalDateTime



class DadosRepositorios {

    lateinit var jdbcTemplate: JdbcTemplate
    var jdbcTemplate_server = Conexao.jdbcTemplate_server!!

    fun iniciar() {
        jdbcTemplate = Conexao.jdbcTemplate!!
    }

    fun iniciar_server() {
        jdbcTemplate_server = Conexao.jdbcTemplate_server!!
    }

    fun cadastrarJanela(novaJanela: MutableList<Janela>?, id_maquina: Int, fk_empresa: Int) {
        val janelasNoBanco = jdbcTemplate.queryForList(
            "SELECT nome_janela FROM janela where fk_maquinaJ = $id_maquina and fk_empresaJ = $fk_empresa",
            String::class.java)

        val janelasNoBancoServer = jdbcTemplate_server.queryForList(
            "SELECT nome_janela FROM janela where fk_maquinaJ = $id_maquina and fk_empresaJ = $fk_empresa",
            String::class.java
        )

        val janelasListadas = novaJanela?.filter { it.titulo != null && it.titulo.isNotBlank() }?.map { it.titulo }

        novaJanela?.forEach { janela ->
            if (janela.titulo != null && janela.titulo.isNotBlank()) {
                val janelaExisteNoBanco = janelasNoBanco.contains(janela.titulo)


                if (janelaExisteNoBanco) {
                    // A janela existe no banco, atualize-a definindo status_abertura como verdadeiro.
                    jdbcTemplate.update(
                        """
                UPDATE janela
                SET data_hora = ?,
                    status_abertura = ?
                WHERE nome_janela = ? AND fk_maquinaJ = $id_maquina AND fk_empresaJ = $fk_empresa
                """,
                        LocalDateTime.now(),
                        true,
                        janela.titulo
                    )
                } else {
                    // A janela não existe no banco, insira-a com status_abertura como verdadeiro.
                    jdbcTemplate.update(
                        """
                INSERT INTO janela (nome_janela, data_hora, status_abertura, fk_maquinaJ, fk_empresaJ)
                VALUES (?, ?, ?, $id_maquina, $fk_empresa)
                """,
                        janela.titulo,
                        LocalDateTime.now(),
                        true
                    )
                }

                val janelaExisteNoBancoServer = janelasNoBancoServer.contains(janela.titulo)

                if (janelaExisteNoBancoServer) {
                    // A janela existe no banco, atualize-a definindo status_abertura como verdadeiro.
                    jdbcTemplate_server.update(
                        """
                UPDATE janela
                SET data_hora = ?,
                    status_abertura = ?
                WHERE nome_janela = ? AND fk_maquinaJ = $id_maquina AND fk_empresaJ = $fk_empresa
                """,
                        LocalDateTime.now(),
                        true,
                        janela.titulo
                    )
                } else {
                    // A janela não existe no banco, insira-a com status_abertura como verdadeiro.
                    jdbcTemplate_server.update(
                        """
                INSERT INTO janela (nome_janela, data_hora, status_abertura, fk_maquinaJ, fk_empresaJ)
                VALUES (?, ?, ?, $id_maquina, $fk_empresa)
                """,
                        janela.titulo,
                        LocalDateTime.now(),
                        true
                    )
                }
            }
        }

        if (janelasListadas != null && janelasListadas.isNotEmpty()) {
            val placeholders = janelasListadas.map { "?" }.joinToString(", ")
            val updateQuery = "UPDATE janela SET status_abertura = ? WHERE nome_janela NOT IN ($placeholders)"
            val params = arrayOf(false, *janelasListadas.toTypedArray())
            val queryJanela = jdbcTemplate.update(updateQuery, *params)
            val queryJanelaServer = jdbcTemplate_server.update(updateQuery, *params)
            println("${queryJanela + queryJanelaServer} registros atualizados na tabela de janelas")
        }
    }


    fun cadastrarT(novaTemp: Temperaturas, id_maquina: Int, fk_empresa: Int) {
        var rowTemperatura = jdbcTemplate_server.update(
            """
        insert into monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida) values
        (?,?,'temperatura cpu',2,$id_maquina,$fk_empresa,4)
        """,
            novaTemp.temp,
            novaTemp.dataHora
        )

        var rowTemperaturaL = jdbcTemplate.update(
            """
        insert into monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida) values
        (?,?,'temperatura cpu',2,$id_maquina,$fk_empresa,4)
        """,
            novaTemp.temp,
            novaTemp.dataHora
        )



        println(
            """
        $rowTemperatura temperatura registrada no banco SERVER 
        $rowTemperaturaL temperatura registrada no banco LOCAL 
        """.trimIndent()
        )
    }

    fun cadastrarCpu(novaCpu: Cpu, id_maquina: Int, fk_empresa: Int) {
        var rowCpu = jdbcTemplate_server.update(
            """
        insert into monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida) values
        (?,?,'uso de cpu kt',2,$id_maquina,$fk_empresa,2)
        """,
            novaCpu.dado,
            novaCpu.dataHora
        )

        println(
            """
        $rowCpu cpu registrada no banco
        """.trimIndent()
        )

        var rowCpuL = jdbcTemplate.update(
            """
        insert into monitoramento (dado_coletado, data_hora, descricao, fk_componentes_monitoramento, fk_maquina_monitoramento, fk_empresa_monitoramento, fk_unidade_medida) values
        (?,?,'uso de cpu kt',2,$id_maquina,$fk_empresa,2)
        """,
            novaCpu.dado,
            novaCpu.dataHora
        )

        println(
            """
        $rowCpuL cpu registrada no banco local
        """.trimIndent()
        )
    }


    fun capturarDadosJ(looca: Looca): MutableList<Janela>? {
        val janela = looca.grupoDeJanelas
        var janelasVisiveis = janela.janelasVisiveis

        return janelasVisiveis
    }


    fun capturarDadosT(looca: Looca): Temperaturas {
        val temperatura = looca.temperatura
        var novaTemp = Temperaturas()
        novaTemp.temp = temperatura.temperatura

        return novaTemp
    }

    fun capturarDadosCpu(looca: Looca): Cpu {
        val cpu = looca.processador.uso
        var novaCpu = Cpu()
        novaCpu.dado = looca.processador.uso
        return novaCpu
    }




}


