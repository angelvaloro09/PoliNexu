enum IpnSchool {
  upiicsa(
    id: 'upiicsa',
    displayName: 'UPIICSA',
    fullName: 'Unidad Profesional Interdisciplinaria de Ingeniería y Ciencias Sociales y Administrativas',
    baseUrl: 'https://www.saes.upiicsa.ipn.mx',
  ),
  escom(
    id: 'escom',
    displayName: 'ESCOM',
    fullName: 'Escuela Superior de Cómputo',
    baseUrl: 'https://www.saes.escom.ipn.mx',
  ),
  upiita(
    id: 'upiita',
    displayName: 'UPIITA',
    fullName: 'Unidad Profesional Interdisciplinaria en Ingeniería y Tecnologías Avanzadas',
    baseUrl: 'https://www.saes.upiita.ipn.mx',
  ),
  esimeZac(
    id: 'esime_zac',
    displayName: 'ESIME Zacatenco',
    fullName: 'Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Zacatenco',
    baseUrl: 'https://www.saes.esimez.ipn.mx',
  ),
  esimeCul(
    id: 'esime_cul',
    displayName: 'ESIME Culhuacán',
    fullName: 'Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Culhuacán',
    baseUrl: 'https://www.saes.esimecu.ipn.mx',
  ),
  esimeTic(
    id: 'esime_tic',
    displayName: 'ESIME Ticomán',
    fullName: 'Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Ticomán',
    baseUrl: 'https://www.saes.esimetic.ipn.mx',
  ),
  esimeAzc(
    id: 'esime_azc',
    displayName: 'ESIME Azcapotzalco',
    fullName: 'Escuela Superior de Ingeniería Mecánica y Eléctrica Unidad Azcapotzalco',
    baseUrl: 'https://www.saes.esimeazc.ipn.mx',
  ),
  escaSto(
    id: 'esca_sto',
    displayName: 'ESCA Santo Tomás',
    fullName: 'Escuela Superior de Comercio y Administración Unidad Santo Tomás',
    baseUrl: 'https://www.saes.escasto.ipn.mx',
  ),
  escaTep(
    id: 'esca_tep',
    displayName: 'ESCA Tepepan',
    fullName: 'Escuela Superior de Comercio y Administración Unidad Tepepan',
    baseUrl: 'https://www.saes.escatep.ipn.mx',
  ),
  ese(
    id: 'ese',
    displayName: 'ESE',
    fullName: 'Escuela Superior de Economía',
    baseUrl: 'https://www.saes.ese.ipn.mx',
  ),
  esm(
    id: 'esm',
    displayName: 'ESM',
    fullName: 'Escuela Superior de Medicina',
    baseUrl: 'https://www.saes.esm.ipn.mx',
  ),
  est(
    id: 'est',
    displayName: 'EST',
    fullName: 'Escuela Superior de Turismo',
    baseUrl: 'https://www.saes.est.ipn.mx',
  ),
  esfm(
    id: 'esfm',
    displayName: 'ESFM',
    fullName: 'Escuela Superior de Física y Matemáticas',
    baseUrl: 'https://www.saes.esfm.ipn.mx',
  ),
  esiqie(
    id: 'esiqie',
    displayName: 'ESIQIE',
    fullName: 'Escuela Superior de Ingeniería Química e Industrias Extractivas',
    baseUrl: 'https://www.saes.esiqie.ipn.mx',
  ),
  esmia(
    id: 'esmia',
    displayName: 'ESIA Ticomán',
    fullName: 'Escuela Superior de Ingeniería y Arquitectura Unidad Ticomán',
    baseUrl: 'https://www.saes.esiatic.ipn.mx',
  ),
  esiaz(
    id: 'esiaz',
    displayName: 'ESIA Zacatenco',
    fullName: 'Escuela Superior de Ingeniería y Arquitectura Unidad Zacatenco',
    baseUrl: 'https://www.saes.esiaz.ipn.mx',
  ),
  encb(
    id: 'encb',
    displayName: 'ENCB',
    fullName: 'Escuela Nacional de Ciencias Biológicas',
    baseUrl: 'https://www.saes.encb.ipn.mx',
  ),
  upibi(
    id: 'upibi',
    displayName: 'UPIBI',
    fullName: 'Unidad Profesional Interdisciplinaria de Biotecnología',
    baseUrl: 'https://www.saes.upibi.ipn.mx',
  ),
  upig(
    id: 'upig',
    displayName: 'UPIIG',
    fullName: 'Unidad Profesional Interdisciplinaria de Ingeniería Campus Guanajuato',
    baseUrl: 'https://www.saes.upiig.ipn.mx',
  ),
  upiz(
    id: 'upiz',
    displayName: 'UPIIZ',
    fullName: 'Unidad Profesional Interdisciplinaria de Ingeniería Campus Zacatecas',
    baseUrl: 'https://www.saes.upiiz.ipn.mx',
  );

  const IpnSchool({
    required this.id,
    required this.displayName,
    required this.fullName,
    required this.baseUrl,
  });

  final String id;
  final String displayName;
  final String fullName;
  final String baseUrl;
}
