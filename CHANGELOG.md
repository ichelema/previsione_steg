## 1.4.0 (2026-08-05)
### Changed
-  Aggiornato a Ruby 4.0.1 e tutte le gem all'ultima versione  ( 2026-08-03 ) [ sphynx79]
-  Actions riscritte col template minimale: contratto expects/promises documentato con tag sopra la DSL, rimossi i blocchi @!method e l'HTML nei commenti  ( 2026-08-04 ) [ sphynx79]
-  Css YARD spostato in template path custom (yard_templates), yard server va avviato con -t ./yard_templates  ( 2026-08-03 ) [ sphynx79]

### Added
-  Plugin yard-switchyard: sezione "Contract" nei doc web generata dal contratto della DSL  ( 2026-08-04 ) [ sphynx79]
-  Convention solargraph-switchyard: hover LSP con il contratto letto dalla DSL  ( 2026-08-04 ) [ sphynx79]
-  CLAUDE.md con la guida del progetto per Claude Code  ( 2026-08-03 ) [ sphynx79]

### Fixed
-  Compatibilita' Ruby 4 nei controller e gem fiddle/win32ole/webrick esplicite nel Gemfile  ( 2026-08-03 ) [ sphynx79]
-  Freccia del toggle esempi nei doc mostrata come mojibake dai browser senza charset UTF-8  ( 2026-08-05 ) [ sphynx79]



## 1.3.1 (2023-01-13)
### Chabged
-  cambiato fuso orario  ( 2022-03-29 ) [ sphynx79]

### Changed
-  cambiato logica lettura db  ( 2022-03-25 ) [ sphynx79]

### Added
-  Aggiunto nomina Goal AVG  ( 2022-03-23 ) [ sphynx79]
-  Ottimizzato per ridurre i tempi, compila dispersione e previsione_up previsione_down solo alle ore 09  ( 2022-03-17 ) [ sphynx79]
-  Aggiunto calcolo della nomina_goal  ( 2022-02-23 ) [ sphynx79]
-  Aggiunto vecchio forecast nell'email del report e print screen scada  ( 2022-01-18 ) [ sphynx79]
-  Aggiunto nello Scheduler che manda una email con l'errore nel caso in cui ci sia un errore  ( 2022-01-17 ) [ sphynx79]
-  aggiunto il supporto per salvare lo storico delle previsioni nel database sqlite  ( 2022-01-12 ) [ sphynx79]
-  Aggiunto la possibilità di usare il log anche dentro le azzioni, esempio log.info("ciao")  ( 2022-01-11 ) [ sphynx79]
-  Portato la compilazione della tabella daily evolution da excel a ruby  ( 2022-01-11 ) [ sphynx79]

### Fixed
-  Corretto il problema che se non trova un file di consuntivi legge quello del giorno prima  ( 2022-02-22 ) [ sphynx79]
-  Risolto problema che non trovava tabella day del forecast  ( 2022-02-22 ) [ sphynx79]
-  sitemato in daily evolution il problema dell'arrotondamento  ( 2022-01-14 ) [ sphynx79]
-  corrette il bug sull'export del DB non prendeva il G-1, e liminato anno 2015 e 2016  ( 2022-01-14 ) [ sphynx79]



## 1.3.0 (2021-12-20)
### Changed
-  Implementato in ruby lo scaricamento dei consuntivi dal server FTP  ( 2021-12-20 ) [ sphynx79]



## 1.2.5 (2021-12-16)


## 1.2.4 (2021-12-13)


## 1.2.3 (2021-11-23)


## 1.2.2 (2021-11-18)


## 1.2.1 (2021-06-24)


## 1.2.0 (2021-06-23)


## 1.1.0 (2021-06-21)


## 1.1.0 (2021-06-21)



