String normalizarBusca(String texto) {
  const origem = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const destino = 'aaaaaeeeeiiiiooooouuuuc';
  return texto.toLowerCase().runes.where((c) => c < 0x300 || c > 0x36f).map((
    c,
  ) {
    final letra = String.fromCharCode(c);
    final indice = origem.indexOf(letra);
    return indice < 0 ? letra : destino[indice];
  }).join();
}
