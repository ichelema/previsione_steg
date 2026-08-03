# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

PrevisioneSteg is a Ruby CLI application for forecasting and reporting on STEG (Société Tunisienne de l'Électricité et du Gaz) energy consumption data. The application processes historical consumption data (consuntivi), generates forecasts using weighted averages, and produces PDF reports sent via email.

## Running the Application

### Main Commands

Run commands from the App directory:

```bash
# Forecast generation
ruby steg.rb --log=info --interface=cli --enviroment=production forecast --dt 10/04/2021 --H 10

# Generate forecast report
ruby steg.rb --log=info --interface=cli --enviroment=production report --type=forecast --dt 10/04/2021 -H 08

# Generate consuntivo report
ruby steg.rb --log=info --interface=cli --enviroment=production report --type=consuntivo --dt 10/04/2021 -H 08

# Download and process consuntivi
ruby steg.rb --log=info --interface=cli --enviroment=production consuntivi
```

### Global Flags

- `--log` or `-l`: Log level [debug, info, warn, error, fatal] (default: info)
- `--interface` or `-i`: Interface [cli, scheduler] (default: cli)
- `--enviroment` or `-e`: Environment [production, development, production_local] (default: production)
- `--database` or `-db`: Database type [sqlite, access, csv] (default: csv)
- `--verbose` or `-v`: Verbose level [s, 1, 2] — level 2 enables TracePoint (very verbose)
- `--mail`: Enable email on unexpected errors

### Scheduler

```bash
ruby scheduler.rb --enviroment=production
```

The scheduler runs:
- Consuntivo processing: Daily at 9:20 AM
- Forecast generation: Hourly from 10:00 to 23:00 (adjusts for DST)

### Dependencies

```bash
bundle install
```

## Linting and Formatting

There are no tests. For code quality:

```bash
# Linting (standard style)
bundle exec rubocop

# Strict linting — also catches leftover binding.pry
bundle exec rubocop -c .rubocop_strict.yml

# Format code (check only)
bundle exec rufo app/

# Format in-place
bundle exec rufo -i app/
```

Rufo config (`.rufo`): double quotes, dynamic parens in `def`, aligned chained calls and `case/when`.

## Architecture

### Entry Point and Routing

`steg.rb` uses GLI for CLI parsing, then calls `Ikigai::Application.dispatch` which dynamically resolves the controller class and method from the env hash. `Ikigai::Initialization.call` (called at startup) auto-loads all files under `app/` via `Object.autoload`, converting snake_case filenames to CamelCase using `Dry::Inflector`.

### MVC-Style Architecture

**Controllers** (`app/controllers/`): `ForecastController`, `ReportController`, `ConsuntiviController`. Each extends `FunctionalLightService::Organizer` and defines a `.steps` array that is the ordered pipeline of actions. All inherit from `Ikigai::BaseController`.

**Actions** (`app/actions/{forecast,report,consuntivi,share}/`): Each is a class inside a module (e.g. `ForecastActions::Previsione`). The module loader in `*_actions.rb` auto-includes `Ikigai::Log` and extends all concern modules onto each action class.

**Models** (`app/models/`): `StegModel` wraps SQLite via `Ikigai::BaseModel`. Results returned as hashes (`results_as_hash = true`). SQLite pragmas: MEMORY journal, `cache_size=4000`, `synchronous=OFF`.

### Writing a New Action

```ruby
# frozen_string_literal: true

module ForecastActions
  # Brief description of what this action does.
  #
  # @expects ctx.some_input [Type] Description
  # @promises ctx.some_output [Type] Description
  class MyAction
    extend FunctionalLightService::Action
    expects :some_input
    promises :some_output

    executed do |ctx|
      try! do
        ctx.some_output = compute(ctx.some_input)
      end.map_err do |err|
        ctx.fail_and_return!(
          { message: "Human-readable message", detail: err.message, location: "#{__FILE__}:#{__LINE__}" }
        )
      end
    end
  end
end
```

Then add `MyAction` to the controller's `.steps` array and include the module in the controller.

Key rules:
- Always use `try!` + `.map_err` — never bare `rescue`
- Error hashes must have `:message`, `:detail`, `:location` keys
- `ctx.fail_and_return!` stops the pipeline; `check_result` in the controller then exits with code 2
- Freeze objects where possible for immutability

### Data Flow

1. **Consuntivi Processing**: Downloads CSV from SCADA FTP → parses → writes to Excel DB files + SQLite
2. **Forecast Generation**: Reads params from `Forecast.xlsm` → reads historical data from DB → filters → groups by hour → weighted average (previsione) → goal nomination macro → upper/lower bounds → dispersion → writes back to Excel → saves to SQLite history
3. **Report Generation**: Connects to Excel → sets date → exports sheet to PDF via COM → sends HTML email with PDF attachment

### Configuration

`config/config.yml` has three environments: `production`, `development`, `production_local`. Loaded via `BetterSettings` into `Ikigai::Config`. Access pattern: `Ikigai::Config.file.excel_forecast`, `Ikigai::Config.mail.from`.

### WIN32OLE Excel Automation

All Excel interop is in `app/controllers/concerns/forecast_concern.rb`. Important gotchas:

- Excel connections are cached in class variables (`@@excel`, `@@workbook`) — they persist across calls
- Named ranges: `workbook.Sheets(sheet).Names(name).Value` returns a formula string; pass to `Evaluate` to get data
- Must call `WIN32OLE.const_load(@@excel, ExcelConst)` before using VB constants
- Empty Excel cells return `""` (empty string), not `nil` — always check before using
- Call `.activate` on a workbook before operating on it
- `range.Rows.each` to iterate rows; manually convert to Ruby arrays/hashes

### Logging

Custom logger in `lib/ikigai/log.rb`, colored via Pastel. Accessible as `log` in any action or controller. Memoized per class.

### Error Handling

Exit codes: 1 (uncaught exception in controller), 2 (action pipeline failure via `check_result`). Scheduler sends Outlook COM email on non-zero exit.

## Key File Locations

- Main entry: `steg.rb`
- Scheduler: `scheduler.rb`
- Framework: `lib/ikigai/`
- Controllers: `app/controllers/`
- Actions: `app/actions/{forecast,report,consuntivi,share}/`
- Models: `app/models/`
- Configuration: `config/config.yml`
- Database: `./DB/steg` (production) or `./DB/steg_dev` (development)
- Excel files: `../Forecast.xlsm`, `../DB/DB.xlsm`, `../DB/DB2.xlsm`
- Reports: `../report/{forecast,consuntivi,scada}/`

## Development Notes

- Ruby version: >= 3.1.0
- Platform: Windows-only (WIN32OLE for Excel COM automation)
- Time zone: Africa/Tunis
- Date format: dd/mm/yyyy (e.g., 20/08/2020)
- Five power stations constant: `PS = %w[feriana kasserine zriba nabeul korba].freeze`

### Italian Terminology

Much of the codebase uses Italian domain terms:

| Italian | English |
|---|---|
| consuntivo / consuntivi | actual consumption data |
| previsione | forecast |
| previsione_up/down | upper/lower forecast bounds |
| dispersione | year-over-year dispersion |
| stazione | station |
| giorno | day |
| giorno_settimana | day of week |
| festivo / festivita | holiday / holiday name |
| stagione | season |
| ora | hour |
| evoluzione giornaliera | daily evolution |
| nomina | goal nomination |

### Known Naming Inconsistency

Some older files reference `Muletto::Config` or `Muletto` — this is the former project name, now renamed to `Ikigai`. If you see `Muletto`, treat it as `Ikigai`.
