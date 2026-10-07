class Produto {
  final int id;
  final String nome;
  final double preco;
  final String? descricao;
  final String? categoria;
  final String? status;
  final int? estoque;
  final String? imagemUrl;

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    this.descricao,
    this.categoria,
    this.status,
    this.estoque,
    this.imagemUrl,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      preco: (json['preco'] as num).toDouble(),
      descricao: json['descricao'],
      categoria: json['categoria'],
      status: json['status'],
      estoque: json['estoque'],
      imagemUrl: json['imagemUrl'],
    );
  }
}