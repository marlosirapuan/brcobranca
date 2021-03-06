# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::Sicoob do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 50.0,
      data_vencimento: Date.today,
      nosso_numero: '429715',
      documento: 6969,
      documento_sacado: '82136760505',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      logradouro_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
      numero_sacado: '999',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      uf_sacado: 'RJ',
      codigo_mora: '1',
      codigo_protesto: '1',
      especie_titulo: 'DSI',
      codigo_multa: '1'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '4327',
      conta_corrente: '03666',
      documento_cedente: '74576177000177',
      modalidade_carteira: '01',
      convenio: '512231',
      pagamentos: [pagamento]
    }
  end

  let(:sicoob) { subject.class.new(params) }

  before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }

  after { Timecop.return }

  context 'validacoes' do
    context '@modalidade_carteira' do
      it 'deve ser invalido se nao possuir a modalidade da carteira' do
        objeto = subject.class.new(params.merge(modalidade_carteira: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Modalidade carteira não pode estar em branco.')
      end
    end

    context '@tipo_formulario' do
      it 'deve ser invalido se nao possuir o tipo de formulario' do
        objeto = subject.class.new(params.merge(tipo_formulario: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Tipo formulario não pode estar em branco.')
      end
    end

    context '@parcela' do
      it 'deve ser invalido se nao possuir a parcela' do
        objeto = subject.class.new(params.merge(parcela: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Parcela não pode estar em branco.')
      end
    end

    context '@agencia' do
      it 'deve ser invalido se a agencia tiver mais de 4 digitos' do
        sicoob.agencia = '12345'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@convenio' do
      it 'deve ser invalido se nao possuir o convenio' do
        sicoob.convenio = nil
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Convenio não pode estar em branco.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se a conta corrente tiver mais de 8 digitos' do
        sicoob.conta_corrente = '123456789'
        expect(sicoob.invalid?).to be true
        expect(sicoob.errors.full_messages).to include('Conta corrente é muito longo (máximo: 8 caracteres).')
      end
    end
  end

  context 'formatacoes' do
    it 'codigo do banco deve ser 001' do
      expect(sicoob.cod_banco).to eq '756'
    end

    it 'nome do banco deve ser Sicoob com 30 posicoes' do
      nome_banco = sicoob.nome_banco
      expect(nome_banco.size).to eq 30
      expect(nome_banco[0..19]).to eq 'SICOOB              '
    end

    it 'versao do layout do arquivo deve ser 081' do
      expect(sicoob.versao_layout_arquivo).to eq '081'
    end

    it 'versao do layout do lote deve ser 040' do
      expect(sicoob.versao_layout_lote).to eq '040'
    end

    it 'deve calcular o digito da agencia' do
      # digito calculado a partir do modulo 11 com base 9
      #
      # agencia = 1  2  3  4
      #
      #           4  3  2  1
      # x         9  8  7  6
      # =         36 24 14 6 = 80
      # 80 / 11 = 7 com resto 3
      expect(sicoob.digito_agencia).to eq '3'

      sicoob_2 = subject.class.new(params.merge!(agencia: '3214'))
      expect(sicoob_2.digito_agencia).to eq '0'

      sicoob_3 = subject.class.new(params.merge!(agencia: '0001'))
      expect(sicoob_3.digito_agencia).to eq '9'

      sicoob_4 = subject.class.new(params.merge!(agencia: '2006'))
      expect(sicoob_4.digito_agencia).to eq '0'

      sicoob_5 = subject.class.new(params.merge!(agencia: '3032'))
      expect(sicoob_5.digito_agencia).to eq '5'
    end

    it 'deve calcular  digito da conta' do
      # digito calculado a partir do modulo 11 com base 9
      #
      # conta = 1  2  3  4  5
      #
      #         5  4  3  2  1
      # x       9  8  7  6  5
      # =       45 32 21 12 5 = 116
      # 116 / 11 = 10 com resto 5
      expect(sicoob.digito_conta).to eq '8'
    end

    it 'cod. convenio deve retornar as informacoes nas posicoes corretas' do
      cod_convenio = sicoob.codigo_convenio
      expect(cod_convenio[0..19]).to eq '                    '
    end

    it 'info conta deve retornar as informacoes nas posicoes corretas' do
      info_conta = sicoob.info_conta
      expect(info_conta[0..4]).to eq '04327'
      expect(info_conta[5]).to eq '3'
      expect(info_conta[6..17]).to eq '000000003666'
      expect(info_conta[18]).to eq '8'
    end

    it 'complemento header deve retornar espacos em branco' do
      expect(sicoob.complemento_header).to eq ''.rjust(29, ' ')
    end

    it 'complemento trailer deve retornar espacos em branco com a totalização das cobranças' do
      total_cobranca_simples    = '00000100000000000005000'
      total_cobranca_vinculada  = ''.rjust(23, '0')
      total_cobranca_caucionada = ''.rjust(23, '0')
      total_cobranca_descontada = ''.rjust(23, '0')

      expect(sicoob.complemento_trailer).to eq "#{total_cobranca_simples}#{total_cobranca_vinculada}"\
                            "#{total_cobranca_caucionada}#{total_cobranca_descontada}".ljust(217, ' ')
    end

    it 'formata o nosso numero' do
      nosso_numero = sicoob.formata_nosso_numero 1
      expect(nosso_numero).to eq '000000000101014     '
    end

    it 'converte espécie título para o código correspondente' do
      segmento_p = sicoob.monta_segmento_p(pagamento, 1, 2)
      expect(segmento_p[106..107]).to eq '05'
    end

    it 'converte espécie título NP para o código correspondente' do
      pagamento.especie_titulo = 'NP'
      segmento_p = sicoob.monta_segmento_p(pagamento, 1, 2)
      expect(segmento_p[106..107]).to eq '12'
    end

    it 'espécie título não informada utiliza espécie padrão' do
      pagamento.especie_titulo = ''
      segmento_p = sicoob.monta_segmento_p(pagamento, 1, 2)
      expect(segmento_p[106..107]).to eq '02'
    end

    it 'data de mora deve ser após o vencimento quando informada' do
      segmento_p = sicoob.monta_segmento_p(pagamento, 1, 2)

      expect(segmento_p[77..84]).to eql '14072015'
      expect(segmento_p[118..125]).to eql '15072015'
    end

    it 'data de mora deve ser após o vencimento quando informada e tipo de mora for 2' do
      pagamento.codigo_mora = '2'
      segmento_p = sicoob.monta_segmento_p(pagamento, 1, 2)

      expect(segmento_p[77..84]).to eql '14072015'
      expect(segmento_p[118..125]).to eql '15072015'
    end

    it 'data de mora deve estar zerada caso tipo de mora seja 1 ou 2' do
      pagamento.codigo_mora = '0'
      segmento_p = sicoob.monta_segmento_p(pagamento, 1, 2)

      expect(segmento_p[118..125]).to eql '00000000'
    end

    it 'data de multa deve ser após o vencimento quando codigo_multa for diferente de 0' do
      segmento_r = sicoob.monta_segmento_r(pagamento, 1, 2)

      expect(segmento_r[65..65]).to eql '1'
      expect(segmento_r[66..73]).to eql '15072015'
    end

    it 'data de multa deve estar zerada para codigo_multa 0' do
      pagamento.codigo_multa = "0"
      segmento_r = sicoob.monta_segmento_r(pagamento, 1, 2)

      expect(segmento_r[65..65]).to eql '0'
      expect(segmento_r[66..73]).to eql '00000000'
    end
  end

  context 'geracao remessa' do
    it_behaves_like 'cnab240'

    context 'arquivo' do
      it { expect(sicoob.gera_arquivo).to eq(read_remessa('remessa-bancoob-cnab240.rem', sicoob.gera_arquivo)) }
    end
  end
end
