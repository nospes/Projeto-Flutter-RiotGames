/// queues.dart — mapeamento de filas e helper de label

const Map<int, String> queueNames = {
  400: "Normal Draft",
  420: "Ranqueada Solo/Duo",
  430: "Normal Blind",
  440: "Ranqueada Flex",
  450: "ARAM",
  490: "Quickplay",
  700: "Clash",
  830: "Co-op vs AI (Intro)",
  840: "Co-op vs AI (Beginner)",
  850: "Co-op vs AI (Intermediate)",
  900: "ARURF",
};

String queueLabel(int? id) => queueNames[id ?? -1] ?? "Fila $id";
