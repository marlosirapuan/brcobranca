# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab240
      class Cecred < Brcobranca::Remessa::Cnab240::Base
        # digito da agencia
        attr_accessor :digito_agencia

        validates_presence_of :digito_agencia, message: 'não pode estar em branco.'
        validates_presence_of :convenio, message: 'não pode estar em branco.'
        validates_presence_of :conta_corrente, message: 'não pode estar em branco.'
        validates_length_of :convenio, maximum: 6, message: 'não deve ter mais de 6 dígitos.'
        validates_length_of :conta_corrente, maximum: 12, message: 'não deve ter mais de 12 dígitos.'
        validates_length_of :digito_agencia, is: 1, message: 'deve ter 1 dígito.'

        def initialize(campos = {})
          campos = { emissao_boleto: '2',
                     forma_cadastramento: '0',
                     codigo_baixa: '1',
                     distribuicao_boleto: '0',
                     especie_titulo: '99' }.merge!(campos)
          super(campos)
        end

        def convenio=(valor)
          @convenio = valor.to_s.rjust(6, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(12, '0') if valor
        end

        def cod_banco
          '085'
        end

        def nome_banco
          'CECRED'.ljust(30, ' ')
        end

        def versao_layout_arquivo
          '087'
        end

        def versao_layout_lote
          '045'
        end

        def codigo_convenio
          convenio.ljust(20, ' ')
        end

        def uso_exclusivo_banco
          ''.rjust(20, ' ')
        end

        def uso_exclusivo_empresa
          ''.ljust(20, ' ')
        end

        def convenio_lote
          codigo_convenio
        end

        def info_conta
          # CAMPO            # TAMANHO
          # agencia          5
          # digito agencia   1
          # conta corrente   12
          # dv da conta      1
          # dv agencia/conta 1
          "#{agencia_conta_corrente}#{agencia_conta_corrente_dv}"
        end

        def agencia_conta_corrente
          "#{agencia.to_s.rjust(5, '0')}#{digito_agencia}#{conta_corrente}#{conta_corrente_dv}"
        end

        def conta_corrente_dv
          conta_corrente.modulo11
        end

        def agencia_conta_corrente_dv
          agencia_conta_corrente.modulo11
        end

        def complemento_header
          "#{''.rjust(29, ' ')}"
        end

        def complemento_trailer
          "#{''.rjust(69, '0')}#{''.rjust(148, ' ')}"
        end

        def tipo_documento
          "2"
        end

        def complemento_p(pagamento)
          # CAMPO                 TAMANHO
          # conta_corrente        12
          # dv conta corrente     1
          # dv agencia/conta      1
          # ident. titulo         20
          "#{conta_corrente}#{conta_corrente_dv}#{agencia_conta_corrente_dv}#{pagamento.nosso_numero.to_s.rjust(20, '0')}"
        end

        def numero_documento(pagamento)
          pagamento.numero_documento.to_s.rjust(15, "0")
        end

        def identificacao_titulo_empresa(pagamento)
          pagamento.numero_documento.to_s.ljust(25, " ")
        end
      end
    end
  end
end
