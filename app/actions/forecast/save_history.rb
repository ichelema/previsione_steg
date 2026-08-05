#!/usr/bin/env ruby
# warn_indent: true
# frozen_string_literal: true

module ForecastActions
  # Salvo nel database la previsione corrente
  class SaveHistory
    extend FunctionalLightService::Action

    # @expects daily_evolution [Hash] Previsione corrente
    expects :daily_evolution

    executed do |ctx|
      try! do
        # @TODO: vedere se rimuovere o usarla nel caso in cui voglio usare un DB diverso da sqlite
        # ctx.db = StegModel.new(database: ctx[:global_options][:database])
        db = StegModel.new(database: "sqlite")
        db.connect
        ctx.fail_and_return!(db.message) unless db.client
        db.create_table(table: "Previsione")
        sql_row = make_sql_row(ctx.daily_evolution)
        insert_to_sqlite(db, sql_row)
      end.map_err do |err|
        ctx.fail_and_return!(
          {message: "Errore nel salvataggio della previsione nel DB dello Storico",
           detail: err.message,
           location: "#{__FILE__}:#{__LINE__}"}
        )
      end
    end

    # inserisce i dati nel database
    #
    # @param db [StegModel] il database
    #
    # @param row [Hash] record da inserire nel database
    #
    # @return [Void]
    def self.insert_to_sqlite(db, row)
      db.client.execute <<-SQL
          INSERT INTO Previsione
          (data_time, data, anno, mese, giorno, ora, previson_type, previsione_v1, previsione_v2, previsione_v3, nomina_steg, steg_progressivo, consuntivo, peso_nomina, correzione_cons_parziale, nomina_goal)
          VALUES(#{values(row)})
            ON CONFLICT(data_time, previson_type)
            DO UPDATE SET
            previsione_v1=excluded.previsione_v1,
            previsione_v2=excluded.previsione_v2,
            previsione_v3=excluded.previsione_v3,
            nomina_steg=excluded.nomina_steg,
            steg_progressivo=excluded.steg_progressivo,
            consuntivo=excluded.consuntivo,
            peso_nomina=excluded.peso_nomina,
            correzione_cons_parziale=excluded.correzione_cons_parziale,
            nomina_goal=excluded.nomina_goal;
      SQL
    end

    # crea un hash con record da inserire nel database
    #
    # @param row [Hash] contiene i valori della mia previsone letti dal file del forecast
    #
    # @return [Hash]
    def self.make_sql_row(row)
      # @TODO:previson_type devo farlo dinamico che prende anche gli altri tipi di previsone
      data_time = get_data_time
      {data_time: data_time,
       data: data_time[0..9].tr("/", "-"),
       anno: data_time[0..3],
       mese: data_time[5..6],
       giorno: data_time[8..9],
       ora: data_time[11..12],
       previson_type: "DICOM",
       previsione_v1: row[:previsione_v1],
       previsione_v2: row[:previsione_v2],
       previsione_v3: row[:previsione_v3],
       nomina_steg: row[:nomina],
       steg_progressivo: row[:progressivo],
       consuntivo: row[:consuntivo],
       peso_nomina: row[:peso_previsione_nomina],
       correzione_cons_parziale: row[:correzione_cons_parziale],
       nomina_goal: row[:nomina_goal]}
    end

    # prende i valori da inserire nel databse e crea una stringa pronta per seeere passata alla insert nel database
    #
    # @param sql_row [Hash] record da inserire nel database
    #
    # @return [String]
    def self.values(sql_row)
      values = "'#{sql_row[:data_time]}' ,"
      values + "'#{sql_row[:data]}',
                '#{sql_row[:anno]}',
                '#{sql_row[:mese]}',
                '#{sql_row[:giorno]}',
                '#{sql_row[:ora]}',
                '#{sql_row[:previson_type]}',
                '#{sql_row[:previsione_v1]}',
                '#{sql_row[:previsione_v2]}',
                '#{sql_row[:previsione_v3]}',
                '#{sql_row[:nomina_steg]}',
                '#{sql_row[:steg_progressivo]}',
                '#{sql_row[:consuntivo]}',
                '#{sql_row[:peso_nomina]}',
                '#{sql_row[:correzione_cons_parziale]}',
                 #{sql_row[:nomina_goal]}"
    end

    # crea la stringa per la colonna data_time
    #
    # @return [String]
    def self.get_data_time
      day, month, year = ctx.dig(:env, :command_options, :dt).split("/")
      hour = ctx.dig(:env, :command_options, :H) + ":00:01"
      "#{year}/#{month}/#{day} #{hour}"
    end

    private_class_method \
      :insert_to_sqlite,
      :make_sql_row,
      :get_data_time,
      :values
  end
end
