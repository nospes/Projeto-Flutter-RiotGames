/// riot_routes.dart — hosts/base URLs da Riot

/// Plataformas (endpoints "platform")
enum PlatformHost { br1, na1, la1, la2, euw1, eun1, kr, jp1, tr1, ru, oce }

/// Regiões (endpoints "regional")
enum RegionHost { americas, europe, asia }

/// URL base por plataforma
String platformBase(PlatformHost p) => 'https://${p.name}.api.riotgames.com';

/// URL base por região
String regionBase(RegionHost r) => 'https://${r.name}.api.riotgames.com';
