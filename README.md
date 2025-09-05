
---

# Riot Profile (Flutter)

App Flutter para consultar perfis e partidas do League of Legends via **Riot API** e assets do **Data Dragon**.
Arquitetura simples com **Riverpod** (injeção de dependência/estado) e **Dio** (HTTP).

## Tecnologias

* Flutter (Material 3)
* Riverpod
* Dio (HTTP)
* Riot API + Data Dragon

## Estrutura do projeto

```
lib/
├─ core/
│  └─ providers.dart                # Providers centrais (Dio, RiotApi, DataDragon)
├─ features/
│  └─ profile/
│     ├─ data/
│     │  ├─ riot_api.dart           # Cliente de endpoints da Riot
│     │  └─ riot_routes.dart        # Hosts/URLs base (platform/regional)
│     └─ presentation/
│        ├─ search_page.dart        # Tela inicial (busca por Riot ID)
│        ├─ profile_page.dart       # Perfil + partidas recentes
│        └─ match_detail_page.dart  # Detalhes de uma partida
├─ shared/
│  ├─ data_dragon.dart              # Versões/ícones (campeões/itens/feitiços)
│  ├─ queues.dart                   # Mapa de filas e helper de label
│  └─ time_format.dart              # Formatação de tempo
└─ main.dart                        # Bootstrap do app
```

## Pré-requisitos

* Flutter instalado e configurado
* Emulador Android rodando (ex.: `emulator-5554`) ou dispositivo físico
* **Chave da Riot API** (crie em: developer.riotgames.com)

## Como rodar

> **Importante:** nunca versione sua chave. Use `--dart-define`.

```bash
flutter clean
flutter pub get
flutter run -d emulator-5554 --dart-define=RIOT_API_KEY=SUA-RIOT-KEY
```

Dicas:

* Liste dispositivos disponíveis: `flutter devices`
* Altere o `-d` conforme o ID do seu device (ex.: `-d windows`, `-d chrome`, `-d iphone`)

## Uso

1. Abra o app.
2. Informe o Riot ID no formato `Nome#TAG` (ex.: `Joao#BR1`).
3. Busque e navegue pelos detalhes de partidas.
obs: Só funciona no server BR.

## Testes

```bash
flutter test
```

## Variáveis e credenciais

* `RIOT_API_KEY`: chave usada no header `X-Riot-Token`.
* Não suba chaves no repositório. Prefira `--dart-define` ou pipelines com secrets.

## Observações

* A versão **Web** pode sofrer com **CORS** da Riot. Priorize emulador/dispositivo.
* Respeite os **limites de rate** e os **Termos de Uso** da Riot.

## Licença

MIT License

Copyright (c) 2025 SEU NOME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
