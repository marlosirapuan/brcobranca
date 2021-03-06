# -*- encoding: utf-8 -*-
module Brcobranca
  module Boleto
    class Banrisul < Base # Banco BANRISUL
      validates_length_of :agencia, maximum: 4
      validates_length_of :numero, maximum: 8
      validates_length_of :convenio, maximum: 13
      validates_length_of :carteira, is: 1

      # Nova instancia do Banrisul
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = { carteira: '1' }.merge!(campos)

        campos.merge!(local_pagamento: 'Pagável em qualquer banco até o vencimento')

        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '041'
      end

      # Número seqüencial utilizado para identificar o boleto.
      # @return [String] 8 caracteres numéricos.
      def numero=(valor)
        @numero = valor.to_s.rjust(8, '0') if valor
      end

      def convenio=(valor)
        if valor
          convenio = valor.to_s.rjust(13, '0')
          @convenio = convenio[4..-1]
        end
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "00000004042-28"
      def nosso_numero_boleto
        "#{numero}-#{nosso_numero_dv}"
      end

      # Dígito verificador da agência
      # @return [Integer] 2 caracteres numéricos.
      def agencia_dv
        agencia.duplo_digito_banrisul
      end

      # Dígito verificador do nosso número
      # @return [Integer] 2 caracteres numéricos.
      def nosso_numero_dv
        numero.duplo_digito_banrisul
      end

      # Agência + convênio do cliente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "0548.23/0000140-26"
      def agencia_conta_boleto
        agrupa_convenio_e_dv = /\A(\d{7})(\d{2})\Z/
        formata_convenio = '\\1-\\2'
        "#{agencia}.#{agencia_dv} / #{convenio.gsub(agrupa_convenio_e_dv, formata_convenio)}"
      end

      # Segunda parte do código de barras.
      #
      # Posição | Tamanho | Conteúdo<br/>
      # 20        1         Constante 2, identifica o Produto
      # 21        1         Constante 1, identifica o Sistema
      # 22 a 25   4         Agência do Beneficiário, sem NC
      # 26 a 32   7         Código do Cedente, sem NC
      # 33 a 40   8         Nosso Número, sem NC
      # 41 a 42   2         Constante 40
      # 43 a 44   2         Número de controle (cálculo através dos modulos 10 e 11)
      #
      # @return [String] 25 caracteres numéricos.
      def codigo_barras_segunda_parte
        codigo_sem_nc = "21#{agencia}#{convenio[0..-3]}#{numero}40"
        "#{codigo_sem_nc}#{codigo_sem_nc.duplo_digito_banrisul}"
      end
    end
  end
end
