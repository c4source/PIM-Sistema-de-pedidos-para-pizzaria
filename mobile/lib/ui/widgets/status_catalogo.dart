import 'package:flutter/material.dart';

class StatusCatalogo extends StatelessWidget {
  final bool local;
  final bool carregando;
  final bool falhaCache;
  final bool falhaConsulta;
  final DateTime? atualizadoEm;
  final VoidCallback sincronizar;
  final String assunto;
  final int pendentes;
  final int atencao;
  final VoidCallback? abrirFila;
  const StatusCatalogo({
    super.key,
    required this.local,
    required this.carregando,
    required this.falhaCache,
    required this.atualizadoEm,
    required this.sincronizar,
    this.falhaConsulta = false,
    this.assunto = 'Produtos',
    this.pendentes = 0,
    this.atencao = 0,
    this.abrirFila,
  });

  String? get horario {
    final date = atualizadoEm?.toLocal();
    if (date == null) return null;
    final hoje = DateTime.now();
    final hora =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final mesmoDia =
        date.year == hoje.year &&
        date.month == hoje.month &&
        date.day == hoje.day;
    if (mesmoDia) return 'Atualizado às $hora';
    final data =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return 'Atualizado em $data às $hora';
  }

  @override
  Widget build(BuildContext context) {
    final temFila = pendentes + atencao > 0;
    final alerta =
        local ||
        falhaCache ||
        falhaConsulta ||
        (!carregando && atualizadoEm == null);
    final cor = alerta ? const Color(0xff8a5900) : const Color(0xff15803d);
    final titulo = carregando
        ? 'Atualizando...'
        : local
        ? 'Sem conexão'
        : falhaConsulta || atualizadoEm == null && !falhaCache
        ? 'Não foi possível atualizar'
        : falhaCache
        ? 'Dados atualizados, sem cópia offline'
        : temFila
        ? 'Sincronização pendente'
        : '$assunto atualizado${assunto == 'Produtos' ? 's' : ''}';
    final descricao = local
        ? 'Você pode registrar movimentações; elas serão enviadas quando a conexão voltar.'
        : falhaConsulta
        ? 'Tente atualizar novamente.'
        : falhaCache
        ? 'Não foi possível salvar os dados para usar sem conexão.'
        : null;
    final detalhes = <String>[
      if (pendentes > 0)
        pendentes == 1
            ? '1 movimentação aguardando envio'
            : '$pendentes movimentações aguardando envio',
      if (atencao > 0)
        atencao == 1
            ? '1 movimentação requer atenção'
            : '$atencao movimentações requerem atenção',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: alerta ? const Color(0xfffff6df) : null,
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        local
                            ? Icons.cloud_off_outlined
                            : alerta || temFila
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: temFila && !alerta
                            ? const Color(0xff64748b)
                            : cor,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: alerta ? cor : const Color(0xff334155),
                      ),
                    ),
                    if (descricao != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          descricao,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    if (horario != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          horario!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: carregando ? null : sincronizar,
                icon: const Icon(Icons.refresh, size: 21),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        if (temFila)
          Material(
            color: const Color(0xfffff6df),
            child: InkWell(
              onTap: abrirFila,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      atencao > 0
                          ? Icons.error_outline
                          : Icons.cloud_upload_outlined,
                      size: 20,
                      color: const Color(0xff8a5900),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detalhes.join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff704800),
                        ),
                      ),
                    ),
                    if (abrirFila != null)
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xff8a5900),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
