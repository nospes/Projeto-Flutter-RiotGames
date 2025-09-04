enum PlatformHost { br1, na1, la1, la2, euw1, eun1, kr, jp1, tr1, ru, oce }
enum RegionHost { americas, europe, asia }

String platformBase(PlatformHost p) => 'https://${p.name}.api.riotgames.com';
String regionBase(RegionHost r) => 'https://${r.name}.api.riotgames.com';

// BR:
// - endpoints "platform" (ex.: summoner-v4): br1
// - endpoints "regional" (ex.: account-v1, match-v5): americas
