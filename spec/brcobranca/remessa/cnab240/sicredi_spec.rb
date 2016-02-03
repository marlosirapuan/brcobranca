# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::Sicredi do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 50.0,
      data_vencimento: Date.today,
      nosso_numero: '429715',
      numero_documento: '429715',
      documento_sacado: '82136760505',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      uf_sacado: 'RJ'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '4327',
      conta_corrente: '03666',
      documento_cedente: '74576177000177',
      modalidade_carteira: '01',
      posto: '14',
      byte_idt: '2',
      pagamentos: [pagamento]
    }
  end

  let(:sicredi) { subject.class.new(params) }

  context 'validacoes' do
    context '@posto' do
      it 'deve ser invalido se nao possuir o valor do posto' do
        objeto = subject.class.new(params.merge(posto: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Posto não pode estar em branco.')
      end

      it 'deve ser invalido se o posto tiver mais de 2 dígitos' do
        sicredi.posto = '123'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Posto deve ser menor ou igual a 2 dígitos.')
      end
    end

    context '@byte_idt' do
      it 'deve ser invalido se nao possuir o valor da byte de geracao' do
        objeto = subject.class.new(params.merge(byte_idt: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Byte idt não pode estar em branco.')
      end

      it 'deve ser invalido se o byte idt tiver mais de 1 dígito' do
        sicredi.byte_idt = '12'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages)
          .to include('Byte idt deve ser 1 se o numero foi gerado pela agencia ou 2-9 se foi gerado pelo beneficiário')
      end
    end

    context '@modalidade_carteira' do
      it 'deve ser invalido se nao possuir a modalidade da carteira' do
        objeto = subject.class.new(params.merge(modalidade_carteira: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Modalidade carteira não pode estar em branco.')
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
        sicredi.agencia = '12345'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser invalido se a conta corrente tiver mais de 8 digitos' do
        sicredi.conta_corrente = '123456789'
        expect(sicredi.invalid?).to be true
        expect(sicredi.errors.full_messages).to include('Conta corrente deve ter 8 dígitos.')
      end
    end
  end

  context 'formatacoes' do
    it 'codigo do banco deve ser 001' do
      expect(sicredi.cod_banco).to eq '748'
    end

    it 'nome do banco deve ser sicredi com 30 posicoes' do
      nome_banco = sicredi.nome_banco
      expect(nome_banco.size).to eq 30
      expect(nome_banco[0..19]).to eq 'SICREDI             '
    end

    it 'versao do layout do arquivo deve ser 081' do
      expect(sicredi.versao_layout_arquivo).to eq '081'
    end

    it 'versao do layout do lote deve ser 040' do
      expect(sicredi.versao_layout_lote).to eq '040'
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
      expect(sicredi.digito_agencia).to eq '3'
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
      expect(sicredi.digito_conta).to eq '8'
    end

    it 'cod. convenio deve retornar as informacoes nas posicoes corretas' do
      cod_convenio = sicredi.codigo_convenio
      expect(cod_convenio[0..19]).to eq '                    '
    end

    it 'info conta deve retornar as informacoes nas posicoes corretas' do
      info_conta = sicredi.info_conta
      expect(info_conta[0..4]).to eq '04327'
      expect(info_conta[5]).to eq '3'
      expect(info_conta[6..17]).to eq '000000003666'
      expect(info_conta[18]).to eq '8'
    end

    it 'complemento header deve retornar espacos em branco' do
      expect(sicredi.complemento_header).to eq ''.rjust(29, ' ')
    end

    it 'complemento trailer deve retornar espacos em branco com a totalização das cobranças' do
      total_cobranca_simples    = "00000100000000000005000"
      total_cobranca_vinculada  = "".rjust(23, "0")
      total_cobranca_caucionada = "".rjust(23, "0")
      total_cobranca_descontada = "".rjust(23, "0")

      expect(sicredi.complemento_trailer).to eq "#{total_cobranca_simples}#{total_cobranca_vinculada}"\
        "#{total_cobranca_caucionada}#{total_cobranca_descontada}".ljust(217, ' ')
    end

    before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
    after { Timecop.return }

    it 'formata o nosso numero' do
      nosso_numero = sicredi.formata_nosso_numero 1
      expect(nosso_numero).to eq "15200000000000000011"
    end
  end

  context 'geracao remessa' do
    it_behaves_like 'cnab240'

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(sicredi.gera_arquivo).to eq(read_remessa('remessa-sicredi-cnab240.rem', sicredi.gera_arquivo)) }
    end
  end
end
