class Produto {
  final int id;
  final int estoqueMinimo;
  final bool ehKit;
  final String nome;
  final double preco;
  final String? descricao;
  final String? categoria;
  final String? status;
  final int? estoque;
  final String? imagemUrl;

  Produto({
    required this.id,
    this.ehKit = false,
    this.estoqueMinimo = 5,
    required this.nome,
    required this.preco,
    this.descricao,
    this.categoria,
    this.status,
    this.estoque,
    this.imagemUrl,
  });

  Map<String, Object?> toLocalMap() => {
    'id': id,
    'eh_kit': ehKit ? 1 : 0,
    'estoque_minimo': estoqueMinimo,
    'nome': nome,
    'preco': preco,
    'descricao': descricao,
    'categoria': categoria,
    'status': status,
    'estoque': estoque,
    'imagem_url': imagemUrl,
  };
  factory Produto.fromLocalMap(Map<String, Object?> map) => Produto(
    id: map['id'] as int,
    ehKit: map['eh_kit'] == 1,
    estoqueMinimo: map['estoque_minimo'] as int? ?? 5,
    nome: map['nome'] as String,
    preco: (map['preco'] as num).toDouble(),
    descricao: map['descricao'] as String?,
    categoria: map['categoria'] as String?,
    status: map['status'] as String?,
    estoque: map['estoque'] as int?,
    imagemUrl: map['imagem_url'] as String?,
  );

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      ehKit: json['ehKit'] == true,
      estoqueMinimo: json['estoqueMinimo'] as int? ?? 5,
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
